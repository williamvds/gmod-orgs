local PANEL = {}

function PANEL:Init()
  self:orgs_Dock( FILL, {u=5,d=5})

  self.Selector = self:Add( 'DColumnSheet' )
  self.Selector:orgs_BGR( orgs.C_NONE )
  self.Selector:orgs_Dock( FILL, {r=5} )
  self.Selector.Navigation:orgs_Dock( LEFT, {l=5,r=5})

  self.Modify = self:Add( 'orgs.Menu.Manage_Modify' )
  self.Selector:AddSheet( 'Edit group', self.Modify )

  self.Ranks = self:Add( 'orgs.Menu.Manage_Ranks' )
  self.Selector:AddSheet( 'Edit ranks', self.Ranks )

  self.Events = self:Add( 'orgs.Events' )
  self.Selector:AddSheet( 'View events', self.Events )

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
    [self.Ranks]= 'RANKS' }

  for k, v in SortedPairs( self.Selector.Items, true ) do
    local bool = LocalPlayer():orgs_Has( orgs['PERM_'..panels[v.Panel]] )
    v.Button:SetVisible( bool )
    if bool then visible[k] = v.Button end
  end

  if not table.HasValue( visible, self.Selector.ActiveButton ) and table.Count( visible ) > 0 then
    self.Selector:SetActiveButton( select( 2, next( visible ) ) )
  end

  self.Modify:Update( org )
  self.Events:Update( org )
  self.Ranks:Update( org )
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
      orgs.Menu:SetMsg( 'Modified the group successfully' )
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

local PANEL = {}

function PANEL:Init()
  self.Ranks = {}
  -- Negative margin to fix the last column having wrong width
  -- and to fix apparent 1px horizontal padding on lines
  self:Dock( FILL )
  self:orgs_BGR( orgs.C_GRAY )

  self.List = self:Add( 'DListView' )
  self.List:orgs_Dock( FILL, {l=-1,r=-3} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 24 )
  self.List:SetMultiSelect( false )
  self.List:orgs_BGR( orgs.C_GRAY )

  self.Desc = self:orgs_AddLabel( 'Manage ranks by secondary or double clicking them',
    'orgs.Small', orgs.C_WHITE )
  self.Desc:orgs_Dock( BOTTOM, {u=5} )
  self.Desc:SetContentAlignment(5)

  local c
  for k, v in pairs( {
    {txt= '', w=25},
    {txt= 'Name'},
    {txt= 'Immunity', w=100},
    {txt= 'Withdraw limit', w= 150},
  } ) do
    c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
    c.Header:orgs_SetText( nil, 'orgs.Medium', orgs.C_WHITE )
    c.Header:orgs_BGR( orgs.C_DARKBLUE )
  end

  local oldAddLine = vgui.GetControlTable( 'DListView' ).AddLine

  -- List AddLine
  self.List.AddLine = function( p, rank, ... )
    local tab, text = {...}, {}
    for k, v in pairs( tab ) do text[k] = istable(v) and v[1] or v end


    local l = oldAddLine( p, unpack{...} )
    l.Rank = rank.RankID

    l.Paint = function( self, w, h )
      local col = orgs.C_NONE
      if self:IsSelected() then col = orgs.C_LIGHTGRAY end
      orgs.DrawRect( 0, 0, w, h, col )
    end

    for k, v in pairs( tab ) do
      if istable(v) and v[2] then l:SetSortValue( k, v[2] ) end
    end

    for k, c in pairs( l.Columns ) do
      c:orgs_SetText( nil, 'orgs.SmallLight', orgs.C_WHITE )
      c:SetContentAlignment(5)
    end

    self.Ranks[ rank.RankID ] = l

    return l
  end

  -- List OnRowRightClick
  self.List.OnRowRightClick = function( p, id, line )

    self.Popup = DermaMenu( p )
    self.Popup:orgs_BGR( orgs.C_WHITE )

    self.Popup:AddOption( 'Manage rank', function()
      orgs._manageRank = line.Rank
      vgui.Create( 'orgs.Menu.Manage_Ranks.Edit' )
      orgs._manageRank = nil
    end )

    local rankName, curDefault = orgs.Ranks[line.Rank].Name, LocalPlayer():orgs_Org().DefaultRank
    if LocalPlayer():orgs_Has( orgs.PERM_MODIFY )
    and line.Rank ~= curDefault then
      self.Popup:AddOption( 'Make default', function()
        netmsg.Send( 'orgs.Menu.Manage.Edit', {DefaultRank=line.Rank} )( function( tab )
          if tab[1] then
            orgs.Menu:SetError( 'Failed set default rank because '.. orgs.ModifyFails[tab[1]] )
            return
          end
          self.Ranks[curDefault]:SetColumnText( 1, '' )
          self.Ranks[line.Rank]:SetColumnText( 1, '*' )
          orgs.Menu:SetMsg( rankName ..' is now the group\'s default rank' )
        end )

      end )
    end

    if orgs.Ranks[line.Rank].Immunity < LocalPlayer():orgs_Rank().Immunity
    and line.Rank ~= curDefault then
      self.Popup:AddOption( 'Remove rank', function()
        netmsg.Send( 'orgs.Menu.Manage.RemoveRank', line.Rank )( function( tab )
          if tab[1] then
            orgs.Menu:SetError( 'Failed to remove rank because '.. orgs.RemoveRankFails[tab[1]] )
            return
          end
          orgs.Menu:SetMsg( 'Removed rank '.. rankName )
          self.List:RemoveLine( id )
        end )

      end )

    end

    self.Popup:AddOption( 'Add new rank', function()
      vgui.Create( 'orgs.Menu.Manage_Ranks.Edit' )
    end )

    for k, opt in pairs( self.Popup:GetCanvas():GetChildren() ) do
      if opt.ThisClass ~= 'DMenuOption' then continue end
      opt:orgs_SetText( nil, 'orgs.Small', orgs.C_DARKGRAY )
      opt:SetTextInset( 10, 0 )
      opt:orgs_BGR( orgs.C_NONE )
    end

    self.Popup:Open()
  end
  self.List.DoDoubleClick = self.List.OnRowRightClick

