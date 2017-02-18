netmsg = netmsg or { Hooks = {}, Receivers = {}, Tables = {} }

local reservedKeys = {
  __id     = true,
  __parent    = true,
  __key       = true,
  __filter    = true,
  __subFilter = true,
}
local EntityMeta = FindMetaTable( 'Entity' )
-- Should only be passed netmsg tables (without metatable)
local function findSubTables( tab )
  for k, v in pairs( tab ) do
    if istable(v) and not IsColor(v) and not isvector(v)
    and ( (SERVER and not v.__id) or CLIENT ) then
      v.__filter = tab.__subFilter
      netmsg.NetworkTable( v, (tab.__id and tab.__id ..'.' or '') .. k )
    end
  end
end

function netmsg.safeTable( tab, clean )
  local newTab = {}
  table.Merge( newTab, tab.__tab or tab )  -- Prevents copying metatable

  if clean then
    for k, v in pairs( reservedKeys ) do
      newTab[k] = nil
    end
  end

  for k, v in pairs( newTab ) do
    if isfunction( v ) then newTab[k] = nil end
    if istable( v ) then newTab[k] = netmsg.safeTable( v.__tab or v, clean ) end
  end

  return newTab
end

function netmsg.Receive( name, func )
  netmsg.Receivers[ name ] = func
end

function netmsg.NetworkTable( tab, id, plys, parent, key )
  if SERVER and tab.__id then return end

  tab.__id = id
  if SERVER then
    local filter, subFilter = tab.__filter, tab.__subFilter

    netmsg.Tables[id] = { __id= id, __parent= parent, __key= key }
    table.Merge( netmsg.Tables[id], tab )
    findSubTables( netmsg.Tables[id] )

    table.Empty( tab )

    tab.__id = id

    setmetatable( tab, netmsg.METATABLE )

    netmsg.SyncTable( netmsg.Tables[id], plys )
    return
  end

  netmsg.Tables[id] = tab
  if CLIENT then findSubTables( netmsg.Tables[id] ) end
end

function EntityMeta:GetNWVar( name, def )

  return ( self.netmsg_PrivVars and self.netmsg_PrivVars[ name ] )
    or ( self.netmsg_PubVars and self.netmsg_PubVars[ name ] ) or def
end

local lastNetmsg, lastPly
net.Receive( 'netmsg.Msg', function( _, ply )

  local name = net.ReadString()
  local done = netmsg.Receivers[ name ]

  if not done then
    MsgN( string.format('[NET] Could not find receiver for message %s', name ) )
    return
  end

  local len, data = net.ReadUInt( 32 )
  if len ~= 0 then
    data = net.ReadData( len )
    data = util.Decompress( data )
    data = von.deserialize( data )
  end

  lastNetmsg, lastPly = name, ply
  done( data, ply )
  lastNetmsg, lastPly = nil, nil
end )

