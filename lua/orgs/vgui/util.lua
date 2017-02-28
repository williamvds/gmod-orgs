function orgs.DrawRect( x, y, w, h, col )
  surface.SetDrawColor( col or orgs.Colors.Primary )
  surface.DrawRect( x, y, w, h )
end

local Panel = FindMetaTable( 'Panel' )

function Panel:orgs_SetText( txt, font, col, resize )

  if txt then self:SetText( txt ) end
  if font or not string.StartWith( self:GetFont(), 'orgs.' ) then
    self:SetFont( font or 'orgs.Medium' )
  end
  if resize then self:SizeToContents() end
  self:SetTextColor( col or ( self:GetName() == 'DButton' and orgs.Colors.MenuTextAlt )
    or orgs.Colors.MenuText )

end

function Panel:orgs_AddLabel( text, font, col, wrap, noresize )
  local l = self:Add( 'DLabel' )

  if wrap then
    l:SetWrap( true )
    l:SetAutoStretchVertical( true )
  end
  l:orgs_SetText( text, font, col or orgs.Colors.MenuText, not noresize )

  return l
end

function Panel:orgs_Dock( dir, m, p, resize )

  self:Dock( dir or NODOCK )
  if m then self:DockMargin( m.l or 0, m.u or 0, m.r or 0, m.d or 0 ) end
  if p then self:DockPadding( p.l or 0, p.u or 0, p.r or 0, p.d or 0 ) end
  if resize then self:SizeToContents() end

end

function Panel:Debug()

  self.oldPaint = self.Paint
  self.Paint = function( self, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.Colors.Close )
    if self.oldPaint then self:oldPaint( w, h ) end
  end

end

function Panel:orgs_BGR( col, hover, disabled )

  self.Paint = function( self, w, h )
    local col = ( disabled and self:GetDisabled() ) and depressed
      or ( hover and self:IsHovered() ) and hover or col
    orgs.DrawRect( 0, 0, w, h, col )
  end

end

local frameAdd = function( self, p )
  local new = FindMetaTable'Panel'.Add( self, p )
  if new.SetSkin then new:SetSkin( 'orgs' ) end
  new.Add = frameAdd

  return new
end

function Panel:orgs_Frame()
  AccessorFunc( self, 'b_remove_on_close', 'RemoveOnHide', FORCE_BOOL )
  self:SetRemoveOnHide( true )

  self.Add = frameAdd
  self:SetSkin( 'orgs' )
  self:SetSize( 150, 100 )
  self:SetPos( 0, -100 )
  self:SetScreenLock( true )
  self:DockPadding( 0, 0, 0, 0 )

  self.Header = self:Add( 'DPanel' )
  self.Header:orgs_BGR( orgs.COLOR_NONE )
  self.Header:Dock( TOP )
  self.Header:SetTall( 25 )
  self.Header.OnMousePressed = function() self:OnMousePressed() end
  self.Header.OnMouseReleased = function() self:OnMouseReleased() end


  self.lblTitle:SetParent( self.Header )
  self.lblTitle.OnMousePressed = function() self:OnMousePressed() end
  self.lblTitle.OnMouseReleased = function() self:OnMouseReleased() end
  self.lblTitle:orgs_SetText()
  self.lblTitle:SetTextInset( 0, 2 )
  self.lblTitle:orgs_Dock( TOP, {u=2} )
  self.lblTitle:SetContentAlignment( 5 )
  self.lblTitle.UpdateColors = function( p, skin )
    p:SetTextColor( orgs.Menu.MenuText )
  end

  self.btnClose:SetParent( self.Header )
  self.btnClose:orgs_SetText( '✕', 'orgs.SmallLight', orgs.Colors.CloseText )
  self.btnClose:SetSize( 25, 20 )
  self.btnClose.DoClick = function() self:AnimateHide() end

  self.PerformLayout = function( self )
  	self.btnClose:AlignRight()
  end

  self.btnMinim:Remove()
  self.btnMaxim:Remove()

  self.AnimateShow = function( self, done )

    self:Show()
    if not self.Hiding then
      self:SetPos( ScrW()/2 -self:GetWide()/2, -self:GetTall() )
    end
    self:MoveTo( ScrW()/2 -self:GetWide()/2, ScrH() /2 -self:GetTall() /2, .25, nil, nil,
      function()
        self:MakePopup()
        if done then done() end
      end )

  end

  self.AnimateHide = function( self, done )
    if self.Hiding then return end
    self.Hiding = true

    self:MoveTo( self.x, -self:GetTall(), .25, nil, nil,
      function( tab )
        self.Hiding = false
        self:Hide()
        if self:GetRemoveOnHide() then self:Remove() end
        if done then done() end
    end )

    CloseDermaMenus()
  end

  local oldThink = self.Think
  self.Think = function( self )
    if not self.NoEscape and input.IsKeyDown( KEY_ESCAPE ) then self:AnimateHide() end
    local oldY = self.y
    oldThink( self )

    if not self.Dragging then
      self:SetPos( self.x, oldY )
    end
  end

