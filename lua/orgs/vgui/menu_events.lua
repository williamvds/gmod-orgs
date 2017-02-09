local PANEL = {}

function PANEL:Init()
  self.Lines = {}
  self:Dock( FILL )
  self:orgs_BGR( orgs.C_GRAY )

  self.NoEvents = self:orgs_AddLabel( 'There are no events visible to you',
  'orgs.Medium', orgs.C_WHITE )
  self.NoEvents:Dock( FILL )
  self.NoEvents:SetContentAlignment(5)

  self.Desc = self:orgs_AddLabel( 'For more information double click events',
    'orgs.Small', orgs.C_WHITE )
  self.Desc:orgs_Dock( BOTTOM, {u=5} )
  self.Desc:SetContentAlignment(5)

  self.List = self:Add( 'DListView' )
  self.List:orgs_Dock( FILL, {l=-1} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 20 )
  self.List:SortByColumn( 1, true )
  self.List:orgs_BGR( orgs.C_GRAY )
  self.List.oldAddLine = vgui.GetControlTable( 'DListView' ).AddLine

  for k, v in pairs( {
    {txt= 'Time', w= 120},
    {txt= 'Description'},
  } ) do
    local c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
    c.Header:orgs_SetText( nil, 'orgs.Medium', orgs.C_WHITE )
    c.Header:orgs_BGR( orgs.C_DARKBLUE )
  end

  self.List.Think = function( self )
    if not self.doLayout then return end
    self:SetDirty( true )
    self:InvalidateLayout()
  end

  self.List.AddLine = function( self, event )

    local l = self:oldAddLine( '', '' )
    l.Event = event

    l.Paint = function( p, w, h )
      local col = orgs.C_NONE
      if p:IsSelected() then col = orgs.C_LIGHTGRAY end
      orgs.DrawRect( 0, 0, w, h, col )
    end

    for k, c in pairs( l.Columns ) do
      c:orgs_SetText( nil, 'orgs.Tiny', orgs.C_WHITE )
    end

    l.Columns[1]:SetContentAlignment( 6 )
    l.Columns[1]:Dock( LEFT )
    l:SetSortValue( 1, event.EventID )
    l:SetColumnText( 1,
      os.date( '%I:%M %p %d/%m/%y', event.Time ):gsub('/0', '/'):gsub('^0', ''):gsub(' 0', ' ') )

    local rt = l:Add( 'RichText' )
    rt:orgs_Dock( FILL, {r=8} )
    rt.ApplySchemeSettings = function() end
    rt.PerformLayout = function( p )
      p:SetFontInternal( 'orgs.Tiny' )
      p:SetFGColor( orgs.C_WHITE )
    end
    rt:SetVerticalScrollbarEnabled( false )
    rt:SetMouseInputEnabled( false )

    local col = orgs.TextCol
    for k, v in pairs( orgs.EventToString( orgs.ParseEvent( nil, table.Copy( event ) ), true ) ) do
      rt:InsertColorChange( col.r, col.g, col.b, col.a )
      rt:AppendText( v )
      col = col == orgs.TextCol and orgs.HighlightCol or orgs.TextCol
    end

    l.Columns[2]:Remove()
    l.Columns[2] = rt
    l:SetSortValue( 2, tonumber( event.ActionBy ) or 0 )

    l:orgs_BGR( orgs.C_NONE, orgs.C_DARKGRAY )
    self:GetParent().Lines[event.EventID] = l
    self.doLayout = true

    return l
  end

  self.List.OnRowRightClick = function( self, line )
    local event = self:GetLine( line ).Event
    if not event then return end

    self.Popup = DermaMenu( self )
    self.Popup:orgs_BGR( orgs.C_WHITE, Color( 30, 30, 30 ) )

    if event.ActionBy then
      self.Popup:AddOption( 'Actor: View Steam profile', function()
        gui.OpenURL( 'https://steamcommunity.com/profiles/'.. event.ActionBy )
      end )
      self.Popup:AddOption( 'Actor: Copy SteamID', function()
        SetClipboardText( util.SteamIDFrom64( event.ActionBy ) )
      end )
    end

    if event.ActionAgainst and event.ActionAgainst ~= event.ActionBy
    and not TruthTable{ orgs.EVENT_BANK_TRANSFER,
      orgs.EVENT_RANK_RENAME,
      orgs.EVENT_RANK_IMMUNITY,
      orgs.EVENT_RANK_PERMS,
      orgs.EVENT_RANK_BANKLIMIT,
      orgs.EVENT_RANK_BANKCOOLDOWN }[event.Type] then

      self.Popup:AddOption( 'Target: View Steam profile', function()
        gui.OpenURL( 'https://steamcommunity.com/profiles/'.. event.ActionAgainst )
      end )
      self.Popup:AddOption( 'Target: Copy SteamID', function()
        SetClipboardText( util.SteamIDFrom64( event.ActionAgainst ) )
      end )
    end

    for k, opt in pairs( self.Popup:GetCanvas():GetChildren() ) do
      if opt.ThisClass ~= 'DMenuOption' then continue end
      opt:orgs_SetText( nil, 'orgs.Small', orgs.C_DARKGRAY )
      opt:SetTextInset( 10, 0 )
      opt:orgs_BGR( orgs.C_NONE )
    end

    self.Popup:Open()
  end
  self.List.DoDoubleClick = self.List.OnRowRightClick

  self.List.OnRequestResize = function() end

  self.List.DataLayout = function( self )
    local y, h = 0, self.m_iDataHeight
    for k, l in ipairs( self.Sorted ) do
      l:SetPos( 0, y )
      if l.Columns[2]:GetTall() <= 24 then
        l.Columns[2]:SetToFullHeight()
        self.doLayout = true
      end

      l:SetTall( l.Columns[2]:GetTall() > h and l.Columns[2]:GetTall() or h )
      l.Columns[1]:SetWide( self:ColumnWidth( 1 ) )
      l:SetWide( self:GetWide() )

      for k, c in pairs( l.Columns ) do
        c:SetWide( self:ColumnWidth( k ) )
      end

      y = y + l:GetTall()
    end

    return y
  end

end

function PANEL:Update()
  local events = netmsg.safeTable( orgs.Events, true )

  for k, event in SortedPairsByMemberValue( events, 'Time', true ) do
    if self.Lines[ event.EventID ] then continue end
    self.List:AddLine( event )
  end

  self.List:SortByColumn( 1, true )

  self.NoEvents:SetVisible( table.Count( events ) < 1 )
  self.Desc:SetVisible( table.Count( events ) > 0 )
  self.List:SetVisible( table.Count( events ) > 0 )

end

vgui.Register( 'orgs.Events', PANEL, 'DPanel' )
