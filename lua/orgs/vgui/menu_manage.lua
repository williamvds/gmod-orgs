local PANEL = {}

function PANEL:Init()
  self:orgs_Dock( FILL, {u=5,d=5} )

  self.Selector = self:Add( 'DColumnSheet' )
  self.Selector:orgs_BGR( orgs.C_NONE )
  self.Selector:orgs_Dock( FILL, {r=5} )
  self.Selector.Navigation:orgs_Dock( LEFT, {l=5,r=5} )

  self.Modify = self:Add( 'orgs.Menu.Manage_Modify' )
  self.Selector:AddSheet( 'Edit group', self.Modify )

  self.Ranks = self:Add( 'orgs.Menu.Manage_Ranks' )
  self.Selector:AddSheet( 'Edit ranks', self.Ranks )

  self.Events = self:Add( 'orgs.Events' )
  self.Selector:AddSheet( 'Events', self.Events )

  self.Invites = self:Add( 'orgs.Menu.Manage_Invites' )
  self.Selector:AddSheet( 'Invites', self.Invites )

  self.Selector.Content.PerformLayout = function( p )
    for k, b in pairs( self.Selector.Navigation.pnlCanvas:GetChildren() ) do
      b:orgs_SetText( nil, nil, orgs.C_WHITE )
    end
    if IsValid( self.Selector.ActiveButton ) then
      self.Selector.ActiveButton:orgs_SetText( nil, nil, orgs.C_DARKGRAY )
    end
  end

  for k, b in pairs( self.Selector.Navigation.pnlCanvas:GetChildren() ) do
    b.Paint = function()
      orgs.DrawRect( 0, 0, b:GetWide(), b:GetTall(),
        b.m_bSelected and orgs.C_WHITE or b.Hovered and orgs.C_BLUE or orgs.C_DARKBLUE )
    end
    b:orgs_Dock( TOP, {d=10} )
    b:orgs_SetText( nil, 'orgs.Medium', orgs.C_WHITE, true )
    b:SetTall( 30 )
  end

end

function PANEL:Update( org )
  local visible, panels = {}, {
    [self.Modify]= 'MODIFY',
    [self.Events]= 'EVENTS',
    [self.Ranks]= 'RANKS',
    [self.Invites]= 'KICK',
  }

  for k, v in SortedPairs( self.Selector.Items, true ) do
    local bool = LocalPlayer():orgs_Has( orgs['PERM_'..panels[v.Panel]] )
    v.Button:SetVisible( bool )
    if v.Panel == self.Invites then
      local num = table.Count( netmsg.safeTable( orgs.Invites, true ) )
      v.Button:SetText( num < 1 and 'Invites' or 'Invites (%s)' %{num} )
    end
    if bool then visible[k] = v.Button end
  end

  if not table.HasValue( visible, self.Selector.ActiveButton ) and table.Count( visible ) > 0 then
    self.Selector:SetActiveButton( select( 2, next( visible ) ) )
  end

  self.Modify:Update( org )
  self.Events:Update( org )
  self.Ranks:Update( org )
  self.Invites:Update( org )
end

vgui.Register( 'orgs.Menu.Manage', PANEL, 'EditablePanel' )

local PANEL = {}

