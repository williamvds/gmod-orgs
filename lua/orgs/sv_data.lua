if not file.Exists( 'orgs/providers/'.. orgs.Provider ..'.lua', 'LUA' ) then
  orgs.LogError( false, 'Invalid provider '.. orgs.Provider ..' specified - defaulting to SQLite' )
  orgs.Provider = 'sqlite'
end

orgs._Provider = orgs._Provider or include( 'providers/'.. orgs.Provider ..'.lua' )

local function getID( var )
  return isentity( var ) and var:SteamID64() or var
end

orgs.addEvent = function( type, tab )
  local copy = table.Copy( tab )
  orgs._Provider.addEvent( type, copy, function( id )
    tab.EventID = id
    orgs.Events[id] = tab
  end )
end

--[[ Players ]]

-- Given: steamID
-- Expected: table of player attributes
orgs.getPlayer = function( ply, done )

  local steamID = getID( ply )
  orgs.Log( true, 'Fetching information for ', '%s [%s]' %{ ply:Nick(), steamID } )

  orgs._Provider.getPlayer( steamID, function( data, err )
    if not data then orgs.addPlayer( IsValid( ply ) and ply or steamID ) return end
    if err then return end -- TODO: Add an error message of some sort?

    -- if not orgs.Members[steamID] and isentity( ply ) and IsValid( ply ) then
    --   orgs.Members[steamID] = {Nick=ply:Nick(),SteamID=steamID}
    -- end

    if data.OrgID then
      if IsValid( ply ) then
        ply:SetNWVar( 'orgs.OrgID', data.OrgID )
        netmsg.SyncTable( orgs.Members, ply )
        netmsg.SyncTable( orgs.Ranks, ply )
      end
      if not orgs.Loaded[ data.OrgID ] then
        orgs.getOrgRanks( data.OrgID )
        orgs.getOrgMembers( data.OrgID )
        orgs.getOrgEvents( data.OrgID )
      end
    end

    if IsValid( ply ) and not data.Nick or data.Nick ~= ply:Nick() then
      orgs.updatePlayer( steamID, {Nick= ply:Nick()} )
    end

    hook.Run( 'orgs.AfterLoadPlayer', ply, data.OrgID )
    if done then done( data, err ) end
  end )

end
hook.Add( 'PlayerInitialSpawn', 'orgs.GetPlayerInfo', orgs.getPlayer )

-- Given: player, function callback
orgs.addPlayer = function( ply, done )

  orgs.Log( true, 'Storing player info for ', isentity( ply )
    and '%s [%s]' %{ply:Nick(), ply:SteamID64()} or ply )
  orgs._Provider.addPlayer( getID( ply ), isentity( ply ) and IsValid( ply )
    and ply:Nick() or '???',
  function( data, err )
    if done then done( data, err ) end
  end )

end

