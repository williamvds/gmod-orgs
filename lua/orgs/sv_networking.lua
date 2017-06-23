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

local function query( method, ply, msg, args )
  local err = orgs[method]( unpack( args ) )

  if not err then return end

  orgs.DebugLog( 'Request from ', ply, ' failed: ', '%s (%s)' %{msg,method}, ' Error code ', err )
  netmsg.Respond( err )
  return err
end

netmsg.Receive( 'orgs.JoinMenu.Create', function( tab, ply, msg )
  if ply.orgs_GroupLock then return end
  ply.orgs_GroupLock = true

  local err = query( 'addOrg', ply, msg, {tab, ply, function()
    ply.orgs_GroupLock = nil
  end} )

  if err then ply.orgs_GroupLock = nil end
end )

netmsg.Receive( 'orgs.LeaveOrg', function( _, ply, msg )
  query( 'updatePlayer', ply, msg, {ply, {OrgID= NULL}, nil, function()
    if not IsValid( ply ) then return end
    netmsg.Call( ply, 'orgs.LeftOrg' )
  end} )

end )

-- BULLETIN

netmsg.Receive( 'orgs.Menu.Bulletin', function( tab, ply, msg )
  query( 'updateOrg', ply, msg, {ply:orgs_Org(0), {Bulletin= tab[1]}, ply, function()
    netmsg.Send( msg, false, ply )
  end} )

end )

-- MEMBERS

netmsg.Receive( 'orgs.Menu.Members.Kick', function( tab, ply, msg )
  query( 'updatePlayer', ply, msg, {tab[1], {OrgID= NULL}, ply, function()
    netmsg.Send( msg, false, ply )
  end} )

end )

netmsg.Receive( 'orgs.Menu.Members.Manage', function( tab, ply, msg )
  local ply2 = tab.Player
  tab.Player = nil

  query( 'updatePlayer', ply, msg, {ply2, tab, ply, function( data, err )
    netmsg.Send( msg, err and true or false, ply )
  end} )

end )

netmsg.Receive( 'orgs.Menu.Members.Invite', function( tab, ply, msg )
  query( 'addInvite', ply, msg, {tab[1], ply, function( _, err )
    netmsg.Send( msg, err and true or false, ply )
  end} )

end )

netmsg.Receive( 'orgs.Menu.Members.RemoveInvite', function( tab, ply, msg )
  query( 'removeInvite', ply, msg, {tab[1], ply, function( _, err )
    netmsg.Send( msg, err and true or false, ply )
  end} )

  logRespond( ply, msg ..' (removeInvite)', err )
end )

-- BANK

local bankHandler = function( tab, ply, msg )
  local orgID, org = ply:orgs_Org(0), ply:orgs_Org()
  if not orgID or not isnumber( tab.Val ) then
    netmsg.Respond( true )
  return end

  query( 'updateOrg', ply, msg, {orgID,
    {Balance= org.Balance +( msg:find('Deposit') and tab.Val or -tab.Val ) }, ply,
  function( _, err )
    netmsg.Send( msg, err and true or false, ply )
  end} )

end

netmsg.Receive( 'orgs.Menu.Bank.Deposit', bankHandler )
netmsg.Receive( 'orgs.Menu.Bank.Withdraw', bankHandler )

-- MANAGE

netmsg.Receive( 'orgs.Menu.Manage.Edit', function( tab, ply, msg )

  query( 'updateOrg', ply, msg, {ply:orgs_Org(0), tab, ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end} )

end )

netmsg.Receive( 'orgs.Menu.Manage.EditRank', function( tab, ply, msg )

  local rankID = tab.RankID
  tab.RankID = nil
  query( 'updateRank', ply, msg, {rankID, tab, ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end} )

end )

netmsg.Receive( 'orgs.Menu.Manage.RemoveRank', function( tab, ply, msg )
  query( 'removeRank', ply, msg, {tab[1], ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end} )

end )

netmsg.Receive( 'orgs.Menu.Manage.AddRank', function( tab, ply, msg )
  query( 'addRank', ply, msg, {ply:orgs_Org(0), tab, ply, function( _, err )
    netmsg.Send( msg, err or false, ply )
  end} )

end )

-- JOIN

netmsg.Receive( 'orgs.JoinMenu_Join.Join', function( tab, ply, msg )
  if ply.orgs_GroupLock then return end
  ply.orgs_GroupLock = true

  local err = query( 'updatePlayer', ply, msg, {ply, {OrgID= tab[1]}, nil, function()
    ply.orgs_GroupLock = nil
  end} )

  if err then ply.orgs_GroupLock = nil end
end )