function PANEL:Init()
  self:Dock( FILL )

  self.Desc = self:orgs_AddLabel( 'Control your group\'s appearance and information',
    'orgs.Small', orgs.C_WHITE )
  self.Desc:Dock( TOP )
  self.Desc:SetContentAlignment(5)

  local l = self:NewLine()
  self.NameLabel = l:orgs_AddLabel( 'Name', 'orgs.Medium', orgs.C_WHITE )
  self.NameLabel:Dock( LEFT )
  self.NameLabel:SetWide( 50 )
  self.NameLabel:SetContentAlignment( 6 )

  self.Name = l:Add( 'DTextEntry' )
  self.Name:orgs_Dock( LEFT, {l=15} )
  self.Name:SetSize( 250, 25 )
  self.Name:SetFont( 'orgs.Medium' )
  self.Name.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.Name.AllowInput = function( p )
    return p:GetText():len() +1 > orgs.MaxNameLength
  end

  l = self:NewLine()

  self.ColorLabel = l:orgs_AddLabel( 'Color', 'orgs.Medium', orgs.C_WHITE )
  self.ColorLabel:Dock( LEFT )
  self.ColorLabel:SetWide( 50 )
  self.ColorLabel:SetContentAlignment( 6 )

  self.ColorCube = l:Add( 'DButton' )
  self.ColorCube:SetText( '' )
  self.ColorCube.Color = orgs.C_WHITE
  self.ColorCube.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    orgs.DrawRect( 1, 1, w -2, h -2, p.Color )
  end
  self.ColorCube:SetSize( 20, 20 )
  self.ColorCube:orgs_Dock( LEFT, {l=15,u=2,d=2} )
  self.ColorCube:SetMouseInputEnabled( true )
  self.ColorCube.DoClick = function()
    local pop = orgs.Popup( 'Select group color', 'The group color is used for chat tags and '..
    'member highlighting' )

    pop:SetSize( 300, 300 )
    pop:DoModal( true )
    pop:AnimateShow( function() pop:SetDrawOnTop( false ) end )

    pop.Label:orgs_Dock( TOP, {d=5} )
    pop.Label:SetWrap( true )
    pop.Label:SetAutoStretchVertical( true )
    pop.Label:orgs_SetText( nil, 'orgs.Small', nil )

    pop.Color = pop.Body:Add( 'DColorMixer' )
    pop.Color:orgs_Dock( FILL, {d=5} )
    pop.Color:SetAlphaBar( false )
    pop.Color:SetPalette( false )
    pop.Color:SetColor( orgs.Menu.Manage.Modify.ColorCube.Color )
    pop.Color.ValueChanged = function( pop, col )
      orgs.Menu.Manage.Modify.ColorCube.Color = col
    end

    pop.Select = pop.Body:Add( 'DButton' )
    pop.Select:orgs_SetText( 'Select', 'orgs.Medium', orgs.C_WHITE )
    pop.Select:orgs_Dock( BOTTOM, {l=105,r=105} )
    pop.Select:SetTall( 30 )
    pop.Select:orgs_BGR( orgs.C_DARKBLUE, orgs.C_BLUE )
    pop.Select.DoClick= function( p )
      orgs.Menu.Manage.Modify.ColorCube.Color = pop.Color:GetColor()
      pop:AnimateHide()
    end
  end

  self.TagLabel = l:orgs_AddLabel( 'Tag', 'orgs.Medium', orgs.C_WHITE )
  self.TagLabel:orgs_Dock( LEFT, {l=25} )
  self.TagLabel:SetContentAlignment( 6 )

  self.Tag = l:Add( 'DTextEntry' )
  self.Tag:orgs_Dock( LEFT, {l=15} )
  self.Tag:SetSize( 75, 25 )
  self.Tag:SetFont( 'orgs.Medium' )
  self.Tag.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.Tag.AllowInput = function( p )
    return p:GetText():len() +1 > orgs.MaxTagLength
  end

  l = self:NewLine()

  self.MottoLabel = l:orgs_AddLabel( 'Motto', 'orgs.Medium', orgs.C_WHITE )
  self.MottoLabel:Dock( LEFT )
  self.MottoLabel:SetWide( 50 )
  self.MottoLabel:SetContentAlignment( 6 )

  self.Motto = l:Add( 'DTextEntry' )
  self.Motto:orgs_Dock( LEFT, {l=15} )
  self.Motto:SetSize( 350, 25 )
  self.Motto:SetFont( 'orgs.Medium' )
  self.Motto.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.Motto.AllowInput = function( p )
    return p:GetText():len() +1 > orgs.MaxMottoLength
  end

  l = self:NewLine()

  self.PublicLabel = l:orgs_AddLabel( 'Public ', 'orgs.Medium', orgs.C_WHITE )
  self.PublicLabel:SetTall( 22 )
  self.PublicLabel:orgs_Dock( LEFT, {r=10} )
  self.PublicLabel:SetContentAlignment(6)
  self.PublicLabel:SetMouseInputEnabled( true )

  self.Public = l:Add( 'DCheckBox' )
  self.Public:Dock( LEFT )
  self.Public:SetSize( 22, 22 )
  self.Public.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, p:GetDisabled() and orgs.C_LIGHTGRAY or orgs.C_BLUE )
    orgs.DrawRect( 3, 3, w -6, h -6, p:GetChecked() and orgs.C_LIGHTGREEN or orgs.C_DARKRED )
  end
  self.PublicLabel.DoClick = function() self.Public:Toggle() end

  self.Bottom = self:Add( 'DPanel' )
  self.Bottom.Paint = function() end
  self.Bottom:Dock( BOTTOM )
  self.Bottom:SetTall( 30 )

  self.Upgrade = self.Bottom:Add( 'DButton' )
  self.Upgrade:orgs_BGR( orgs.C_DARKBLUE, orgs.C_BLUE )
  self.Upgrade:SetTall( 30 )
  self.Upgrade:orgs_Dock( LEFT, {l=125} )
  self.Upgrade:orgs_SetText( 'Upgrade group', 'orgs.Medium', orgs.C_WHITE, true )
  self.Upgrade.DoClick = function( p )
    vgui.Create( 'orgs.Menu.Manage_Upgrade')
  end

  self.Save = self.Bottom:Add( 'DButton' )
  self.Save:orgs_BGR( orgs.C_DARKBLUE, orgs.C_BLUE )
  self.Save:SetTall( 30 )
  self.Save:orgs_Dock( RIGHT, {r=125} )
  self.Save:orgs_SetText( 'Save', 'orgs.Medium', orgs.C_WHITE )
  self.Save.DoClick = function( p )
    local org, tab = LocalPlayer():orgs_Org(), {}

    for k, v in pairs{ 'Tag', 'Motto', 'Name' } do
      if self[v]:GetText() ~= '' and self[v]:GetText() ~= org[v] then
        tab[v] = self[v]:GetText()
      end
    end

    local c = self.ColorCube.Color
    tab.Color = '%s,%s,%s' %{c.r, c.g, c.b}
    tab.Color = tab.Color ~= org.Color and tab.Color or nil
    if self.Public:GetChecked() ~= ( org.Public or false ) then
      tab.Public = self.Public:GetChecked()
    end

    netmsg.Send( 'orgs.Menu.Manage.Edit', tab )( function( tab )
      if tab[1] then
        orgs.Menu:SetError( 'Failed to modify the group because '.. orgs.ModifyFails[tab[1]] )
        self:Update( LocalPlayer():orgs_Org() )
        return
      end
      -- orgs.Menu:Update()
      orgs.ChatLog( 'Modified the group successfully' )
    end )
  end

end

function PANEL:NewLine()

  local l = self:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=10}, {l=15,r=15} )
  l:orgs_BGR( orgs.C_NONE )

  return l
end

function PANEL:Update( org )
  self.Name:orgs_SetText( org.Name )
  self.Tag:orgs_SetText( org.Tag )
  self.Motto:orgs_SetText( org.Motto )
  self.ColorCube.Color = istable( org.Color ) and org.Color
    or Color( unpack( string.Explode( ',', org.Color ) ) )
  self.Public:SetChecked( org.Public )
end

vgui.Register( 'orgs.Menu.Manage_Modify', PANEL, 'EditablePanel' )