-- Given: steamID, table of attributes, player performing action, function callback
orgs.updatePlayer = function( ply, tab, ply2, done )
  if not tab or not istable( tab ) then return 1 end
  local steamID, steamID2 = getID( ply )
  local member, member2 = orgs.Members[steamID]

  if member then
    for k, v in pairs( tab ) do
      if v == '' then tab[k] = NULL end
      if ( tab[k] == NULL and nil or tab[k] ) == member[k] then tab[k] = nil continue end
    end
  end

  if table.Count( tab ) < 1 then return 1 end
  tab.Salary = tab.Salary and math.floor( tonumber( tab.Salary ) )

  if ply2 then
    if not member then return 2 end
    steamID2 = getID( ply2 )
    member2 = orgs.Members[steamID2]

    if member2.OrgID ~= member.OrgID then
    -- Actor not member of target's Org
      return 2
    elseif tab.SteamID or tab.OrgID and tab.OrgID ~= NULL or tab.Nick then
    -- Attempting to change values that are not allowed
      return 3
    elseif not orgs.Has( ply2, orgs.PERM_PROMOTE ) then
    -- Actor not allowed to promote
      return 4
    elseif not orgs.Has( ply2, orgs.PERM_KICK ) and tab.OrgID == NULL then
    -- Attempting to kick without permissions
      return 5
    elseif member.SteamID ~= member2.SteamID
    and orgs.Ranks[member2.RankID].Immunity <= orgs.Ranks[ member.RankID ].Immunity then
    -- (Not targeting self) and doesn't have immunity
      return 6
    elseif tab.RankID and tab.RankID ~= NULL
    and orgs.Ranks[member2.RankID].Immunity < orgs.Ranks[ tab.RankID ].Immunity then
    -- Actor doesn't have immunity over target rank
      return 7
    elseif tab.Perms and tab.Perms ~= NULL
    and not orgs.Has( ply2, unpack( string.Explode( ',', tab.Perms ) ) ) then
    -- Actor does not have desired perms
      return 8
    end
  end

  if tab.OrgID and tab.OrgID ~= NULL then
    local org = orgs.List[tab.OrgID]
    if not org then
      -- Org does not exist
      return 9
    elseif org.Members >= orgs.Types[org.Type].MaxMembers then
      -- Target group full
      return 10
    elseif not org.Forming and not org.Public then
      -- Not public TODO: check invitations
      return 11
    end
  end

  if tab.RankID and tab.RankID ~= NULL then
    if not orgs.Ranks[ tab.RankID ] then
    -- Rank doesn't exist
      return 12
    elseif (member and not tab.OrgID) and member.OrgID
    and member.OrgID ~= orgs.Ranks[ tab.RankID ].OrgID then
    -- Rank not part of current Org
        return 13
    elseif not member and ( not tab.OrgID or tab.OrgID ~= orgs.Ranks[ tab.RankID ].OrgID ) then
    -- Rank not part of target Org
      return 14
    end
  end


  if tab.OrgID and tab.OrgID ~= NULL and not tab.RankID or tab.RankID == NULL then
    tab.RankID = orgs.List[ tab.OrgID ].DefaultRank
  end

  if tab.OrgID == NULL and member.OrgID then
    tab.RankID = NULL; tab.Perms = NULL; tab.Salary = NULL
  end

  orgs._Provider.updatePlayer( steamID, tab, function( data, err )
    local ply = player.GetBySteamID64( steamID )
    if err then
      orgs.Log( true, 'Failed to update player ', IsValid( ply ) and ply:Nick() or steamID )
      return
    end

    if tab.OrgID then
      if IsValid( ply ) then
        ply:SetNWVar( 'orgs.OrgID', tab.OrgID == NULL and nil or tab.OrgID )
      end

      if member and member.OrgID then
        orgs.List[member.OrgID].Members = orgs.List[member.OrgID].Members -1
      end

      if tab.OrgID ~= NULL then
        orgs.List[tab.OrgID].Members = orgs.List[tab.OrgID].Members +1

      else
        if steamID2 then orgs.LogEvent( orgs.EVENT_MEMBER_KICKED,
          {ActionBy= steamID2, ActionAgainst= steamID, OrgID= orgs.Members[steamID2].OrgID} )
        else orgs.LogEvent( orgs.EVENT_MEMBER_LEFT,
          {ActionBy= steamID, OrgID= orgs.Members[steamID].OrgID} )
        end

      end
    end

    if tab.RankID and tab.RankID ~= NULL then
      orgs.LogEvent( orgs.EVENT_MEMBER_RANK, {
        ActionBy= steamID2,
        OrgID= orgs.Members[steamID] and orgs.Members[steamID].OrgID or tab.OrgID,
        ActionAgainst= steamID,
        ActionValue= tab.RankID } )
    end

    local oldTab = orgs.Members[steamID] and safeTable( orgs.Members[steamID], true ) or {}

    if table.Count( oldTab ) < 1 then
      tab.Nick = IsValid( ply ) and ply:Nick() or '???'
      tab.SteamID = steamID
    end
    table.Merge( oldTab, tab )

    for k, v in pairs( tab ) do
      if v == NULL then
        tab[k] = nil
        oldTab[k] = nil
      end
    end

    orgs.Members[steamID] = oldTab

    -- if tab.OrgID then
    --   local plys = {}
    --   for k, ply in pairs( player.GetAll() ) do
    --     if ply:orgs_Org(0) == tab.OrgID then table.insert( plys, ply ) end
    --   end
    --   netmsg.SyncTable( orgs.Members, plys )
    -- end

    if IsValid( ply ) and tab.OrgID then
      netmsg.SyncTable( orgs.Ranks, ply )
      netmsg.SyncTable( orgs.Events, ply )
      netmsg.SyncTable( orgs.Members, ply )

      if tab.OrgID ~= NULL then
        timer.Simple( .1, function() netmsg.Call( ply, 'orgs.JoinedOrg' ) end )
      end
    end

    if done then done( data, err ) end
  end )

