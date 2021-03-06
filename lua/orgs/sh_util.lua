-- Python's string formatting is beautiful
getmetatable''.__mod = function( self, tab )
  return string.format( self, unpack( tab ) )
end

orgs.Log = function( ... )

  if debug and not orgs.Debug then return end

  local col, tab = orgs.Colors.Text, {}
  for k, str in pairs( {...} ) do
    if k == #{...} then str = (str or '') ..'\n' end
    table.insert( tab, col )
    table.insert( tab, str )
    col = col == orgs.Colors.Text and orgs.Colors.Secondary or orgs.Colors.Text
  end

  MsgC( orgs.Colors.Primary, 'ORGS: ', unpack( tab ) )
end

orgs.DebugLog = function( ... )
  if not orgs.Debug then return end

  orgs.Log( ... )
end

orgs.ErrorLog = function( ... )

  local col, tab = orgs.Colors.Error, {}
  for k, str in pairs( {...} ) do
    if k == #{...} then str = str ..'\n' end
    table.insert( tab, col )
    table.insert( tab, str )
    col = col == orgs.Colors.Error and orgs.Colors.Secondary or orgs.Colors.Error
  end

  MsgC( orgs.Colors.Primary, 'ORGS ERROR: ', unpack( tab ) )
end

orgs.Get = function( id ) return orgs.List[id] end

orgs.LogEvent = function( type, tab )
  local event = orgs.ParseEvent( type, tab )
  orgs.addEvent( type, event )
  orgs.Log( unpack( orgs.EventToString( table.Copy(event), true ) ) )
end

orgs.ParseEvent = function( type, tab )

  if isentity( tab.ActionBy ) then
    tab.ActionBy = tab.ActionBy:SteamID64()
  end

  if isentity( tab.ActionAgainst ) then
    tab.ActionAgainst = tab.ActionAgainst:SteamID64()
  end

  tab.Type = tab.Type or type
  tab.Time = tab.Time or os.time()

  return tab
end

orgs.EventToString = function( tab, explode )
  local str = orgs.EventStrings[ tab.Type ]
  if not str then orgs.ErrorLog( 'Found no text to parse for event ', tab.Type ) return end
  if isfunction( str ) then str = str( tab ) end

  if tab.OrgID and orgs.List[tab.OrgID] then
    tab.OrgID = (orgs.Debug and '%s [%s]' or '%s')
      %{orgs.List[tab.OrgID].Name, orgs.Debug and tab.OrgID or nil}
  end

  if tab.ActionBy then
    local steamID = tab.ActionBy
    local ply = ( CLIENT and steamID == LocalPlayer():SteamID64() and '(You)' )
    or (orgs.Members[steamID] and orgs.Members[steamID].Nick)
    or (player.GetBySteamID64( steamID ) and player.GetBySteamID64( steamID ):Nick())
    if ply then tab.ActionBy = (orgs.Debug and '%s [%s]' or '%s')
      %{ply, orgs.Debug and tab.ActionBy or nil} end
  end

  local getOrg = table.HasValue( {orgs.EVENT_BANK_TRANSFER}, tab.Type )
  if tab.ActionAgainst and not getOrg then
    local steamID = tab.ActionAgainst
    local ply = ( CLIENT and steamID == LocalPlayer():SteamID64() and '(You)' )
    or (orgs.Members[steamID] and orgs.Members[steamID].Nick)
    or (player.GetBySteamID64( steamID ) and player.GetBySteamID64( steamID ):Nick())
    if ply then tab.ActionAgainst = (orgs.Debug and '%s [%s]' or '%s')
      %{ply, orgs.Debug and tab.ActionAgainst or nil} end

  elseif tab.ActionAgainst and getOrg then
    local orgID = tonumber( tab.ActionAgainst )
    local org = orgs.List[orgID] and orgs.List[orgID].Name
    if org then tab.ActionAgainst = (orgs.Debug and '%s [%s]' or '%s')
      %{org, orgs.Debug and orgID or nil} end
  end

  tab.ActionBy = tab.ActionBy or '(Someone)'
  tab.ActionAgainst = tab.ActionAgainst or '(Someone)'
  tab.ActionValue = tab.ActionValue == '' and '(Nothing)' or tab.ActionValue

  for k, v in pairs( tab ) do
    str = string.Replace( str, '['.. k ..']', '%'.. tostring(v) ..'%' )
  end

  return explode and string.Explode( '%', str ) or str
end

local postfixes = {'K','M','B','T','QD','QT'}
orgs.FormatCurrencyShort = function( amt, len )
  amt = tonumber( amt )
  if not amt then return end
  len = len or 6

  local str = orgs.CurrencySymbolLeft and orgs.CurrencySymbol or ''

  local k = 1
  while k < #postfixes and amt /(1000 ^k) >= 1 do
    k = k +1
  end

  local val = amt /(1000 ^(k -1))
  local valLen = tostring( math.floor(val) ):len()
  str = str.. ( '%.'.. ( len -valLen -orgs.CurrencySymbol:len() -( postfixes[k-1] or '' ):len() > 2
    and '2' or '0' ) ..'f%s' )
    %{ math.Round( val, 2 ), postfixes[k-1] or '' }

  return str.. ( not orgs.CurrencySymbolLeft and orgs.CurrencySymbol or '' )
end

orgs.FormatCurrency = function( amt )
  amt = tonumber( amt )
  if not amt then return end

  return (orgs.CurrencySymbolLeft and orgs.CurrencySymbol or '')
    .. string.Comma( math.floor(amt) )
    .. (not orgs.CurrencySymbolLeft and orgs.CurrencySymbol or '')
end

function Enum( parent, prefix, tab )
  for k, v in pairs( tab ) do
    parent[prefix..v] = k -1
  end
end

function TruthTable( tab )

  local new = {}
  for k, v in pairs( tab ) do new[v] = true end

  return new
end

function orgs.Has( ply, ... )
  if not ply or #{...} < 1 then return false end

  -- 'ply' is either player data table, entity, or SteamID64
  ply = istable( ply ) and ply or orgs.Members[isentity( ply ) and ply:SteamID64() or ply]
  if not ply or not ply.RankID or not orgs.Ranks[ ply.RankID ] then return false end

  -- Combine player and rank permissions
  plyPerms = TruthTable( string.Explode( ',',
    ( ply.Perms or '' ) .. ( orgs.Ranks[ ply.RankID ].Perms or '' ) ) )
  if not plyPerms then return false end

  local hasPerms = true
  for k, v in pairs( {...} ) do
    if not v or not plyPerms[tostring(v)] then return false end
  end

  return true
end

function orgs.RankHas( rank, ... )
  local rank = orgs.Ranks[rank]
  if not rank or #{...} < 1 then return false end

  rankPerms = rank.Perms and TruthTable( string.Explode( ',', rank.Perms ) )
  if not rankPerms then return false end

  for k, v in pairs( {...} ) do
    if not v or not rankPerms[tostring(v)] then return false end
  end

  return true
end

local player = FindMetaTable( 'Player' )

function player:orgs_Org( id )
  local orgID = self:GetNWVar( 'orgs.OrgID' )
  return ( id or not orgID ) and orgID or orgs.List[orgID]
end

function player:orgs_Info()
  if not self:orgs_Org(0) then return end
  return orgs.Members[self:SteamID64()]
end

function player:orgs_Rank( id )
  if not self:orgs_Org(0) then return end
  local rankID = self:orgs_Info().RankID
  return (id or not rankID) and rankID or orgs.Ranks[rankID]
end

function player:orgs_Has( ... )
  if not self:orgs_Org(0) then return false end

  return orgs.Has( self, ... )
end
