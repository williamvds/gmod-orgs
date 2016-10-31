local PANEL = {}

function PANEL:Init()
  self.Lines = {}
  self:Dock( FILL, {l=-1,r=-3} )
  self:SetHeaderHeight( 25 )
  self:SetDataHeight( 19 )
  self:SortByColumn( 1, true )
  self:BGR( C_NONE )
  self.oldAddLine = vgui.GetControlTable( 'DListView' ).AddLine

  for k, v in pairs( {
    {txt= 'Time', w= 120},
    {txt= 'Description'},
  } ) do
    c = self:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
    c.Header:SetText( nil, 'orgs.Medium', C_WHITE )
    c.Header:BGR( C_DARKBLUE )
  end

  self.NoEvents = self:AddLabel( 'There are no events visible to you',
    'orgs.Medium' )
  self.NoEvents:Dock( FILL )
  self.NoEvents:SetContentAlignment( 5 )
  self.NoEvents:Hide()

  if not self:GetParent() then self:Update() end
end

function PANEL:Think()
  if not self.doLayout then return end
  self:SetDirty( true )
  self:InvalidateLayout()
end

function PANEL:AddLine( event )

  local l = self:oldAddLine( '', '' )
  l.Event = event

  l.Paint = function( p, w, h )
    local col = C_NONE
    if p:IsSelected() then col = C_LIGHTGRAY end
    DrawRect( 0, 0, w, h, col )
  end

  for k, c in pairs( l.Columns ) do
    c:SetText( nil, 'orgs.Tiny', C_WHITE )
  end

  l.Columns[1]:SetContentAlignment( 6 )
  l.Columns[1]:Dock( LEFT )
  l:SetSortValue( 1, event.EventID )
  l:SetColumnText( 1, os.date( '%I:%M %p %d/%m/%y', event.Time ):gsub('/0', '/'):gsub('^0', '') )

  local rt = l:Add( 'RichText' )
  rt:Dock( FILL, {r=8} )
  rt.ApplySchemeSettings = function() end
  rt.PerformLayout = function( p )
    p:SetFontInternal( 'orgs.Tiny' )
    p:SetFGColor( C_WHITE )
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

  l:BGR( C_NONE, C_DARKGRAY )
  self.Lines[event.EventID] = l
  self.doLayout = true

  return l
end

function PANEL:OnRowRightClick( line )
  local event = self:GetLine( line ).Event
  if not event then return end

  self.Popup = DermaMenu( self )
  self.Popup:BGR( C_WHITE )

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
    opt:SetText( nil, 'orgs.Small', C_DARKGRAY )
    opt:SetTextInset( 10, 0 )
    opt:BGR( C_NONE )
  end

  self.Popup:Open()
end
PANEL.DoDoubleClick = PANEL.OnRowRightClick

function PANEL:DataLayout()
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

function PANEL:OnRequestResize() end

function PANEL:Update()
  local events = safeTable( orgs.Events, true )

  self.NoEvents:SetVisible( table.Count( events ) < 1 )
  self.pnlCanvas:SetVisible( table.Count( events ) > 0 )
  self:SetHideHeaders( table.Count( events ) < 1 )

  for k, event in SortedPairsByMemberValue( events, 'Time', true ) do
    if self.Lines[ event.EventID ] then continue end
    self:AddLine( event )
  end

end

vgui.Register( 'orgs.Events', PANEL, 'DListView' )
