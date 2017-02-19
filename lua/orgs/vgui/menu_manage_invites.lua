local PANEL = {}

function PANEL:Init()
  self.Lines = {}
  self:Dock( FILL )

  self.NoInvites = self:orgs_AddLabel( 'No players are currently invited to the organisation',
    'orgs.Medium', orgs.C_WHITE )
  self.NoInvites:Dock( FILL )
  self.NoInvites:SetContentAlignment(5)

  self.Tip = self:orgs_AddLabel( 'Double click an invitation to withdraw it',
    'orgs.Small', orgs.C_WHITE )
  self.Tip:Dock( BOTTOM, {u=5} )
  self.Tip:SetContentAlignment(5)

  self.List = self:Add( 'DListView' )
  self.List:orgs_Dock( FILL, {l=-1,r=-3} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 24 )
  self.List:SetMultiSelect( false )
  self.List:orgs_BGR( orgs.C_GRAY )

  local c
  for k, v in pairs( {
    {txt= 'Player'},
    {txt= 'Invited by'},
  } ) do
    c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
    c.Header:orgs_SetText( nil, 'orgs.Medium', orgs.C_WHITE )
    c.Header:orgs_BGR( orgs.C_DARKBLUE )
  end

  local oldAddLine = vgui.GetControlTable( 'DListView' ).AddLine

  self.List.AddLine = function( p, inv )
    local to, from = player.GetBySteamID64( inv.To ) and player.GetBySteamID64( inv.To ):Nick()
      or orgs.Members[inv.To] and orgs.Members[inv.To].Nick
      or util.SteamIDFrom64( inv.To ),

      player.GetBySteamID64( inv.From ) and player.GetBySteamID64( inv.From ):Nick()
      or orgs.Members[inv.From] and orgs.Members[inv.From].Nick
      or util.SteamIDFrom64( inv.From )

    local l = oldAddLine( p, to, from )

    l.Invite = inv.InviteID
    l.To = inv.To
    l.From = inv.From

    l.Paint = function( self, w, h )
      local col = orgs.C_NONE
      if self:IsSelected() then col = orgs.C_LIGHTGRAY end
      orgs.DrawRect( 0, 0, w, h, col )
    end

    for k, c in pairs( l.Columns ) do
      c:orgs_SetText( nil, 'orgs.SmallLight', orgs.C_WHITE )
      c:SetContentAlignment(5)
    end

    self.Lines[ inv.InviteID ] = l

    return l
  end

  self.List.OnRowRightClick = function( p, id, line )

    self.Popup = DermaMenu( p )
    self.Popup:orgs_BGR( orgs.C_WHITE )

    self.Popup:AddOption( 'To: View Steam profile', function()
      gui.OpenURL( 'https://steamcommunity.com/profiles/'.. line.To )
    end )

    self.Popup:AddOption( 'From: View Steam profile', function()
      gui.OpenURL( 'https://steamcommunity.com/profiles/'.. line.From )
    end )

    self.Popup:AddOption( 'Withdraw invite', function()
      netmsg.Send( 'orgs.Menu.Members.RemoveInvite', line.Invite ) ( function( tab )
        if tab[1] then
          orgs.Menu:SetError( 'Failed to withdraw invite because '..
            orgs.RemoveInviteFails[tab[1]] )
          return
        end

        self.List:RemoveLine( id )
      end )

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
  for k, l in pairs( self.List.Lines ) do
    if not orgs.Invites[l.Invite] then self.List:RemoveLine( k ) end
  end

  local num = 0
  for k, inv in pairs( netmsg.safeTable( orgs.Invites, true ) ) do
    if self.Lines[ inv.InviteID ] then return end

    self.List:AddLine( inv )

    num = num +1
  end

  self.NoInvites:SetVisible( num < 1 )
  self.List:SetVisible( num > 0 )
  self.Tip:SetVisible( num > 0 )

end


vgui.Register( 'orgs.Menu.Manage_Invites', PANEL )