if SERVER then

  netmsg.METATABLE = {
    __newindex = function( self, key, value )
      local oldValue = rawget( netmsg.Tables[self.__id], key )

      if value == oldValue then return end

      if value == nil and istable( oldValue ) and oldValue.__id then
        for k, v in pairs( netmsg.Tables ) do
          if string.StartWith( k, oldValue.__id ..'.' ) then netmsg.Tables[k] = nil end
        end
        netmsg.Tables[oldValue.__id] = nil
      end


      rawset( netmsg.Tables[self.__id], key, value )
      if isfunction( value ) then rawset( self, key, value ) return end

      if istable( value ) and not IsColor( value ) and not isvector( v ) then
        -- Subtables need to be networked, and be given the parent's filter
        value.__filter = self.__subFilter

        netmsg.NetworkTable( value, self.__id ..'.'.. key, nil, self.__id, key )
        return
      end

      if self.__filter and string.sub( key, 0, 2 ) ~= '__' then
        -- Perform filtering for each player
        for _, ply in pairs( player.GetAll() ) do
          local v = self:__filter( ply, key, value )
          netmsg.Send( 'netmsg.SyncKey', { id= self.__id, k= key, v= v }, ply )
        end

      else netmsg.Send( 'netmsg.SyncKey', { id= self.__id, k= key, v= value } ) end

    end,
    __index = function( self, key )
      local id = rawget( self, '__id' )
      if not id then return rawget( self, key ) end

      if key == '__tab' then return netmsg.Tables[id] end

      local value = rawget( netmsg.Tables[id], key )
      return value
    end
  }

  util.AddNetworkString( 'netmsg.Msg' )

  function netmsg.Send( name, tab, plys )
    tab = tab ~= nil and( istable(tab) and tab or {tab} ) or {}
    plys = plys or player.GetAll()

    local data = von.serialize( tab )
    data = util.Compress( data )

    net.Start( 'netmsg.Msg' )
      net.WriteString( name )
      net.WriteUInt( data and #data or 0, 32 )
      if data then net.WriteData( data, #data ) end
    net.Send( plys )

    return function( done ) netmsg.Receive( name, done ) end
  end

  function netmsg.Respond( tab )
    if not lastNetmsg then Error( '[NET] No message to respond to' ) return end

    netmsg.Send( lastNetmsg, tab, lastPly )
  end

  function EntityMeta:SetNWVar( name, public, private )
    if not IsValid( self ) then return end
    local plys

    self.netmsg_PubVars = self.netmsg_PubVars or {}
    self.netmsg_PrivVars = self.netmsg_PrivVars or {}

    self.netmsg_PubVars[ name ] = public
    if self:IsPlayer() then self.netmsg_PrivVars[ name ] = private end

    if private and self:IsPlayer() then
      plys = player.GetAll()
      table.RemoveByValue( plys, self )

      netmsg.Send( 'netmsg.SyncVar', { name= name, val= private, ent= self }, self )
    end
    netmsg.Send( 'netmsg.SyncVar', { name= name, val= public, ent= self }, plys )

    hook.Run( 'netmsg.NWVarChange', self, name, public, private )
  end

  -- TODO: Ensure that all entity/player vars are shared (private ones?)
  function EntityMeta:SyncNWVars()
    for k, ent in pairs( ents.GetAll() ) do
      if not ent.netmsg_PubVars then continue end
      for name, val in pairs( ent.netmsg_PubVars ) do
        netmsg.Send( 'netmsg.SyncVar', { name= name, val= val, ent= ent }, self )
      end
    end

    if self.netmsg_PubVars then
      for name, val in pairs( self.netmsg_PubVars ) do
        netmsg.Send( 'netmsg.SyncVar', { name= name, val= val, ent= self }, self )
      end
    end

    if self.netmsg_PrivVars then
      for name, val in pairs( self.netmsg_PrivVars ) do
        netmsg.Send( 'netmsg.SyncVar', { name= name, val= val, ent= self }, self )
      end
    end

  end

  netmsg.Receive( 'netmsg.NWSync', function( _, ply )
    ply:SyncNWVars()
    for k, tab in pairs( netmsg.Tables ) do
      if tab.__parent then continue end
      netmsg.SyncTable( tab, ply )
    end
    timer.Simple( .1, function() netmsg.Call( ply, 'netmsg.TableSyncDone' ) end )
  end )

  function netmsg.Call( plys, name, ... )
    netmsg.Send( 'netmsg.Call', { name= name, args= {...} }, plys )
  end

  -- Recursively apply filtering to a table for a specific player
  local function filterTable( tab, ply )
    local filtered = {}
    table.Merge( filtered, tab.__tab or tab )

    for k, v in pairs( netmsg.safeTable( tab ) ) do
      if tab.__filter and not string.StartWith( k, '__' ) then
        filtered[k] = tab:__filter( ply, k, v )
      end
      if istable( tab[k] ) and tab[k].__filter then filtered[k] = filterTable( tab[k], ply ) end
    end

    return filtered
  end

  -- Sync a table to a player so they have all the correct data
  function netmsg.SyncTable( tab, plys )
    if not tab.__id then
      Error( '[NET] SyncTable given table with no network identifier' )
      return
    end

    plys = plys and ( istable(plys) and plys or {plys} ) or player.GetAll()
    if tab.__filter or tab.__subFilter then
      for k, ply in pairs( plys ) do

        local sendTab = filterTable( tab, ply )
        sendTab = netmsg.safeTable( sendTab )

        netmsg.Send( 'netmsg.SyncTable', sendTab, ply )
      end

    else
      netmsg.Send( 'netmsg.SyncTable', tab, plys )
    end
  end

end

if CLIENT then

  function netmsg.Send( name, tab )

    local data = von.serialize( tab ~= nil and( istable(tab) and tab or {tab} ) or {} )
    data = util.Compress( data )

    net.Start( 'netmsg.Msg' )
      net.WriteString( name )
      net.WriteUInt( data and #data or 0, 32 )
      if data then net.WriteData( data, #data ) end
    net.SendToServer()

    return function( done ) netmsg.Receive( name, done ) end
  end

  netmsg.Receive( 'netmsg.SyncKey', function( tab )
    if not netmsg.Tables[ tab.id ] then netmsg.Tables[ tab.id ] = {} end

    if tab.v == nil then
      local v = netmsg.Tables[ tab.id ][ tab.k ]
      if istable( v ) and v.__id then netmsg.Tables[ v.__id ] = nil end
    end

    netmsg.Tables[ tab.id ][ tab.k ] = tab.v

    if not reservedKeys[tab.k] and netmsg.Tables[ tab.id ].__onKeySync then
      netmsg.Tables[ tab.id ]:__onKeySync( tab.k, tab.v )
    end
  end )

  netmsg.Receive( 'netmsg.SyncTable', function( tab )
    local id, parent, key = tab.__id, tab.__parent, tab.__key

    if netmsg.Tables[id] then
      for k, v in pairs( netmsg.Tables[id] ) do
        if isfunction( v ) then tab[k] = v end
      end
      table.Empty( netmsg.Tables[id] )

    else netmsg.Tables[id] = {} end

    for k, v in pairs( netmsg.Tables ) do
      if string.StartWith( k, id ..'.' ) then netmsg.Tables[k] = nil end
    end

    table.CopyFromTo( tab, netmsg.Tables[id] )
    if parent and key then netmsg.Tables[parent][key] = netmsg.Tables[id] end

    -- Run __onKeySync for parent
    if not reservedKeys[key] and netmsg.Tables[parent] and netmsg.Tables[parent].__onKeySync then
      netmsg.Tables[parent]:__onKeySync( key, tab )
    end

    findSubTables( netmsg.Tables[ id ] )
  end )

  netmsg.Receive( 'netmsg.SyncVar', function( tab )
    if not IsValid( LocalPlayer() ) then return end
    local ent = tab.ent
    if not IsValid( ent ) then return end

    ent.netmsg_PubVars = ent.netmsg_PubVars or {}
    ent.netmsg_PrivVars = ent.netmsg_PrivVars or {}

    local index = 'netmsg_'.. ( ent == LocalPlayer() and 'Priv' or 'Pub' ) ..'Vars'
    ent[index][tab.name] = tab.val

    hook.Run( 'netmsg.NWVarChange', ent, tab.val )
  end )

  hook.Add( 'InitPostEntity', 'netmsg.NWVarSync', function()
    netmsg.Send( 'netmsg.NWSync' )
  end )

  hook.Add( 'netmsg.TableSyncDone', 'netmsg.TableSyncDone', function()
    findSubTables( netmsg.Tables )
  end )

  netmsg.Receive( 'netmsg.Call', function( data )
    hook.Run( data.name, unpack( data.args ) )
  end )

end
