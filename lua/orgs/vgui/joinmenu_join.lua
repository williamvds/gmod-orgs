local PANEL = {}

function PANEL:Init()
  self.Lines = {}

  self.NoGroups = self:orgs_AddLabel( 'There are no public groups - try making your own',
    'orgs.Medium' )
  self.NoGroups:Dock( FILL )
  self.NoGroups:SetContentAlignment( 5 )
  self.NoGroups:Hide()

  self.List = self:Add( 'DListView' )
  self.List:orgs_Dock( FILL, {l=-1,r=-3} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 65 )
  self.List:orgs_BGR( orgs.C_NONE )
  self.List:Hide()

  for k, v in pairs( {
    {txt= 'Rank', w= 100},
    {txt= ''},
    {txt= 'Members', w=100},
    {txt= '', w=100},
  } ) do
    c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
    c.Header:orgs_SetText( nil, 'orgs.Medium', orgs.C_WHITE )
    c.Header:orgs_BGR( orgs.C_DARKBLUE )
  end

  self:Update()
end

function PANEL:AddLine( rank, org )

  local l = vgui.GetControlTable( 'DListView' ).AddLine( self.List,
    rank, org.Name, org.Members, '' )
  l.OrgID = org.OrgID

  l.Columns[1]:orgs_SetText( nil, 'orgs.Large', orgs.C_WHITE )
  l.Columns[1]:SetContentAlignment( 5 )
  l.Columns[1]:Dock( LEFT )

  l.Columns[2]:orgs_SetText( nil, 'orgs.Large', orgs.C_WHITE )
  l.Columns[2]:SetContentAlignment( 5 )
  l.Columns[2]:Dock( FILL )

  l.Columns[3]:orgs_SetText( nil, 'orgs.Large', orgs.C_WHITE )
  l.Columns[3]:SetContentAlignment( 5 )
  l.Columns[3]:Dock( RIGHT )

  l.Motto = l:orgs_AddLabel( nil, 'orgs.Medium' )
  l.Motto:orgs_Dock( BOTTOM, {u=2,d=5} )
  l.Motto:SetTall( 25 )
  l.Motto:SetContentAlignment( 5 )
  if not org.Motto then l.Motto:Hide() end

  l.JoinPanel = l:Add( 'DPanel' )
  l.JoinPanel:orgs_BGR( orgs.C_NONE )
  l.JoinPanel:Dock( RIGHT )
  l.JoinPanel:SetZPos( -2 )

  l.Join = l.JoinPanel:Add( 'DButton' )
  l.Join:orgs_SetText( 'Join', 'orgs.Medium', orgs.C_WHITE )
  l.Join:orgs_BGR( orgs.C_DARKBLUE, orgs.C_BLUE )
  l.Join:orgs_Dock( FILL, {l=22,r=22,u=17,d=17 } )
  l.Join.DoClick = function( p )
    netmsg.Send( 'orgs.JoinMenu_Join.Join', {org.OrgID} )
  end

  l.DataLayout = function( self, ListView )
  	self:ApplySchemeSettings()
  	for k, Column in pairs( self.Columns ) do
  		Column:SetWide( ListView:ColumnWidth( k ) )
  	end
    l.JoinPanel:SetWide( ListView:ColumnWidth( 4 ) )
  end

  l:orgs_BGR( orgs.C_NONE, orgs.C_DARKGRAY )

  self.Lines[org.OrgID] = l

  return l
end

function PANEL:Update()
  local list = netmsg.safeTable( orgs.List, true )

  local public = table.Copy( list )
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


  local rank = -1
  for k, org in SortedPairsByMemberValue( list, 'Balance' ) do
    rank = rank +1
    local l = self.Lines[org.OrgID]

    if not IsValid( l ) then
      l = self:AddLine( table.Count( list ) -rank, org )

    else
      l.Columns[2]:SetText( org.Name )
      if org.Motto then
        l.Motto:SetText( '\'%s\'' %{org.Motto or ''} )
        l.Motto:Show()
      end
      l.Columns[1]:SetText( table.Count( list ) -rank )
      l.Columns[3]:SetText( org.Members or 0 )
    end

    if not org.Public then self.List:RemoveLine( l:GetID() ) end
  end


end

vgui.Register( 'orgs.JoinMenu_Join', PANEL )
