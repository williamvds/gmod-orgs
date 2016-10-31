netmsg = netmsg or { Hooks = {}, Tables = {} }
local EntityMeta = FindMetaTable( 'Entity' )

local function iscolor( tab )

  return tab.r and tab.g and tab.b and tab.a
end

function safeTable( tab, clean )
  local newTab = {}
  table.Merge( newTab, getmetatable( tab ) and tab.__tab or tab )  -- Prevents copying metatable

  if clean then
    newTab.__tabID = nil
    newTab.__filter = nil
    newTab.__subFilter = nil
  end

  for k, v in pairs( newTab ) do
    if isfunction( v ) then newTab[k] = nil end
    if istable( v ) then newTab[k] = safeTable( getmetatable(v) and v.__tab or v ) end
  end

  return newTab
end

-- Should only be passed netmsg tables (without metatable)
local function findSubTables( tab )
  for k, v in pairs( tab ) do
    if istable(v) and not iscolor(v) and not isvector(v)
    and ( (SERVER and not v.__tabID) or CLIENT ) then
      v.__filter = tab.__subFilter
      netmsg.NetworkTable( v, (tab.__tabID and tab.__tabID ..'.' or '') .. k )
    end
  end
end

function netmsg.Receive( name, func )
  netmsg.Hooks[ name ] = func
end

function netmsg.NetworkTable( tab, id, ... )
  if SERVER and tab.__tabID then return end

  tab.__tabID = id
  if SERVER then
    local filter, subFilter = tab.__filter, tab.__subFilter

    netmsg.Tables[id] = {}
    table.Merge( netmsg.Tables[id], tab )
    findSubTables( netmsg.Tables[id] )

    table.Empty( tab )
    tab.__tabID = id
    tab.__filter = filter
    tab.__subFilter = subFilter

    setmetatable( tab, netmsg.METATABLE )

    netmsg.SyncTable( netmsg.Tables[id], unpack{...} )
    return
  end

  netmsg.Tables[id] = tab
  if CLIENT then findSubTables( netmsg.Tables[id] ) end
end

function EntityMeta:GetNWVar( name, def )

  return ( self.net_PrivVars and self.net_PrivVars[ name ] )
    or ( self.net_PubVars and self.net_PubVars[ name ] ) or def
end

