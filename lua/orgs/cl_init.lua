orgs.COLOR_NONE = Color( 0, 0, 0, 0 )

surface.CreateFont( 'orgs.Menu', {
  font      = 'Roboto',
  size      = 14,
  weight    = 500,
  antialias = true,
  additive  = true,
} )

surface.CreateFont( 'orgs.Tiny', {
  font      = 'Roboto',
  size      = 16,
  weight    = 400,
  antialias = true,
} )

surface.CreateFont( 'orgs.SmallLight', {
  font      = 'Roboto',
  size      = 18,
  weight    = 400,
  antialias = true,
} )

surface.CreateFont( 'orgs.Small', {
  font      = 'Roboto',
  size      = 17,
  weight    = 500,
  antialias = true,
} )

surface.CreateFont( 'orgs.Medium', {
  font      = 'Roboto',
  size      = 22,
  weight    = 500,
  antialias = true,
} )

surface.CreateFont( 'orgs.MediumLight', {
  font      = 'Roboto',
  size      = 20,
  weight    = 400,
  antialias = true,
} )

surface.CreateFont( 'orgs.Large', {
  font      = 'Roboto',
  size      = 28,
  weight    = 500,
  antialias = true,
  additive  = true,
} )

orgs.ManageFails = { -- Managing other players (including self when joining)
  'you haven\'t changed anything',
  'target is not a member of your group',
  'you don\'t have permission to change that information',
  'you don\'t have permission to manage other members',
  'you don\'t have permission to kick other members',
  'you have insufficient immunity to manage that member',
  'you have insufficient immunity to give that rank',
  'you don\'t have the permissions you are trying to bestow',
  'you must leave your group before joining another',
  'that group does not exist',
  'that group is full',
  'you need an invitation to join that group',
  'the desired rank does not exist',
  'the desired rank is not a part of your group',
  'the desired rank is not a part of the desired group',
}

orgs.InviteFails = { -- Inviting players
  'an invalid Steam ID was given',
  'you can\'t invite yourself',
  'you can\'t invite players',
  'that player has already been invited to this group',
}
orgs.RemoveInviteFails = { -- Inviting players
  'that invite does not exist',
  'you are not allowed to withdraw that invite',
}

orgs.EditRankFails = { -- Altering ranks
  'you haven\'t changed anything',
  'that rank doesn\'t exist',
  'that rank isn\'t a part of your group',
  'you don\'t have permission to edit ranks',
  'the target rank has greater immunity than yours',
  'you can\'t give a rank greater immunity than you',
  'you don\'t have the permissions you are trying to bestow',
}
orgs.RemoveRankFails = { -- Removing ranks
  'that rank does not exist',
  'you don\'t have permission to remove that rank',
  'you have insufficient immunity to remove that rank',
  'that rank is the default rank for the group',
}

orgs.ModifyFails = { -- Altering group information
  'you haven\'t changed anything',
  'you are not allowed to change that information',
  'you don\'t belong to a group',
  'you\'re not allowed to change the bulletin',
  'you\'re not allowed to modify the group',
  'the group cannot afford that',
  'the desired name is invalid',
  'the desired name is too long',
  'the desired tag is too long',
  'the desired motto is too long',
  'the desired bulletin is too long',
  'another group already has that name',
  'another group already has that tag',
  'the desired default rank is invalid',
  'that group type does not exist',
  'your group has too few members',
  'your group has too many members',
  'you\'re not allowed to withdraw money',
  'your group\'s account cannot contain that much money',
  'you would exceed your withdrawal limit',
}

orgs.PermCheckboxes = {
  {'Invite',   'Invite players'},
  {'Bulletin', 'Edit bulletin'},
  {'Withdraw', 'Withdraw from bank'},
  {'Promote',  'Promote members'},
  {'Kick',     'Kick members'},
  {'Ranks',    'Modify ranks'},
  {'Modify',   'Modify the group'},
  {'Events',   'View events'},
}

for _, f in pairs( file.Find( 'orgs/vgui/*.lua', 'LUA' ) ) do  include( 'orgs/vgui/'.. f ) end

netmsg.Receive( 'orgs.OpenMenu', function()
  if not LocalPlayer():orgs_Org() then
    if not IsValid( orgs.JoinMenu ) then
      orgs.JoinMenu = vgui.Create( 'orgs.JoinMenu' )
    else
      orgs.JoinMenu:Update()
      orgs.JoinMenu:AnimateShow()
    end
    return
  end

  if not IsValid( orgs.Menu ) then
    orgs.Menu = vgui.Create( 'orgs.Menu' )
  else orgs.Menu:Update() orgs.Menu:AnimateShow() end

end )

hook.Add( 'KeyPress', 'orgs.CloseMenus', function( ply, bind )
  if bind ~= 'cancelselect' then return end

  if orgs.JoinMenu and orgs.JoinMenu:IsValid() then orgs.JoinMenu:AnimateHide() end
  if orgs.Menu and orgs.Menu:IsValid() then orgs.Menu:AnimateHide() end

end )

orgs.ChatLog = function( ... )
  -- TODO: Get ChatLog to work with custom colors?
  local args, chatTab = {...}, {}
  for k, v in pairs( args ) do
    table.insert( chatTab, v )
    table.insert( chatTab, k %2 == 1 and orgs.Colors.Secondary or orgs.Colors.Text )
  end
  chat.AddText( orgs.Colors.Primary, 'ORGS: ', orgs.Colors.Text, unpack( chatTab ) )

  if IsValid( orgs.Menu ) then
    orgs.Menu:SetMsg( table.concat( args ) )
  elseif IsValid( orgs.JoinMenu ) then
    orgs.JoinMenu:SetMsg( table.concat( args ) )
  end
end
netmsg.Receive( 'orgs.ChatLog', function( tab ) orgs.ChatLog( unpack( tab ) ) end )

local lastChat, lastChatPly
hook.Add( 'OnPlayerChat', 'orgs.ChatIntercept', function( ply, txt )
  lastChat = txt
  lastChatPly = ply
end )

local oldChatText = oldChatText or chat.AddText
function chat.AddText( ... )
  local tab, ply = {...}, false

  if lastChat and lastChatPly and lastChatPly != NULL and tab[#tab] == ': '.. lastChat then
    ply = lastChatPly
    lastChat, lastChatPly = nil, nil
  end

  if not ply or not IsValid( ply ) or not ply:orgs_Org(0) then
    oldChatText( unpack( tab ) )
  return end

  local org = ply:orgs_Org()

  if org.Tag then
    table.insert( tab, #tab -3, '[%s] ' %{ org.Tag } )
    table.insert( tab, #tab -4, Color( unpack( string.Explode( ',', org.Color ) ) ) )
  end

  oldChatText( unpack( tab ) )

  return true
end

hook.Add( 'PreDrawHalos', 'orgs.MemberHalos', function()
  local org = LocalPlayer():orgs_Org()
  if not org then return end

  local plys = {}
  for k, v in pairs( netmsg.safeTable( orgs.Members, true ) ) do
    ply = player.GetBySteamID64( v.SteamID )
    if not ply or ply == LocalPlayer() then continue end

    table.insert( plys, ply )

  end

  halo.Add( plys, Color( unpack( string.Explode( ',', org.Color ) ) ), 1, 1, 5, true, false )

end )
