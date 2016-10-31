local rgb = Color -- TODO: Change back to Color
C_DARKGRAY   = rgb( 34, 34, 34 )
C_GRAY       = rgb( 51, 51, 51 )
C_LIGHTGRAY  = rgb( 127, 140, 141 )
C_DARKBLUE   = rgb( 54, 120, 172 )
C_BLUE       = rgb( 74, 140, 192 )
C_LIGHTGREEN = rgb( 41, 235, 82 )
C_GREEN      = rgb(0, 203, 0)
C_DARKGREEN  = rgb( 0, 40, 0 )
C_RED        = rgb( 228, 42, 46 )
C_DARKRED    = rgb( 207, 28, 27 )
C_WHITE      = rgb( 238, 238, 238 )
C_NONE       = rgb( 0, 0, 0, 0 )

surface.CreateFont( 'orgs.Menu', {
  font      = 'Roboto-Medium',
  size      = 14,
  weight    = 500,
  antialias = true,
  additive  = true,
} )

surface.CreateFont( 'orgs.Tiny', {
  font      = 'Roboto-Light',
  size      = 15,
  weight    = 400,
  antialias = true,
} )

surface.CreateFont( 'orgs.SmallLight', {
  font      = 'Roboto-Light',
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
  font      = 'Roboto-Medium',
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
  font      = 'Roboto-Medium',
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
  'that group does not exist',
  'that group is full',
  'that group is invitation only',
  'the desired rank does not exist',
  'the desired rank is not a part of your group',
  'the desired rank is not a part of the desired group',
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
  'the group would go into debt',
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

function DrawText( txt, f, x, y, c, a )
  local a = a or TEXT_ALIGN_LEFT
  draw.DrawText( txt, f, x +1, y +1, Color( 0, 0, 0, c.a *( 250/255 ) ), a )
  draw.DrawText( txt, f, x +2, y +2, Color( 0, 0, 0, c.a *( 50/255 ) ), a )
  draw.DrawText( txt, f, x, y, c, a )

end

function DrawRect( x, y, w, h, col )
  surface.SetDrawColor( col )
  surface.DrawRect( x, y, w, h )
end

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
  local tab = {}
  for k, v in pairs( {...} ) do
    table.insert( tab, v )
    table.insert( tab, k %2 == 1 and orgs.HighlightCol or orgs.TextCol )
  end
  chat.AddText( orgs.PrimaryCol, 'ORGS: ', orgs.TextCol, unpack( tab ) )
end
netmsg.Receive( 'orgs.ChatLog', function( tab ) orgs.ChatLog( unpack( tab ) ) end )

-- hook.Add( 'PreDrawHalos', 'orgs.MemberHalos', function()
--   if not LocalPlayer():orgs_Org() then return end
--
--   for k, ply in pairs( safeTable(orgs.Members, true) ) do
--     ply = player.GetBySteamID64( ply.SteamID )
--     if not ply or ply == LocalPlayer() then continue end
--
--     halo.Add( {ply}, Color(unpack(string.Explode(',',LocalPlayer():orgs_Org().Color ))), 1, 1, 0, true, true )
--   end
--
-- end )
-- hook.Add( 'OnPlayerChat', 'orgs.ChatTag', function( ply, txt )
--   local org = ply:orgs_Org()
--   if not org then return end
--
--   -- table.insert( )
--
--   return true
-- end )

-- hook.Add( 'PreDrawHalos', 'orgs.MemberHalos', function()
--   if not LocalPlayer():orgs_Org() then return end
--
--   for k, ply in pairs( safeTable(orgs.Members, true) ) do
--     ply = player.GetBySteamID64( ply.SteamID )
--     if not ply or ply == LocalPlayer() then continue end
--
--     cam.Start3D()
--       render.SetStencilEnable( true )
--         render.SuppressEngineLighting(true)
--         cam.IgnoreZ( entry.IgnoreZ )
--
--           render.SetStencilWriteMask( 1 )
--           render.SetStencilTestMask( 1 )
--           render.SetStencilReferenceValue( 1 )
--
--           render.SetStencilCompareFunction( STENCIL_ALWAYS )
--           render.SetStencilPassOperation( STENCIL_REPLACE )
--           render.SetStencilFailOperation( STENCIL_KEEP )
--           render.SetStencilZFailOperation( STENCIL_KEEP )
--
--
--             for k, v in pairs( entry.Ents ) do
--
--               if ( !IsValid( v ) ) then continue end
--
--               RenderEnt = v
--
--               v:DrawModel()
--
--             end
--
--             RenderEnt = NULL
--
--           render.SetStencilCompareFunction( STENCIL_EQUAL )
--           render.SetStencilPassOperation( STENCIL_KEEP )
--           -- render.SetStencilFailOperation( STENCIL_KEEP )
--           -- render.SetStencilZFailOperation( STENCIL_KEEP )
--
--             cam.Start2D()
--               surface.SetDrawColor( entry.Color )
--               surface.DrawRect( 0, 0, ScrW(), ScrH() )
--             cam.End2D()
--
--             render.SetStencilTestMask( 0 )
--             render.SetStencilWriteMask( 0 )
--             render.SetStencilReferenceValue( 0 )
--
--
--         cam.IgnoreZ( false )
--         render.SuppressEngineLighting(false)
--       render.SetStencilEnable( false )
--     cam.End3D()
--
--   end
--
-- end )
