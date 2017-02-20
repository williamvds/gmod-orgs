-- Handles all networking for the menus etc

orgs.ChatLog = function( plys, ... )
  netmsg.Send( 'orgs.ChatLog', {...}, plys )
end

hook.Add( 'PlayerSay', 'orgs.ChatCommand', function( ply, text )
  if GAMEMODE.ThisClass == 'gamemode_darkrp' or DarkRP then return end

  if string.lower( text ) == orgs.CommandPrefix..orgs.Command then
    if orgs._Provider.Failed then
      orgs.ChatLog( ply, orgs.Colors.Error, 'Organisations couldn\'t connect to the database - '
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
  orgs.updatePlayer( ply, {OrgID= NULL}, nil, function()
    if not IsValid( ply ) then return end
    netmsg.Call( ply, 'orgs.LeftOrg' )
  end )
end )

-- BULLETIN

netmsg.Receive( 'orgs.Menu.Bulletin', function( tab, ply, msg )
  local err = orgs.updateOrg( ply:orgs_Org(0), {Bulletin= tab[1]}, ply, function()
    netmsg.Send( msg, false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

-- MEMBERS

netmsg.Receive( 'orgs.Menu.Members.Kick', function( tab, ply, msg )

  local err = orgs.updatePlayer( tab[1], {OrgID= NULL}, ply, function()
    netmsg.Send( msg, false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Members.Manage', function( tab, ply, msg )
  local ply2 = tab.Player
  tab.Player = nil

  local err = orgs.updatePlayer( ply2, tab, ply, function( data, err )
    netmsg.Send( msg, err and true or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Members.Invite', function( tab, ply, msg )
  local err = orgs.addInvite( tab[1], ply, function( _, err )
    netmsg.Send( msg, err and true or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Members.RemoveInvite', function( tab, ply, msg )
  local err = orgs.removeInvite( tab[1], ply, function( _, err )
    netmsg.Send( msg, err and true or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

-- BANK

local bankHandler = function( tab, ply, msg )
  local orgID, org = ply:orgs_Org(0), ply:orgs_Org()
  if not orgID or not isnumber( tab.Val ) then
    netmsg.Respond( true )
  return end

  local err = orgs.updateOrg( orgID,
    {Balance= org.Balance +( msg:find('Deposit') and tab.Val or -tab.Val ) }, ply,
  function( _, err, msg )
    netmsg.Send( msg, err and true or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end

netmsg.Receive( 'orgs.Menu.Bank.Deposit', bankHandler )
netmsg.Receive( 'orgs.Menu.Bank.Withdraw', bankHandler )

-- MANAGE

netmsg.Receive( 'orgs.Menu.Manage.Edit', function( tab, ply, msg )

  local err = orgs.updateOrg( ply:orgs_Org(0), tab, ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Manage.EditRank', function( tab, ply, msg )

  local rankID = tab.RankID
  tab.RankID = nil
  local err = orgs.updateRank( rankID, tab, ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Manage.RemoveRank', function( tab, ply, msg )
  local err = orgs.removeRank( tab[1], ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

netmsg.Receive( 'orgs.Menu.Manage.AddRank', function( tab, ply, msg )
  local err = orgs.addRank( ply:orgs_Org(0), tab, ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end )

  if err then netmsg.Respond( err ) end
end )

-- JOIN

netmsg.Receive( 'orgs.JoinMenu_Join.Join', function( tab, ply )
  if ply.orgs_GroupLock then return end
  ply.orgs_GroupLock = true

  local err = orgs.updatePlayer( ply, {OrgID= tab[1]}, nil, function()
    ply.orgs_GroupLock = nil
  end )

  if err then netmsg.Respond( err ) end
end )
