local PANEL = {}

function PANEL:Init()

  self.Base = vgui.GetControlTable( 'orgs.JoinMenu_Join' )
  self.Base.Init( self )

  self.NoGroups:orgs_SetText( 'You have no invitations' )

end

function PANEL:AddLine( org, inv )

  local l = self.Base.AddLine( self, org )
  l.InviteID = org

  l.Join:SetText( 'Accept' )
  l.Join:orgs_Dock( FILL, {l=15,r=15,u=17,d=17} )

  self.Lines[org.OrgID] = nil
  self.Lines[inv.InviteID] = l

  return l
end

function PANEL:Update( org )
  local invites = netmsg.safeTable( orgs.Invites, true )

  self.NoGroups:SetVisible( table.Count( invites ) < 1 )
  self.List:SetVisible( table.Count( invites ) > 0 )

  if table.Count( invites ) < 1 then return end

  for k, l in pairs( self.Lines ) do
    if not invites[k] then
      self.List:RemoveLine( k )
      self.Lines[k] = nil
    end
  end

  for k, inv in pairs( invites ) do
    if inv.To ~= LocalPlayer():SteamID64() then continue end
    local org, l = orgs.List[inv.OrgID], self.Lines[inv.InviteID]

    if not IsValid( l ) then
      l = self:AddLine( org, inv )

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

vgui.Register( 'orgs.JoinMenu_Invites', PANEL )