end

function PANEL:Update( org )
  for k, rank in pairs( netmsg.safeTable( orgs.Ranks, true ) ) do
    if self.Ranks[ rank.RankID ] then
      local l = self.Ranks[ rank.RankID ]
      l:SetColumnText( 1, k == org.DefaultRank and '*' or '' )
      l:SetColumnText( 2, rank.Name )
      l:SetColumnText( 3, rank.Immunity )
      l:SetColumnText( 4, rank.BankLimit and '%s/%s %s' %{
        orgs.FormatCurrencyShort( rank.BankLimit ),
        rank.BankCooldown, 'mins'} or '' )

    else
      self.List:AddLine( rank, k == org.DefaultRank and '*' or '', rank.Name, rank.Immunity,
        rank.BankLimit and '%s/%s %s' %{
          orgs.FormatCurrencyShort( rank.BankLimit ),
          rank.BankCooldown, 'mins'} or '' )

    end
    self.List:SortByColumn( 3, true )
  end
end

vgui.Register( 'orgs.Menu.Manage_Ranks', PANEL, 'DListView' )

local PANEL = {}

function PANEL:Init()
  local l
  self:SetSize( 400, 365 )
  self:AnimateShow()

  self.Rank = orgs.Ranks[orgs._manageRank] or {}

  self.Header.Title:SetText( self.Rank.RankID and 'Managing '.. self.Rank.Name
    or 'Creating new rank')

  l = self:NewLine()

  self.NameLabel = l:orgs_AddLabel( 'Name', 'orgs.Medium', orgs.C_WHITE, true )
  self.NameLabel:orgs_Dock( LEFT, {l=35} )
  self.NameLabel:SetWide( 80 )
  self.NameLabel:SetContentAlignment( 6 )

  self.Name = l:Add( 'DTextEntry' )
  self.Name:orgs_Dock( LEFT, {l=15} )
  self.Name:SetSize( 150, 25 )
  self.Name:SetFont( 'orgs.Medium' )
  self.Name.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.Name:SetText( self.Rank.Name )

  l = self:NewLine()

  self.ImmunityLabel = l:orgs_AddLabel( 'Immunity', 'orgs.Medium', orgs.C_WHITE, true )
  self.ImmunityLabel:orgs_Dock( LEFT, {l=35} )
  self.ImmunityLabel:SetWide( 80 )
  self.ImmunityLabel:SetContentAlignment( 6 )

  self.Immunity = l:Add( 'DTextEntry' )
  self.Immunity:orgs_Dock( LEFT, {l=15} )
  self.Immunity:SetSize( 35, 25 )
  self.Immunity:SetFont( 'orgs.Medium' )
  self.Immunity:SetText( '0' )
  self.Immunity:SetNumeric( true )
  self.Immunity.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.Immunity:orgs_SetText( self.Rank.Immunity )

  l = self:NewLine()

  self.PermsLabel = l:Add( 'DLabel' )
  self.PermsLabel:orgs_SetText( 'Permissions', 'orgs.Medium', orgs.C_WHITE )
  self.PermsLabel:orgs_Dock( LEFT, {l=-15}, nil, true )

  l = self:NewLine()
  for k, v in pairs( orgs.PermCheckboxes ) do
    self[v[1]] = l:Add( 'DCheckBoxLabel' )
    local box, perm = self[v[1]], orgs['PERM_'.. string.upper( v[1] )]
    box:Dock( k %2 ~= 0 and LEFT or RIGHT )
    box.Label:orgs_SetText( v[2], 'orgs.Small', orgs.C_WHITE )
    box.Label:orgs_Dock( LEFT, {l=20} )
    box.Label:SetContentAlignment(4)
    if k %2 ~= 0 then box:SizeToContents()
    else box:SetWide( 150 ) end

    if self.Rank.RankID then box:SetChecked( string.find( self.Rank.Perms, perm ) ) end
    box:SetDisabled( not LocalPlayer():orgs_Has( perm ) )

    if k %2 == 0 then l = self:NewLine() end
  end

  self.WithdrawLabel = l:orgs_AddLabel( 'Withdraw limit', 'orgs.Medium', orgs.C_WHITE, true )
  self.WithdrawLabel:orgs_Dock( LEFT, {l=-15} )
  self.WithdrawLabel:SetWide( 120 )
  self.WithdrawLabel:SetContentAlignment( 8 )

  self.BankLimit = l:Add( 'DTextEntry' )
  self.BankLimit:orgs_Dock( LEFT, {l=15} )
  self.BankLimit:SetSize( 85, 25 )
  self.BankLimit:SetFont( 'orgs.Medium' )
  self.BankLimit:SetNumeric( true )
  self.BankLimit.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.BankLimit:SetText( self.Rank.BankLimit )

  self.WithdrawLabel2 = l:orgs_AddLabel( 'every', 'orgs.Medium', orgs.C_WHITE, true )
  self.WithdrawLabel2:orgs_Dock( LEFT, {l=5} )
  self.WithdrawLabel2:SetWide( 45 )
  self.WithdrawLabel2:SetContentAlignment( 8 )
  self.WithdrawLabel2:SetZPos( 1 )

  self.BankCooldown = l:Add( 'DTextEntry' )
  self.BankCooldown:orgs_Dock( LEFT, {l=5} )
  self.BankCooldown:SetSize( 25, 25 )
  self.BankCooldown:SetFont( 'orgs.Medium' )
  self.BankCooldown:SetNumeric( true )
  self.BankCooldown.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.BankCooldown:SetText( self.Rank.BankCooldown )
  self.BankCooldown:SetZPos( 2 )

  self.WithdrawLabel3 = l:orgs_AddLabel( 'mins', 'orgs.Medium', orgs.C_WHITE, true )
  self.WithdrawLabel3:orgs_Dock( LEFT, {l=5} )
  self.WithdrawLabel3:SetWide( 40 )
  self.WithdrawLabel3:SetContentAlignment( 8 )
  self.WithdrawLabel3:SetZPos( 3 )

  self.Save = self.Body:Add( 'DButton' )
  self.Save:orgs_BGR( orgs.C_DARKBLUE, orgs.C_BLUE )
  self.Save:orgs_Dock( BOTTOM, {l=150,r=150} )
  self.Save:SetTall( 30 )
  self.Save:orgs_SetText( 'Save', 'orgs.Medium', orgs.C_WHITE )
  self.Save.DoClick = function( p )
    local perms, tab = {}, {}

    for k, v in pairs( orgs.PermCheckboxes ) do
      if not self[v[1]]:GetDisabled() and self[v[1]]:GetChecked() then
        table.insert( perms, orgs['PERM_'.. string.upper( v[1] )] )
      end
    end
    perms = string.Implode( ',', perms )
    tab.Perms = perms ~= self.Rank.Perms and perms or nil

    tab.Name = self.Name:GetText() ~= self.Rank.Name and self.Name:GetText() or nil

    for k, v in pairs( {'Immunity', 'BankLimit', 'BankCooldown'} ) do
      local tb = self[v]
      if tb:GetText() ~= tostring( self.Rank[v] ) and tb:GetText() ~= '' then
        tab[v] = tonumber( tb:GetText() ) or 0
      end
    end

    if table.Count( tab ) < 1 then
      self:AnimateHide()
      return
    end

    if self.Rank.RankID then
      tab.RankID = self.Rank.RankID
      netmsg.Send( 'orgs.Menu.Manage.EditRank', tab )( function( res )
        if res[1] and IsValid( orgs.Menu ) then
          orgs.Menu:SetError( 'Failed to alter rank because '.. orgs.EditRankFails[res[1]] )
          return
        end
        if IsValid( orgs.Menu ) then
          orgs.Menu:SetMsg( 'Successfully managed '.. self.Rank.Name )
          -- orgs.Menu:Update()
        end
        self:AnimateHide()
      end )

    else
      netmsg.Send( 'orgs.Menu.Manage.AddRank', tab )( function( res )
        if res[1] and IsValid( orgs.Menu ) then
          orgs.Menu:SetError( 'Failed to add rank' )
          return
        end
        if IsValid( orgs.Menu ) then
          orgs.Menu:SetMsg( 'Successfully added rank '.. tab.Name )
          -- orgs.Menu:Update()
        end
        self:AnimateHide()

      end )

    end
  end

end

function PANEL:NewLine()

  local l = self.Body:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=10}, {l=25,r=25} )
  l:orgs_BGR( orgs.C_NONE )

  return l
end

vgui.Register( 'orgs.Menu.Manage_Ranks.Edit', PANEL, 'orgs.Popup' )
