-- Handles all networking for the menus etc

orgs.ChatLog = function( plys, ... )
  netmsg.Send( 'orgs.ChatLog', {...}, plys )
end

hook.Add( 'PlayerSay', 'orgs.ChatCommand', function( ply, text )
  if GAMEMODE.ThisClass == 'gamemode_darkrp' or DarkRP then return end

  if string.lower( text ) == orgs.CommandPrefix..orgs.Command then
    if orgs._Provider.Failed then
      orgs.ChatLog( ply, orgs.C_RED, 'Organisations couldn\'t connect to the database - '
        ..'please warn an admin as soon as possible!' )
      return false
    end

    netmsg.Send( 'orgs.OpenMenu', nil, ply )

    return false
  end

end )

netmsg.Receive( 'orgs.JoinMenu.Create', function( tab, ply )
  if ply.orgs_GroupLock then return end
  ply.orgs_GroupLock = true

  local err = orgs.addOrg( tab, ply, function()
    ply.orgs_GroupLock = nil
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.LeaveOrg', function( _, ply )
  orgs.updatePlayer( ply, {OrgID= NULL}, nil, function() netmsg.Call( ply, 'orgs.LeftOrg' ) end )
end )

-- BULLETIN

netmsg.Receive( 'orgs.Menu.Bulletin', function( tab, ply )
  local err = orgs.updateOrg( ply:orgs_Org(0), {Bulletin= tab[1]}, ply, function()
    netmsg.Send( 'orgs.Menu.Bulletin', false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

-- MEMBERS

netmsg.Receive( 'orgs.Menu.Members.Kick', function( tab, ply )

  local err = orgs.updatePlayer( tab[1], {OrgID= NULL}, ply, function()
    netmsg.Send( 'orgs.Menu.Members.Kick', false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Members.Manage', function( tab, ply )
  local ply2 = tab.Player
  tab.Player = nil

  local err = orgs.updatePlayer( ply2, tab, ply, function()
    netmsg.Send( 'orgs.Menu.Members.Manage', false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Members.Invite', function( tab, ply )
  local err = orgs.addInvite( tab[1], ply, function( _, err )
    netmsg.Send( 'orgs.Menu.Members.Invite', err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

-- BANK

netmsg.Receive( 'orgs.Menu.Bank.Deposit', function( tab, ply )
  local orgID = ply:orgs_Org(0)
  if not orgID or not isnumber(tab.Val) then
    netmsg.Respond( true )
    return
  end
  local org, steamID = orgs.List[orgID], ply:SteamID64()

  tab.Val = math.Clamp( math.floor( tab.Val ), 0, math.huge )
  orgs.AddMoney( ply, -tab.Val ) -- Can't risk players leaving
  local err = orgs.updateOrg( orgID, {Balance= org.Balance +tab.Val}, nil,
  function( _, err )
    if err then
      orgs.AddMoney( ply, tab.Val )
      netmsg.Send( 'orgs.Menu.Bank.Deposit', true, ply )
    return end
    orgs.LogEvent( orgs.EVENT_BANK_DEPOSIT, {ActionBy= steamID,
      ActionValue= tab.Val, OrgID= orgID} )
    netmsg.Send( 'orgs.Menu.Bank.Deposit', false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Bank.Withdraw', function( tab, ply )
  local orgID = ply:orgs_Org(0)
  if not ply:orgs_Org(0) or not isnumber( tab.Val )
  or not ply:orgs_Has( orgs.PERM_WITHDRAW ) then
    netmsg.Respond( 18 )
    return
  end
  local org, steamID = orgs.List[orgID], ply:SteamID64()

  tab.Val = math.Clamp( math.floor( tab.Val ), 0, org.Balance )
  local err = orgs.updateOrg( ply:orgs_Org(0), {Balance= org.Balance -tab.Val}, nil,
  function( _, err )
    if err then netmsg.Send( 'orgs.Menu.Bank.Withdraw', true, ply ) return end

    orgs.LogEvent( orgs.EVENT_BANK_WITHDRAW, {ActionBy= IsValid(ply) and ply or steamID,
      ActionValue= tab.Val, OrgID= orgID} )

    orgs.AddMoney( ply, tab.Val )
    netmsg.Send( 'orgs.Menu.Bank.Withdraw', err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

-- MANAGE

netmsg.Receive( 'orgs.Menu.Manage.Edit', function( tab, ply )

  local err = orgs.updateOrg( ply:orgs_Org(0), tab, ply, function( _, err )
    netmsg.Send( 'orgs.Menu.Manage.Edit', err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Manage.EditRank', function( tab, ply )

  local rankID = tab.RankID
  tab.RankID = nil
  local err = orgs.updateRank( rankID, tab, ply, function( _, err )
    netmsg.Send( 'orgs.Menu.Manage.EditRank', err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Manage.RemoveRank', function( tab, ply )
  local err = orgs.removeRank( tab[1], ply, function( _, err )
    netmsg.Send( 'orgs.Menu.Manage.RemoveRank', err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Manage.AddRank', function( tab, ply )
  local err = orgs.addRank( ply:orgs_Org(0), tab, ply, function( _, err )
    netmsg.Send( 'orgs.Menu.Manage.AddRank', err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

-- netmsg.Receive( 'orgs.Menu.Manage_Upgrade', function( tab, ply )
--   if not orgs.Has( ply, orgs.PERM_MODIFY ) then
--     netmsg.Respond( )
--   local err = orgs.updateOrg( ply:orgs_Org(0), tab, )
--
-- end

-- JOIN

netmsg.Receive( 'orgs.JoinMenu_Join.Join', function( tab, ply )
  if ply.orgs_GroupLock then return end
  ply.orgs_GroupLock = true

  local err = orgs.updatePlayer( ply, {OrgID= tab[1]}, nil, function()
    ply.orgs_GroupLock = nil
  end )

  if err then netmsg.Respond( err ) end
end )