local lastNetmsg, lastPly
net.Receive( 'netmsg.Msg', function( _, ply )

  local name = net.ReadString()
  local done = netmsg.Hooks[ name ]

  if not done then
    MsgN( string.format('[NET] Could not find hook for message %s', name ) )
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
      rawset( netmsg.Tables[self.__tabID], key, value )
      if isfunction( value ) then rawset( self, key, value ) return end

      --if not self.__tabID then return end

      if istable( value ) and not iscolor( value ) and not isvector( v ) then
        -- Subtables need to be networked, and be given the parent's filter
        value.__filter = self.__subFilter

        netmsg.NetworkTable( value, self.__tabID ..'.'.. key, nil, self.__tabID, key )

      elseif value then
        -- Perform filtering for each player
        for _, ply in pairs( player.GetAll() ) do
          local v = value
          if self.__filter and string.sub( key, 0, 2 ) ~= '__' then
            v = self:__filter( ply, key, value )
          end
          if not v then continue end
          netmsg.Send( 'netmsg.SyncKey', { id= self.__tabID, k= key, v= v }, ply )
        end

      else netmsg.Send( 'netmsg.RemoveKey', { id= self.__tabID, k= key } ) end
      -- TODO: check filter for RemoveKey?
    end,
    __index = function( self, key )
      local id = rawget( self, '__tabID' )
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

    self.net_PubVars = self.net_PubVars or {}
    self.net_PrivVars = self.net_PrivVars or {}

    self.net_PubVars[ name ] = public
    if self:IsPlayer() then self.net_PrivVars[ name ] = private end

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
      if not ent.net_PubVars then continue end
      for name, val in pairs( ent.net_PubVars ) do
        netmsg.Send( 'netmsg.SyncVar', { name= name, val= val, ent= ent }, self )
      end
    end

    if self.net_PubVars then
      for name, val in pairs( self.net_PubVars ) do
        netmsg.Send( 'netmsg.SyncVar', { name= name, val= val, ent= self }, self )
      end
    end

    if self.net_PrivVars then
      for name, val in pairs( self.net_PrivVars ) do
        netmsg.Send( 'netmsg.SyncVar', { name= name, val= val, ent= self }, self )
      end
    end

  end

  netmsg.Receive( 'netmsg.NWSync', function( _, ply )
    ply:SyncNWVars()
    for k, tab in pairs( netmsg.Tables ) do
      netmsg.SyncTable( tab, ply )
    end
    timer.Simple( .1, function() netmsg.Call( ply, 'netmsg.TableSyncDone' ) end )
  end )

  function netmsg.Call( plys, name, ... )
    netmsg.Send( 'netmsg.Call', { name= name, args= {...} }, plys )
  end

  function netmsg.SyncTable( tab, plys, parent, key )
    if not tab.__tabID then
      Error( '[NET] SyncTable given table with no network identifier' )
      --PrintTable( tab )
      return
    end

    if tab.__filter then
      for k, ply in pairs( plys and (istable(plys) and plys or {plys}) or player.GetAll() ) do
        sendTab, safeTab = safeTable( tab ),  safeTable( tab, true )
        for k, v in pairs( safeTab ) do
          if tab.__filter then sendTab[k] = tab:__filter( ply, k, v ) end
        end

        netmsg.Send( 'netmsg.SyncTable', parent
          and {tab= safeTable(sendTab), p= parent, k= key, __hasParent= true}
          or safeTable(sendTab), ply )
      end

    else netmsg.Send( 'netmsg.SyncTable', parent
      and {tab= safeTable(tab), p= parent, k= key, __hasParent= true}
      or safeTable(tab), plys ) end
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
    if not tab.id then return end -- TODO: Look into some tables being sent with no id
    if not netmsg.Tables[ tab.id ] then netmsg.Tables[ tab.id ] = {} end
    netmsg.Tables[ tab.id ][ tab.k ] = tab.v

    if netmsg.Tables[ tab.id ].__onKeySync then
      netmsg.Tables[ tab.id ]:__onKeySync( tab.k, tab.v )
    end
  end )

  netmsg.Receive( 'netmsg.RemoveKey', function( tab )
    local v = netmsg.Tables[ tab.id ][ tab.k ]
    --if istable( v ) and v.__tabID then netmsg.Tables[ tab.__tabID ] = nil end
    netmsg.Tables[ tab.id ][ tab.k ] = nil
    if netmsg.Tables[ tab.id ].__onKeySync then netmsg.Tables[ tab.id ]:__onKeySync( tab.k ) end
  end )

  netmsg.Receive( 'netmsg.SyncTable', function( tab )
    local id = tab.__hasParent and tab.tab.__tabID or tab.__tabID

    if netmsg.Tables[ id ] then
      for k, v in pairs( netmsg.Tables[ id ] ) do
        if isfunction( v ) then tab[k] = v end
      end

    else netmsg.Tables[ id ] = {} end

    table.CopyFromTo( tab.__hasParent and tab.tab or tab, netmsg.Tables[ id ] )
    if tab.__hasParent then netmsg.Tables[tab.p][tab.k] = netmsg.Tables[id] end

    if tab.p and netmsg.Tables[ tab.p ].__onKeySync then
      netmsg.Tables[ tab.p ]:__onKeySync( tab.k, tab.tab )
    elseif tab.__onKeySync then netmsg.Tables[ tab.__tabID ]:__onKeySync() end

    findSubTables( netmsg.Tables[ id ] )
  end )

  netmsg.Receive( 'netmsg.LinkTables', function( tab )
    netmsg.Tables[tab.id][tab.k] = netmsg.Tables[ tab.t ]
  end )

  netmsg.Receive( 'netmsg.SyncVar', function( tab )
    if not IsValid( LocalPlayer() ) then return end
    local ent = tab.ent
    if not IsValid( ent ) then return end

    ent.net_PubVars = ent.net_PubVars or {}
    ent.net_PrivVars = ent.net_PrivVars or {}

    local index = 'net_'.. ( ent == LocalPlayer() and 'Priv' or 'Pub' ) ..'Vars'
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