end

orgs.leaveOrg = function( ply, ply2, done )
  if ply2 then
    local member, ply2 = orgs.Members[getID(ply)], orgs.Members[getID(ply2)]
    if not member
    or member.OrgID ~= ply2.OrgID
    or not orgs.Has( ply2, orgs.PERM_KICK )
    or orgs.Ranks[ply2.RankID].Immunity <= orgs.Ranks[member.RankID].Immunity then
      return false
    end
  end

  local orgID
  if isentity(ply) then orgID = ply:orgs_Org(0)
  else orgID = orgs.Members[ply] and orgs.Members[ply].OrgID end
  if not orgID then return end

  orgs._Provider.updatePlayer( getID( ply ),
  {OrgID= NULL, RankID= NULL, Perms= NULL, Salary= NULL}, function( data, err )
    if err then return end

    if isentity( ply ) and IsValid( ply ) then
      ply:SetNWVar( 'orgs.OrgID', nil )

      netmsg.SyncTable( orgs.Members, ply )
      netmsg.SyncTable( orgs.Ranks, ply )
      netmsg.SyncTable( orgs.Events, ply )
    end

    orgs.Members[getID(ply)].OrgID = nil
    orgs.Members[getID(ply)].RankID = nil
    orgs.Members[getID(ply)].Perms = nil
    orgs.Members[getID(ply)].Salary = nil

    local plys = {}
    for k, ply in pairs( player.GetAll() ) do
      if ply:orgs_Org(0) == orgID then table.insert( plys, ply ) end
    end
    netmsg.SyncTable( orgs.Members, plys )

    if ply2 then orgs.LogEvent( orgs.EVENT_MEMBER_KICKED, {ActionBy= ply2, ActionAgainst= ply, OrgID= orgID} )
    else orgs.LogEvent( orgs.EVENT_MEMBER_LEFT, {ActionBy= ply, OrgID= orgID} ) end

    -- check # of members and delete if empty
    orgs.getOrgMembers( orgID, function( data, err )
      if #data == 0 then orgs.removeOrg( orgID ) end
    end )
    if done then done( data, err ) end
  end )
end

--[[ Organisations ]]
orgs.addOrg = function( tab, ply, done )
  local steamID = getID( ply )
  orgs._Provider.addOrg( tab, function( orgID, err )
    if err then return end

    local new = {Balance= 0, Color= '255,255,255', Type= 1, OrgID= orgID, Public= false, Members= 0,
      Forming= true}
    table.Merge( new, tab )

    orgs.List[orgID] = new
    orgs.LogEvent( orgs.EVENT_ORG_CREATED, {ActionBy= steamID, OrgID= orgID} )

    local imm = 1
    for k, rank in SortedPairsByMemberValue( orgs.DefaultRanks, 'Immunity' ) do
      rank.__key = nil
      orgs.addRank( orgID, rank, nil, imm == 1 and function( rankID, tab )
        orgs.updateOrg( orgID, {DefaultRank= rankID} )
      end or imm == table.Count( orgs.DefaultRanks ) and steamID and function( rankID, tab )
        orgs.updatePlayer( steamID, {OrgID= orgID, RankID= rankID}, nil, function()
          print( 'updatePlayer callback')
            orgs.List[orgID].Forming = nil -- So we can check if an org is public when joining
        end )
      end )
      imm = imm +1
    end
    orgs.Loaded[orgID] = true

    if done then done( data, err ) end
  end )