end

local function createSkin()
  local SKIN = table.Copy( derma.GetDefaultSkin() )
  SKIN.fontFrame = 'orgs.Medium'
  SKIN.fontTab = 'orgs.Medium'
  SKIN.fontCategoryHeader = 'orgs.Medium'

  SKIN.Colours.Label = {
    Default = orgs.Colors.MenuTextAlt,
    Bright = orgs.Colors.MenuTextAlt,
    Dark = orgs.Colors.MenuText,
    Highlight = orgs.Colors.MenuText -- Table headers
  }

  SKIN.Colours.Tab.Active = {
    Default = orgs.Colors.MenuTextAlt,
    Bright = orgs.Colors.MenuTextAlt,
    Dark = orgs.Colors.MenuText,
    Highlight = orgs.Colors.MenuText -- Table headers
  }
  SKIN.Colours.Tab.Inactive = {
    Default = orgs.Colors.MenuTextAlt,
    Bright = orgs.Colors.MenuTextAlt,
    Dark = orgs.Colors.MenuText,
    Highlight = orgs.Colors.MenuText
  }

  SKIN.Colours.Button = {
    Normal = orgs.Colors.MenuTextAlt,
    Bright = orgs.Colors.MenuTextAlt,
    Dark = orgs.Colors.MenuTextAlt,
    Hover = orgs.Colors.MenuTextAlt
  }

  function SKIN:PaintFrame( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.Colors.MenuBackground )
  end

  -- Panel
  function SKIN:PaintPanel( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.Colors.MenuBackgroundAlt )
  end

  function SKIN:PaintWindowCloseButton( p, w, h )
    orgs.DrawRect( 0, 0, w, h, p:IsHovered() and orgs.Colors.CloseAlt or orgs.Colors.Close )
  end

  SKIN.PaintWindowMaximizeButton = function() end
  SKIN.PaintWindowMinimizeButton = function() end

  -- Menu
  function SKIN:PaintMenu( p, w, h ) end

  function SKIN:LayoutMenu( p )
    for k, opt in pairs( p:GetCanvas():GetChildren() ) do
      if opt.ThisClass ~= 'DMenuOption' then continue end
      opt:orgs_SetText( nil, 'orgs.Small', orgs.Colors.MenuBackground )
      opt:SetTextInset( 10, 0 )
    end
  end

  function SKIN:PaintMenuOption( p, w, h )
    if not p.m_bBackground then return end

    orgs.DrawRect( 0, 0, w, h, orgs.Colors.MenuText )

    if p:IsHovered() or p.Hovered or p.Highlight then
      orgs.DrawRect( 0, 0, 5, h, orgs.Colors.MenuPrimary )
    end
  end

  -- Button
  function SKIN:PaintButton( p, w, h )
  	if not p.m_bBackground then return end

    orgs.DrawRect( 0, 0, w, h, p:GetDisabled() and orgs.Colors.MenuSecondary
      or p:IsHovered() and orgs.Colors.MenuButtonAlt
      or orgs.Colors.MenuButton )
  end

  -- Checkbox
  function SKIN:PaintCheckBox( p, w, h )
    orgs.DrawRect( 0, 0, w, h, p:GetDisabled() and orgs.Colors.MenuSecondary
      or orgs.Colors.MenuPrimaryAlt )

    orgs.DrawRect( 3, 3, w -6, h -6, p:GetChecked() and orgs.Colors.MenuIndicatorOn
      or orgs.Colors.MenuIndicatorOff )
  end

  -- TextEntry
  function SKIN:SchemeTextEntry( p )
    if not string.StartWith( p:GetFont(), 'orgs.' ) then p:SetFontInternal( 'orgs.Medium' ) end
  end

  function SKIN:PaintTextEntry( p, w, h )

    orgs.DrawRect( 0, 0, w, h, ( p:IsEnabled() and p:HasFocus() ) and orgs.Colors.MenuSecondary
      or orgs.Colors.MenuBackgroundAlt )

    if not p:GetDisabled() then
      surface.SetDrawColor( orgs.Colors.MenuSecondary )
      p:DrawOutlinedRect()
    end

    p:DrawTextEntryText( orgs.Colors.MenuText, orgs.Colors.MenuTextAlt, orgs.Colors.MenuText )
  end

  -- Scrollbar
  -- TODO: Figure out colors and hover, make VBar thinner
  function SKIN:PaintVScrollBar( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.COLOR_NONE )
  end

  function SKIN:PaintScrollBarGrip( p, w, h )
    orgs.DrawRect( 0, 0, w, h, p:IsHovered() and orgs.Colors.MenuPrimaryAlt
      or orgs.Colors.MenuPrimary )
  end

  function SKIN:PaintButtonDown( p, w, h )
    self.tex.Input.UpDown.Down.Hover( 0, 0, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.COLOR_NONE )
  end

  function SKIN:PaintButtonUp( p, w, h )
    self.tex.Input.UpDown.Up.Hover( 0, 0, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.COLOR_NONE )
  end

  -- ComboBox
  SKIN.PaintComboBox = SKIN.PaintTextEntry

  -- ListView
  function SKIN:PaintListViewLine( p, w, h )
    orgs.DrawRect( 0, 0, w, h, p:IsSelected() and orgs.Colors.MenuActive
      or p:IsHovered() and orgs.Colors.MenuBackground
      or orgs.Colors.MenuBackgroundAlt )
  end

  function SKIN:SchemeListViewLine( p )
    for k, v in pairs( p.Columns ) do
      v:SetFont( string.StartWith( v:GetFont() or '', 'orgs.' )
        and v:GetFont() or 'orgs.SmallLight' )
      v:SetContentAlignment( 5 )
    end
  end

  function SKIN:PaintListView( panel, w, h )
  	if not panel.m_bBackground then return end

    orgs.DrawRect( 0, 0, w, h, orgs.Colors.MenuBackgroundAlt )
  end

  function SKIN:PaintListViewHeaderLabel( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.UsePrimaryInTables and orgs.Colors.MenuPrimary
    or orgs.Colors.MenuSecondary )
  end

  function SKIN:SchemeListViewColumn( p )
    Derma_Hook( p.Header, 'Paint', 'Paint', 'ListViewHeaderLabel' )
    p.Header:SetFont( 'orgs.Medium' )
    p.Header:SetTextColor( orgs.UsePrimaryInTables and orgs.Colors.MenuTextAlt
      or orgs.Colors.MenuText )
  end

  created = true

  derma.DefineSkin( 'orgs', '', SKIN )
end
hook.Add( 'Initialize', 'orgs.createSkin', createSkin )

if derma.GetNamedSkin( 'orgs' ) then createSkin() end
