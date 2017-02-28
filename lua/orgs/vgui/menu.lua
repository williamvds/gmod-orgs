local menuSize = {720,500}
local bodyHeight = menuSize[2] -100
local statsWidth = 245
local mottoWidth = menuSize[1] -statsWidth -15

local PANEL = {}

function PANEL:Init()
  self:orgs_Frame()
  self:SetSize( unpack(menuSize) )
  self.Org = LocalPlayer():orgs_Org()
  self:DockPadding( 0, 0, 0, 5 )

  -- Header
  self.Header:SetTall( 35 )
  self.Header:DockMargin( 5, 0, 0, 0 )

  self.ColorCube = self.Header:Add( 'DPanel' )
  self.ColorCube.Color = orgs.Colors.MenuText
  self.ColorCube.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, Color( 255, 255, 255 ) )
    orgs.DrawRect( 1, 1, w -2, h -2, p.Color )
  end
  self.ColorCube:SetSize( 20, 20 )
  self.ColorCube:SetPos( 0, 5 )

  self.Name = self.lblTitle
  self.Name:orgs_Dock( LEFT, {l=25} )
  self.Name:SetContentAlignment( 7 )
  self.Name:orgs_SetText( '', 'orgs.Large' )

  self.Tag = self.Header:orgs_AddLabel( '', 'orgs.Large' )
  self.Tag:orgs_Dock( LEFT, {l=10}, _, true )
  self.Tag:SetContentAlignment( 7 )
  self.Tag:SetTextInset( 0, 2 )
  self.Tag:Debug()

  -- Body
  self.Motto = self:orgs_AddLabel( '', 'orgs.Small' )
  self.Motto:SetWide( mottoWidth )
  self.Motto:orgs_Dock( LEFT, {l=5, u=10} )
  self.Motto:SetContentAlignment( 1 )
  self.Motto:SetAutoStretchVertical( true )
  self.Motto:SetWrap( true )

  self.Divider = self:Add( 'DPanel' )
  self.Divider:SetTall( 4 )
  self.Divider:MoveToBack()
  self.Divider:orgs_Dock( BOTTOM, {l=5, r=5} )
  self.Divider:orgs_BGR( orgs.Colors.MenuPrimaryAlt )

  self.Body = self:Add( 'DPanel' )
  self.Body:MoveToBack()
  self.Body:SetTall( bodyHeight )
  self.Body:Dock( BOTTOM )
  self.Body:orgs_BGR( orgs.Colors.MenuBackground )

  self.TabMenu = self.Body:Add( 'orgs.TabMenu' )
  self.TabMenu:DockMargin( 5, 0, 5, 0 )

  self.Bulletin = self.TabMenu:AddTab( 'BULLETIN', vgui.Create( 'orgs.Menu.Bulletin' ) )
  self.Members = self.TabMenu:AddTab( 'MEMBERS', vgui.Create( 'orgs.Menu.Members' ) )
  self.Bank = self.TabMenu:AddTab( 'BANK', vgui.Create( 'orgs.Menu.Bank' ) )
  self.Manage = self.TabMenu:AddTab( 'MANAGE', vgui.Create( 'orgs.Menu.Manage' ),
    nil, nil, 'manage' )
  self.TabMenu:AddTab( 'SETTINGS', vgui.Create( 'orgs.Menu.Settings' ) )

  self.Msg = self:orgs_AddLabel( '', 'orgs.Small' )
  self.Msg:Hide()
  self.Msg:SetContentAlignment( 5 )
  self.Msg:MoveToBack()
  self.Msg:orgs_Dock( BOTTOM, {u=2} )

  self:BuildStats()
  self:Update()
  self:AnimateShow()

end