end

orgs.removeOrg = function( orgID )

  orgs.Log( false, 'Removing organisation ', orgID )

  orgs._Provider.removeOrg( orgID, function()
    orgs.getOrgMembers( orgID, function( data )
      for k, ply in pairs( data ) do orgs.updatePlayer( data.SteamID,
        {OrgID= NULL, RankID= NULL, Salary= NULL, Perms= NULL} )
      end
    end )

    orgs.List[orgID] = nil

  end )

end

orgs.getOrgMembers = function( orgID, done )

  orgs._Provider.getOrgMembers( orgID, function( data, err )
    if err then return end

    for k, v in pairs( data ) do orgs.Members[ v.SteamID ] = v end
    hook.Run( 'orgs.LoadedOrgMembers', orgid, data )

    if done then done( data, err ) end
  end )

end

orgs.addRank = function( orgID, tab, ply, done )
  local tab = table.Copy( tab )

  if not tab.Name or not tab.Immunity then
    -- Missing necessary information
    return 1, done( nil, 2 )
  end

  if isentity( ply ) and IsValid( ply ) and ( not ply:orgs_Has( orgs.PERM_RANKS )
  or ply:orgs_Rank().Immunity < tab.Immunity ) then
    -- Player has insufficient immunity or permissions to create rank
    return 2, done( nil, 2 )
  end

  local n = 0
  for k, rank in pairs( safeTable( orgs.Ranks, true ) ) do
    if rank.OrgID == orgID then n = n +1 end
  end
  if n >= orgs.MaxRanks then
    -- Group has too many ranks
    return 3
  end

  for k, rank in pairs( safeTable( orgs.Ranks, true ) ) do
    if rank.OrgID == orgID and rank.Name == tab.Name then
      -- Group already has rank with that name
      return 4
    end
  end

  tab.OrgID = orgID

  local steamID = getID( ply )
  orgs._Provider.addRank( orgID, tab, function( rankID, err )
    if err then return end

    tab.RankID = rankID
    orgs.Ranks[rankID] = tab
    orgs.LogEvent( orgs.EVENT_RANK_ADDED, {ActionBy= steamID, OrgID= orgID,
      ActionValue= tab.RankID} )

    if done then done( rankID, tab, err ) end
  end )
end

