local PANEL = {}

function PANEL:Init()
  self:SetTitle( 'Organisations', 'orgs.Large' )
  self:SetSize( 600, 400 )
  self:Dock( nil, nil, {l=5,r=5,d=5} )
  self:SetKeyboardInputEnabled( true )
  self:SetFocusTopLevel( true )

  self.SubText = self:AddLabel( 'You don\'t currently belong to any group: you can join or create one',
  'orgs.Small', C_WHITE, true )
  self.SubText:Dock( TOP, {l=15, r=15, d=5} )
  self.SubText:SetAutoStretchVertical( true )

  self.Divider = self:Add( 'DPanel' )
  self.Divider:BGR( C_BLUE )
  self.Divider:SetTall( 4 )
  self.Divider:Dock( TOP )

  self.Body = self:Add( 'DPanel' )
  self.Body:BGR( C_DARKGRAY )
  self.Body:MoveToBack()
  self.Body:SetTall( 300 )
  self.Body:Dock( FILL )

  self.TabMenu = self.Body:Add( 'orgs.TabMenu' )
  self.TabMenu:Dock( FILL, {u=0} )

  self.Join = self.TabMenu:AddTab( 'JOIN', vgui.Create( 'orgs.JoinMenu_Join' ) )
  self.Create = self.TabMenu:AddTab( 'CREATE', vgui.Create( 'orgs.JoinMenu_Create' ) )

  self.Msg = self:AddLabel( '', 'orgs.Small', C_WHITE )
  self.Msg:Hide()
  self.Msg:SetContentAlignment( 5 )
  self.Msg:MoveToBack()
  self.Msg:Dock( BOTTOM, {u=2} )

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
      self.Msg:SetText( text )
      self.Msg:SetTextColor( col or C_WHITE )
      self.Msg:AlphaTo( 255, .2, 0 )
    end )

  else
    self.Msg:SetTextColor( col or C_WHITE )
    self.Msg:SetText( text )
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
  self:SetMsg( text, C_RED, time )
end

function PANEL:Think()
  if input.IsKeyDown( KEY_ESCAPE ) then self:AnimateHide() end
end
--
-- function PANEL:OnKeyCodePressed( key )
--   if key == KEY_ESCAPE then self:AnimateHide() end
-- end

function PANEL:Update()

  for k, tab in pairs( self.TabMenu.Tabs ) do
    if tab.Panel.Update then tab.Panel:Update() end
  end

end

function PANEL:Paint( w, h ) DrawRect( 0, 0, w, h, C_DARKGRAY ) end

vgui.Register( 'orgs.JoinMenu', PANEL, 'orgs.Frame' )

concommand.Add( 'orgs_newjoinmenu', function()
  orgs.JoinMenu = vgui.Create( 'orgs.JoinMenu' )
end )