function PANEL:BuildStats()

  if not self.Stats then

    self.Stats = self:Add( 'DPanel' )
    self.Stats:SetSize( statsWidth )
    self.Stats:orgs_Dock( RIGHT, {r=5}, {l=5} )
    self.Stats:orgs_BGR( orgs.UsePrimaryInStats and orgs.Colors.MenuPrimary
      or orgs.Colors.MenuSecondary )

    self.StatTab = {
      { label = 'RANK', func = function() return self.Org.Rank end },
      { label = 'BALANCE', func = function()
        return orgs.FormatCurrencyShort( self.Org.Balance )
      end },
      { label = 'MEMBERS', func = function() return self.Org.Members end },
    }

    for k, stat in pairs( self.StatTab ) do

      local pnl = self.Stats:Add( 'DPanel' )
      pnl:orgs_BGR( orgs.COLOR_NONE )
      pnl:orgs_Dock( LEFT, {r=5} )
      pnl:SetWide( (statsWidth/#self.StatTab) -5 -(3/#self.StatTab) )

      pnl.Label = pnl:orgs_AddLabel( stat.label, 'orgs.Small' )
      pnl.Label:orgs_Dock( TOP, {u=9} )
      pnl.Label:SetContentAlignment( 5 )

      pnl.Value = pnl:orgs_AddLabel( '', 'orgs.Medium' )
      pnl.Value:Dock( TOP )
      pnl.Value:SetContentAlignment( 5 )
      self.Stats[ stat.label ] = pnl

    end

  else
    for k, stat in pairs( self.StatTab ) do
      self.Stats[ stat.label ].Value:orgs_SetText( stat.func() )
    end
  end

end

function PANEL:Update()

  self.Org = LocalPlayer():orgs_Org()
  if not self.Org then return end
  self.Org = netmsg.safeTable( self.Org )

  self.Name:orgs_SetText( self.Org.Name, _, _, true )
  self.ColorCube.Color = istable( self.Org.Color ) and self.Org.Color
    or Color( unpack( string.Explode( ',', self.Org.Color ) ) )
  self.Tag:orgs_SetText( self.Org.Tag and '['..self.Org.Tag..']' or '', nil, nil, true )
  self.Motto:SetText( self.Org.Motto or '' )
  self:BuildStats()

  if not LocalPlayer():orgs_Has( orgs.PERM_MODIFY )
  and not LocalPlayer():orgs_Has( orgs.PERM_EVENTS )
  and not LocalPlayer():orgs_Has( orgs.PERM_RANK )
  and self.TabMenu.Tabs['manage'].Tab:IsVisible() then
    self.TabMenu:HideTab( 'manage' )
  elseif LocalPlayer():orgs_Has( orgs.PERM_MODIFY )
  or LocalPlayer():orgs_Has( orgs.PERM_EVENTS )
  or LocalPlayer():orgs_Has( orgs.PERM_RANK )
  and not self.TabMenu.Tabs['manage'].Tab:IsVisible() then
    self.TabMenu:ShowTab( 'manage' )
  end

  for k, tab in pairs( self.TabMenu.Tabs ) do
    if tab.Panel.Update then tab.Panel:Update( self.Org ) end
  end

end

function PANEL:SetMsg( text, col, time )
  time = time or 4

  if text == '' then
    self.Msg:AlphaTo( 0, .3, 0, function()
      self:SetTall( menuSize[2] )
      self.Msg:Hide()
    end )
    return
  end

  self:SetTall( menuSize[2] +self.Msg:GetTall() +2 )

  if self.Msg:IsVisible() then
    self.Msg:AlphaTo( 0, .2, 0, function()
      self.Msg:orgs_SetText( text, nil, col or orgs.Colors.MenuText )
      self.Msg:AlphaTo( 255, .2, 0 )
    end )

  else
    self.Msg:SetTextColor( col or orgs.Colors.MenuText )
    self.Msg:SetText( text )
    self.Msg:SetAlpha( 0 )
    self.Msg:Show()
    self.Msg:AlphaTo( 255, .3, 0 )

  end

  if timer.Exists( 'orgs.Menu.HideMsg' ) then
    timer.Adjust( 'orgs.Menu.HideMsg', time, 0 )
    timer.Start( 'orgs.Menu.HideMsg' )

  else
    timer.Create( 'orgs.Menu.HideMsg', time, 0, function()
      if IsValid( orgs.Menu ) then orgs.Menu:SetMsg( '' ) end
      timer.Stop( 'orgs.Menu.HideMsg' )
    end )

  end

end

function PANEL:SetError( text, time )
  self:SetMsg( text, orgs.Colors.Error, time )
end

vgui.Register( 'orgs.Menu', PANEL, 'DFrame' )

concommand.Add( 'orgs_newmenu', function()
  orgs.Menu = vgui.Create( 'orgs.Menu' )
end )