local rankEvents = {
  Name = orgs.EVENT_RANK_RENAME,
  Perms = orgs.EVENT_RANK_PERMS,
  Immunity = orgs.EVENT_RANK_IMMUNITY,
  BankLimit = orgs.EVENT_RANK_IMMUNITY,
  BankCooldown = orgs.EVENT_RANK_BANKCOOLDOWN,
}
orgs.updateRank = function( rankID, tab, ply, done )
  if not rankID or not tab or not istable( tab ) or table.Count( tab ) < 1 then return 1 end
  local rank, member, steamID = orgs.Ranks[ rankID ]

  -- Rank does not exist
  if not rank then return 2 end

  for k, v in pairs( tab ) do
    if v == '' then tab[k] = NULL end
    if ( tab[k] == NULL and nil or tab[k] ) == rank[k] then tab[k] = nil continue end
  end

  if table.Count( tab ) < 1 then return 1 end
  if tab.Immunity and tab.Immunity ~= NULL then tab.Immunity = tonumber( tab.Immunity ) end
  if ply then
    member, steamID = orgs.Members[getID(ply)], getID( ply )
    if not member or member.OrgID ~= rank.OrgID then
    --  Player not member of target org
      return 3
    elseif not orgs.Has( ply, orgs.PERM_RANKS ) then
    -- Member doesn't have perms
      return 4
    elseif orgs.Ranks[member.RankID].Immunity <= rank.Immunity then
    -- Attempting to change rank of equal or greater immunity
      return 5
    elseif tab.Immunity and orgs.Ranks[member.RankID].Immunity < tab.Immunity then
    -- Desired immunity is greater than player's rank's immunity
      return 6
    elseif tab.Perms and tab.Perms ~= NULL
    and not orgs.Has( ply, unpack( string.Explode( ',', tab.Perms ) ) ) then
    -- Player does not have desired perms
      return 7
    end
  end

  orgs._Provider.updateRank( rankID, tab, function( _, err )
    if err then return end

    for k, v in pairs( tab ) do
      orgs.Ranks[rankID][k] = v == NULL and nil or v
      if rankEvents[k] then
        if v == NULL then v = '' end
        orgs.LogEvent( rankEvents[k],
        {OrgID= rank.OrgID, ActionAgainst= rankID, ActionBy= steamID, ActionValue= v} )
      end
    end

    if done then done( tab, err ) end
  end )

end

orgs.removeRank = function( rankID, ply, done )
  local rank, steamID, orgID = orgs.Ranks[rankID], getID( ply )
  if rank then orgID = rank.OrgID end

  if not rank then
    -- Rank does not exist
    return 1
  elseif ply and ply:orgs_Org(0) ~= rank.OrgID or not ply:orgs_Has( orgs.PERM_RANKS ) then
    -- Wrong org or doesn't have permission
    return 2
  elseif ply and ply:orgs_Rank().Immunity <= rank.Immunity then
    -- Member doesn't have required immunity
    return 3
  elseif rankID == orgs.List[rank.OrgID].DefaultRank then
    -- Rank is default for org
    return 4
  end

  -- Reset members of deleted to the default rank
  for k, mem in pairs( safeTable( orgs.Members, true ) ) do
    if mem.RankID ~= rankID then continue end
    orgs.updatePlayer( mem.SteamID, {RankID= orgs.List[orgID].DefaultRank}, steamID )
  end

  orgs._Provider.removeRank( rankID, function( data, err )
    orgs.LogEvent( orgs.EVENT_RANK_REMOVED,
      {ActionBy= steamID, OrgID= orgID, ActionValue= orgs.Ranks[rankID].Name} )
      orgs.Ranks[rankID] = nil
    if done then done( data, err ) end
  end )
end

orgs.getOrgRanks = function( orgID, done )
  orgs._Provider.getOrgRanks( orgID, function( data, err )
    if err then return end

    for k, rank in pairs( data ) do orgs.Ranks[rank.RankID] = rank end
    orgs.Loaded[orgID] = true

    if done then done( data, err ) end
  end )

end

