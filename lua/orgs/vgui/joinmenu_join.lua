local PANEL = {}

function PANEL:Init()
  self.Lines = {}

  self.NoGroups = self:orgs_AddLabel( 'There are no public groups - try making your own',
    'orgs.Medium' )
  self.NoGroups:Dock( FILL )
  self.NoGroups:SetContentAlignment( 5 )
  self.NoGroups:Hide()

  self.List = self:Add( 'DListView' )
  self.List:orgs_Dock( FILL, {l=-1,r=-1} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 65 )
  self.List:orgs_BGR( orgs.COLOR_NONE )
  self.List:Hide()

  for k, v in pairs( {
    {txt= 'Rank', w= 100},
    {txt= 'Organisation'},
    {txt= 'Members', w=100},
    {txt= '', w=100},
  } ) do
    c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
    c.Header:orgs_SetText( nil, 'orgs.Medium', orgs.Colors.Text )
    c.Header:orgs_BGR( orgs.Colors.MenuPrimary )
  end

  self.List.Columns[2]:SetWidth( -100 )

  self:Update()
end

function PANEL:AddLine( org )

  local l = vgui.GetControlTable( 'DListView' ).AddLine( self.List,
    org.Rank, org.Name, org.Members, '' )
  l.OrgID = org.OrgID

  for i= 1, 3 do
    l.Columns[i]:orgs_SetText( nil, 'orgs.Large', orgs.Colors.Text )
    l.Columns[i]:SetContentAlignment( 5 )
    l.Columns[i]:Dock( i < 2 and LEFT or i < 3 and FILL or RIGHT )
  end

  l.Motto = l:orgs_AddLabel( nil, 'orgs.Medium' )
  l.Motto:orgs_Dock( BOTTOM, {u=2,d=5} )
  l.Motto:SetTall( 25 )
  l.Motto:SetContentAlignment( 5 )
  if not org.Motto then l.Motto:Hide() end

  l.JoinPanel = l:Add( 'DPanel' )
  l.JoinPanel:orgs_BGR( orgs.COLOR_NONE )
  l.JoinPanel:Dock( RIGHT )
  l.JoinPanel:SetZPos( -2 )

  l.Join = l.JoinPanel:Add( 'DButton' )
  l.Join:orgs_SetText( 'Join', 'orgs.Medium', orgs.Colors.Text )
  l.Join:orgs_BGR( orgs.Colors.MenuPrimary, orgs.Colors.MenuPrimaryAlt )
  l.Join:orgs_Dock( FILL, {l=22,r=22,u=17,d=17} )
  l.Join.DoClick = function( p )
    netmsg.Send( 'orgs.JoinMenu_Join.Join', {org.OrgID} ) ( function( tab )
      if tab[1] then
        orgs.JoinMenu:SetError( 'Couldn\'t join because ' .. orgs.ManageFails[ tab[1] ] )
      else
        orgs.JoinMenu:SetMsg( 'Joining group..' )
      end

    end )
  end

  l.DataLayout = function( self, ListView )
  	self:ApplySchemeSettings()
  	for k, Column in pairs( self.Columns ) do
  		Column:SetWide( ListView:ColumnWidth( k ) )
  	end
    l.JoinPanel:SetWide( ListView:ColumnWidth( 4 ) )
  end

  l:orgs_BGR( orgs.COLOR_NONE, orgs.Colors.MenuBackground )

  self.Lines[org.OrgID] = l

  return l
end

function PANEL:Update()
  local public = netmsg.safeTable( orgs.List, true )

  for k, v in pairs( public ) do
    if not v.Public then public[k] = nil end
  end

  self.NoGroups:SetVisible( table.Count( public ) < 1 )
  self.List:SetVisible( table.Count( public ) > 0 )

  if table.Count( public ) < 1 then return end

  for k, l in pairs( self.Lines ) do
    if not orgs.List[k] then
      self.List:RemoveLine( k )
      self.Lines[k] = nil
    end
  end

  for k, org in pairs( public ) do
    local l = self.Lines[org.OrgID]

    if not IsValid( l ) then
      l = self:AddLine( org )

    else
      l.Columns[2]:SetText( org.Name )
      if org.Motto then
        l.Motto:SetText( [['%s']] %{org.Motto or ''} )
        l.Motto:Show()
      else l.Motto:Hide() end
      l.Columns[1]:SetText( org.Rank )
      l.Columns[3]:SetText( org.Members or 0 )
     end

    if not org.Public then self.List:RemoveLine( l:GetID() ) end
  end

  self.List:SortByColumn( 1 )
end

vgui.Register( 'orgs.JoinMenu_Join', PANEL )
