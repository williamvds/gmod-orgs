local PANEL = {}

function PANEL:Init()
  self.Lines = {}

  self.NoGroups = self:orgs_AddLabel( 'There are no public groups - try making your own' )
  self.NoGroups:Dock( FILL )
  self.NoGroups:SetContentAlignment( 5 )
  self.NoGroups:Hide()

  self.List = self:Add( 'DListView' )
  self.List:orgs_Dock( FILL, {l=-1,r=-1} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 65 )
  self.List:Hide()
  self.List.OnClickLine = function() end

  for k, v in pairs( {
    {txt= 'Rank', w= 100},
    {txt= 'Organisation'},
    {txt= 'Members', w=100},
    {txt= '', w=100},
  } ) do
    c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
  end

end

function PANEL:AddLine( org )

  local l = vgui.GetControlTable( 'DListView' ).AddLine( self.List,
    org.Rank, org.Name, org.Members, '' )
  l.OrgID = org.OrgID

  l.ApplySchemeSettings = function( p )
    for k, v in pairs( p.Columns ) do
      v:SetFont( string.StartWith( v:GetFont() or '', 'orgs.' )
        and v:GetFont() or 'orgs.SmallLight' )
    end
  end

  for i= 1, 3 do
    l.Columns[i]:orgs_SetText( nil, 'orgs.Large' )
    l.Columns[i]:SetContentAlignment( 5 )
  end

  l.Columns[2]:SetContentAlignment( 8 )
  l.Columns[2]:SetTextInset( 0, 5 )

  l.Motto = l.Columns[2]:orgs_AddLabel( org.Motto )
  l.Motto:orgs_Dock( BOTTOM, {u=2,d=5} )
  l.Motto:SetTall( 25 )
  l.Motto:SetContentAlignment( 5 )
  if not org.Motto then l.Motto:Hide() end

  l.JoinPanel = l:Add( 'DPanel' )
  l.JoinPanel.SetFont = function() end
  l:SetColumnText( 4, l.JoinPanel )
  l.JoinPanel:orgs_BGR( orgs.COLOR_NONE )

  l.Join = l.JoinPanel:Add( 'DButton' )
  l.Join:orgs_SetText( 'Join' )
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