local orgEvents = {
  Type= orgs.EVENT_ORG_TYPE,
  Name= orgs.EVENT_ORG_NAME,
  Motto= orgs.EVENT_ORG_MOTTO,
  Tag= orgs.EVENT_ORG_TAG,
  Color= orgs.EVENT_ORG_COLOR,
  DefaultRank= orgs.EVENT_ORG_DEFAULTRANK,
  Public= orgs.EVENT_ORG_OPEN,
}
orgs.updateOrg = function( orgID, tab, ply, done )
  local org, steamID, member = orgs.List[orgID]
  if not orgID or not org or not tab or table.Count( tab ) < 1 then return 1 end

  for k, v in pairs( tab ) do
    if v == '' then tab[k] = NULL end
    if ( tab[k] == NULL and nil or tab[k] ) == org[k] then tab[k] = nil continue end
  end

  if table.Count( tab ) < 1 then return 1 end

  if ply then
    steamID = getID( ply )
    member = orgs.Members[steamID]

    if tab.OrgID or tab.Balance then
    -- Player attempting to change values they shouldn't
      return 2
    elseif not member or not member.OrgID or member.OrgID ~= orgID then
    -- If actor is not a member TODO: Admin check?
      return 3
    elseif tab.Bulletin and not orgs.Has( ply, orgs.PERM_BULLETIN ) then
    -- If player does not have bulletin perms
      return 4
    end

    if not orgs.Has( ply, orgs.PERM_MODIFY ) then
    -- If actor does not have modify perms
      for k, v in pairs( tab ) do
        if k ~= 'Bulletin' and k ~= 'Balance' then return 5 end
      end
    end
  end

  -- If Balance is invalid
  if tab.Balance and tab.Balance < 0 then return 6 end

  -- Name invalid
  if tab.Name == NULL then return 7 end

  if tab.Name and tab.Name:len() > orgs.MaxNameLength then
    -- Name too long
    return 8
  elseif tab.Tag and tab.Tag ~= NULL and tab.Tag:len() > orgs.MaxTagLength then
    -- Tag too long
    return 9
  elseif tab.Motto and tab.Motto ~= NULL and tab.Motto:len() > orgs.MaxMottoLength then
    -- Motto too long
    return 10
  elseif tab.Bulletin and tab.Bulletin ~= NULL and tab.Bulletin:len() > orgs.MaxBulletinLength then
    -- Bulletin too long
    return 11
  end

  if (tab.Name and tab.Name ~= NULL) or (tab.Tag and tab.Tag ~= NULL) then
    for k, v in pairs( safeTable( orgs.List, true ) ) do
      if v.OrgID == org.OrgID then continue end
      -- If name is duplicated
      if tab.Name and tab.Name ~= NULL and v.Name:lower() == tab.Name:lower() then return 12 end
      if tab.Tag and tab.Tag ~= NULL and v.Tag
      -- If tag is duplicated
      and v.Tag:lower() == tab.Tag:lower() then return 13 end
    end
  end

  if tab.DefaultRank and not orgs.Ranks[tab.DefaultRank]
  or ( orgs.Ranks[tab.DefaultRank] and orgs.Ranks[tab.DefaultRank].OrgID ~= orgID ) then
    -- Invalid default rank
    return 14
  end

  if tab.Type then
    local tp = orgs.Types[ tab.Type ]
    if not tp then
      -- Invalid type
      return 15
    elseif org.Members < tp.MembersRequired then
      -- Too few members
      return 16
    elseif org.Members > tp.MaxMembers then
      -- Too many members
      return 17
    end

    tab.Balance = math.Clamp( tab.Balance or org.Balance, 0, tp.MaxBalance )
  end

  orgs._Provider.updateOrg( orgID, tab, function( data, err )

    for k, v in pairs( tab ) do
      if not orgEvents[k] then continue end
      if v == NULL then v = '' end
      orgs.LogEvent( orgEvents[k],
        {OrgID= orgID, ActionBy= steamID, ActionValue= v} )
    end

    for k, v in pairs( tab ) do
      orgs.List[orgID][k] = v == NULL and nil or v
    end

    if tab.Bulletin then
      orgs.LogEvent( orgs.EVENT_ORG_BULLETIN, {OrgID= orgID, ActionBy= steamID} )
    end

    if done then done( data, err ) end
  end )

end

orgs.getOrgEvents = function( orgID, done )
  orgs._Provider.getOrgEvents( orgID, function( data, err )
    for k, event in pairs( data ) do
      orgs.Events[event.EventID] = event
    end
  end )
end

orgs.getAllOrgs = function( done )
  orgs._Provider.getAllOrgs( function( data, err )
    if err then LogError( false, 'Couldn\'t load organisation list!' ) return end

    for k, v in pairs( data ) do
      orgs.List[v.OrgID] = v
      orgs.getOrgMembers( v.OrgID )
    end

    if done then done( data, err ) end
  end )
end
