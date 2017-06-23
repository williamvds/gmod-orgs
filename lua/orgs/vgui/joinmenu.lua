local PANEL = {}

function PANEL:Init()
  self:orgs_Frame()

  self:SetTitle( 'Organisations', 'orgs.Large' )
  self:SetSize( 600, 400 )
  self:DockPadding( 0, 0, 0, 5 )
  self:SetKeyboardInputEnabled( true )
  self:SetFocusTopLevel( true )

  self.SubText = self:orgs_AddLabel( 'You don\'t currently belong to any group: you can join'
    ..' or create one',
    'orgs.Small', orgs.Colors.MenuText, true )
  self.SubText:orgs_Dock( TOP, {l=5,r=15, d=5} )
  self.SubText:SetAutoStretchVertical( true )

  self.Divider = self:Add( 'DPanel' )
  self.Divider:orgs_BGR( orgs.Colors.MenuPrimaryAlt )
  self.Divider:SetTall( 4 )
  self.Divider:orgs_Dock( TOP, {l=5,r=5} )

  self.Body = self:Add( 'DPanel' )
  self.Body:orgs_BGR( orgs.Colors.MenuBackground )
  self.Body:MoveToBack()
  self.Body:SetTall( 300 )
  self.Body:Dock( FILL )

  self.TabMenu = self.Body:Add( 'orgs.TabMenu' )
  self.TabMenu:orgs_Dock( FILL, {u=0,l=5,r=5} )
  self.Join = self.TabMenu:AddTab( 'JOIN', vgui.Create( 'orgs.JoinMenu_Join' ) )
  self.Create = self.TabMenu:AddTab( 'CREATE', vgui.Create( 'orgs.JoinMenu_Create' ) )

  self.Invites = self.TabMenu:AddTab( 'INVITES', vgui.Create( 'orgs.JoinMenu_Invites' ) )

  self.Msg = self:orgs_AddLabel( '', 'orgs.Small' )
  self.Msg:Hide()
  self.Msg:SetContentAlignment( 5 )
  self.Msg:MoveToBack()
  self.Msg:orgs_Dock( BOTTOM, {u=2} )

  self:Update()
  self:AnimateShow()
end

function PANEL:SetMsg( text, col, time )
  time = time or 4

  if text == '' then
    self.Msg:AlphaTo( 0, .3, 0, function()
      self:SetTall( 400 )
      self.Msg:Hide()
    end )
    return
  end

  self:SetTall( 400 +self.Msg:GetTall() +2 )

  if self.Msg:IsVisible() then
    self.Msg:AlphaTo( 0, .2, 0, function()
      self.Msg:orgs_SetText( text, nil, col or orgs.Colors.MenuText )
      self.Msg:AlphaTo( 255, .2, 0 )
    end )

  else
    self.Msg:SetTextColor( col or orgs.Colors.MenuText )
    self.Msg:orgs_SetText( text )
    self.Msg:SetAlpha( 0 )
    self.Msg:Show()
    self.Msg:AlphaTo( 255, .3, 0 )

  end

  if timer.Exists( 'orgs.JoinMenu.HideMsg' ) then
    timer.Adjust( 'orgs.JoinMenu.HideMsg', time, 0 )
    timer.Start( 'orgs.JoinMenu.HideMsg' )

  else
    timer.Create( 'orgs.JoinMenu.HideMsg', time, 0, function()
      if IsValid( orgs.JoinMenu ) then orgs.JoinMenu:SetMsg( '' ) end
      timer.Stop( 'orgs.JoinMenu.HideMsg' )
    end )

  end

end

function PANEL:SetError( text, time )
  self:SetMsg( text, orgs.Colors.Error, time )
end

function PANEL:Think()
  if input.IsKeyDown( KEY_ESCAPE ) then self:AnimateHide() end
end

function PANEL:Update()
  local invites = netmsg.safeTable( orgs.Invites, true )
  for k, v in pairs( invites ) do
    if v.To ~= LocalPlayer():SteamID64() then table.remove( invites, k ) end
  end

  local txt = 'INVITES'..
    ( table.Count( invites ) > 0 and ' (%s)'  %{table.Count( invites )} or '' )
  self.TabMenu.Tabs[3].Tab:orgs_SetText( txt )
  self.TabMenu.Tabs[3].Tab.Name = txt
  self.TabMenu:RepositionTabs()

  for k, tab in pairs( self.TabMenu.Tabs ) do
    if tab.Panel.Update then tab.Panel:Update() end
  end
end

function PANEL:Paint( w, h ) orgs.DrawRect( 0, 0, w, h, orgs.Colors.MenuBackground ) end

vgui.Register( 'orgs.JoinMenu', PANEL, 'DFrame' )

concommand.Add( 'orgs_newjoinmenu', function()
  orgs.JoinMenu = vgui.Create( 'orgs.JoinMenu' )
end )
