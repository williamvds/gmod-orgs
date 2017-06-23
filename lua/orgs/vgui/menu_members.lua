local PANEL = {}

-- From wiki.garrysmod.com/page/surface/DrawPoly
local drawCircle = function( x, y, radius, seg, col )
  surface.SetDrawColor( col )
  draw.NoTexture()
  local cir = {}

  table.insert( cir, { x= x, y= y, u= 0.5, v= 0.5 } )
  for i = 0, seg do
    local a = math.rad( ( i / seg ) * -360 )
    table.insert( cir, { x= x + math.sin( a ) *radius,
      y= y + math.cos( a ) * radius,
      u= math.sin( a ) / 2 + 0.5,
      v= math.cos( a ) / 2 + 0.5 } )
  end

  local a = math.rad( 0 )
  table.insert( cir, { x= x +math.sin( a ) *radius,
    y= y +math.cos( a ) *radius,
    u= math.sin( a ) / 2 + 0.5,
    v= math.cos( a ) / 2 + 0.5 } )

  surface.DrawPoly( cir )
end

function PANEL:Init()
  self.Players = {}

  self.Desc = self:orgs_AddLabel( 'For more actions double click members',
    'orgs.Small' )
  self.Desc:orgs_Dock( BOTTOM, {u=5,d=5} )
  self.Desc:SetContentAlignment(5)

  self.Invite = self:Add( 'DButton' )
  self.Invite:orgs_SetText( 'Invite' )
  self.Invite:orgs_Dock( BOTTOM, {l=260, r=260} )
  self.Invite:SetTall( 30 )
  self.Invite.DoClick = function( b )
    vgui.Create( 'orgs.Menu.Members.Invite' )
  end

  self.List = self:Add( 'DListView' )
  self.List.oldAddLine = vgui.GetControlTable( 'DListView' ).AddLine
  -- Negative margin to fix the last column having wrong width
  -- and to fix apparent 1px horizontal padding on lines
  self.List:orgs_Dock( FILL, {l=-1,r=-3} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 24 )
  self.List:SetMultiSelect( false )

  local c
  for k, v in pairs( {
    {txt= '', w= 24},
    {txt= 'Member'},
    {txt= 'Rank', w=150},
    {txt= 'Salary', w= 125}
  } ) do
    c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
  end

  self.List.AddLine = function( self, ply, ... )
    local tab, text = {...}, {}
    for k, v in pairs( tab ) do text[k] = istable(v) and v[1] or v end

    local l = self:oldAddLine( player.GetBySteamID64( ply ) and '' or ' ', unpack( text ) )
    l.Player = ply

    l.Columns[1].Color = self:GetText() == '' and orgs.Colors.MenuIndicatorOn
      or orgs.Colors.MenuIndicatorOn
    l.Columns[1].PaintOver = function( p, w, h )
      local col = p:GetText() == '' and orgs.Colors.MenuIndicatorOn or orgs.Colors.MenuIndicatorOn
      col.a = 63
      drawCircle( 12, 12, 8, 24, col )
      col.a = 255
      drawCircle( 12, 12, 8, 12, col )
    end

    if l.Columns[4]:GetText() == '' then l.Columns[4]:SetText( 'none' ) end

    for k, v in pairs( tab ) do
      if istable(v) and v[2] then l:SetSortValue( k, v[2] ) end
    end

    self:GetParent().Players[ ply ] = l

    return l
  end

  self.List.OnRowRightClick = function( self, id, line )

    CloseDermaMenus()
    self.Popup = self:Add( 'DMenu' )

    self.Popup:AddOption( 'View Steam profile', function()
      gui.OpenURL( 'https://steamcommunity.com/profiles/'.. line.Player )
    end )

    if line.Player ~= LocalPlayer():SteamID64()
    and LocalPlayer():orgs_Has( orgs.PERM_KICK ) then
      self.Popup:AddOption( 'Kick', function()
        netmsg.Send( 'orgs.Menu.Members.Kick', line.Player )( function( tab )
          if tab[1] then
            return
          end
          -- orgs.Menu:Update()
        end )
      end )
    end

    if LocalPlayer():orgs_Has( orgs.PERM_PROMOTE ) then
      self.Popup:AddOption( 'Manage member', function()
        orgs._managePlayer = orgs.Members[line.Player]
        vgui.Create( 'orgs.Menu.Members.Manage' )
        orgs._managePlayer = nil
      end )
    end

    self.Popup:Open()
  end
  self.List.DoDoubleClick = self.List.OnRowRightClick

end

function PANEL:Update( org )

  for k, l in pairs( self.List:GetLines() ) do
    local member = orgs.Members[ l.Player ]
    if not member then self.List:RemoveLine( k ) continue end
    local rank = orgs.Ranks[ member.RankID ]

    l:SetColumnText( 1, player.GetBySteamID64( l.Player ) and '' or ' ' )
    l:SetColumnText( 2, member.Nick )
    l:SetColumnText( 3, rank.Name )
    l:SetColumnText( 4, member.Salary and orgs.FormatCurrency( member.Salary ) or 'none' )
  end

  self.Invite:SetVisible( LocalPlayer():orgs_Has( orgs.PERM_INVITE ) )

  for k, ply in pairs( netmsg.safeTable( orgs.Members, true ) ) do
    if self.Players[ k ] then continue end
    local rank = orgs.Ranks[ply.RankID]
    self.List:AddLine( ply.SteamID, ply.Nick, {rank.Name, rank.Immunity},
      ply.Salary and orgs.FormatCurrency( ply.Salary ) )
  end
end

vgui.Register( 'orgs.Menu.Members', PANEL, 'DPanel' )

-- Player management popup

local PANEL = {}

function PANEL:Init()
  local l
  self:SetSize( 375, 315 )
  self:AnimateShow()

  if not orgs._managePlayer then return end
  self.Player = orgs._managePlayer

  self:SetTitle( 'Managing '.. self.Player.Nick )

  l = self:NewLine()

  self.RankLabel = l:orgs_AddLabel( 'Rank' )
  self.RankLabel:orgs_Dock( LEFT, {l=20} )
  self.RankLabel:SetWide( 50 )
  self.RankLabel:SetContentAlignment( 6 )

  self.Rank = l:Add( 'DComboBox' )
  self.Rank:orgs_Dock( LEFT, {l=15} )
  self.Rank:orgs_SetText( nil, 'orgs.Medium', orgs.Colors.MenuText )
  self.Rank:SetSize( 175, 25 )
  self.Rank.OnSelect = function( p, id, value, data )
    for k, v in pairs( orgs.PermCheckboxes ) do
      local box, perm = self[v[1]], orgs['PERM_'.. string.upper( v[1] )]
      box:SetChecked( orgs.RankHas( data, perm ) or orgs.Has( orgs._managePlayer, perm ) )
      box:SetDisabled( orgs.RankHas( data, perm ) or not orgs.Has( LocalPlayer(), perm ) )
    end
  end

  l = self:NewLine()

  self.SalaryLabel = l:orgs_AddLabel( 'Salary' )
  self.SalaryLabel:orgs_Dock( LEFT, {l=20} )
  self.SalaryLabel:SetWide( 50 )
  self.SalaryLabel:SetContentAlignment( 6 )

  self.Salary = l:Add( 'DTextEntry' )
  self.Salary:orgs_Dock( LEFT, {l=15} )
  self.Salary:SetSize( 150, 25 )
  self.Salary:SetNumeric( true )
  self.Salary:orgs_SetText( self.Player.Salary )

  l = self:NewLine()

  self.PermsLabel = l:Add( 'DLabel' )
  self.PermsLabel:orgs_SetText( 'Permissions' )
  self.PermsLabel:orgs_Dock( LEFT, {l=-15}, nil, true )

  l = self:NewLine()
  for k, v in pairs( orgs.PermCheckboxes ) do

    self[v[1]] = l:Add( 'DCheckBoxLabel' )
    local box = self[v[1]]
    box:Dock( k %2 ~= 0 and LEFT or RIGHT )
    box.Label:orgs_SetText( v[2], 'orgs.Small' )
    box.Label:orgs_Dock( LEFT, {l=20} )
    box.Label:SetContentAlignment(4)
    if k %2 ~= 0 then box:SizeToContents()
    else box:SetWide( 130 ) end

    if k %2 == 0 then l = self:NewLine() end
  end

  for k, rank in pairs( netmsg.safeTable( orgs.Ranks, true ) ) do
    if rank.Immunity > LocalPlayer():orgs_Rank().Immunity then continue end
    self.Rank:AddChoice( rank.Name, rank.RankID, rank.RankID == self.Player.RankID )
  end

  self.Save = self.Body:Add( 'DButton' )
  self.Save:orgs_SetText( 'Save' )
  self.Save:orgs_Dock( BOTTOM, {l=150,r=150} )
  self.Save:SetTall( 30 )
  self.Save.DoClick = function( p )
    local perms, tab = {}, {}

    for k, v in pairs( orgs.PermCheckboxes ) do
      if not self[v[1]]:GetDisabled() and self[v[1]]:GetChecked() then
        table.insert( perms, orgs['PERM_'.. string.upper( v[1] )] )
      end
    end
    perms = string.Implode( ',', perms )

    tab.Perms = perms ~= ( self.Player.Perms or '' ) and perms or nil

    local sal = tonumber( self.Salary:GetText() )
    tab.Salary = sal and sal ~= self.Player.Salary
      and math.floor( sal )
      or nil

    local _, rankID = self.Rank:GetSelected()
    tab.RankID = rankID ~= self.Player.RankID and rankID or nil

    if table.Count( tab ) < 1 then
      self:AnimateHide()
      return
    end

    tab.Player = self.Player.SteamID

    netmsg.Send( 'orgs.Menu.Members.Manage', tab )( function( tab )
      if tab[1] and IsValid( orgs.Menu ) then
        orgs.Menu:SetError( 'Failed to manage member because '.. orgs.ManageFails[tab[1]] )
      return end
      if IsValid( orgs.Menu ) then
        orgs.Menu.Members:Update()
      end
      self:AnimateHide()
    end )
  end

end

function PANEL:NewLine()

  local l = self.Body:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=10}, {l=25,r=25} )
  l:orgs_BGR( orgs.COLOR_NONE )

  return l
end

vgui.Register( 'orgs.Menu.Members.Manage', PANEL, 'orgs.Popup' )

local PANEL = {}

function PANEL:Init()
  local l

  self:SetTitle( 'Invite player' )
  self:SetSize( 350, 200 )
  self:AnimateShow()

  self.Desc = self.Body:orgs_AddLabel( 'Invite a player to join the group',
    'orgs.Small' )
  self.Desc:Dock( TOP, {u=5,d=5} )
  self.Desc:SetContentAlignment(5)

  l = self:NewLine()

  self.PlayerLabel = l:orgs_AddLabel( 'Select player' )
  self.PlayerLabel:Dock( LEFT )
  self.PlayerLabel:SetWide( 105 )
  self.PlayerLabel:SetContentAlignment( 6 )

  self.Player = l:Add( 'DComboBox' )
  self.Player:orgs_Dock( LEFT, {l=15} )
  self.Player:orgs_SetText( nil, 'orgs.Medium', orgs.Colors.MenuText )
  self.Player:SetWide( 185 )
  self.Player:AddChoice( 'Send by Steam ID', -1 )
  for k, ply in pairs( player.GetHumans() ) do
    if orgs.Members[ply:SteamID64()] then continue end
    self.Player:AddChoice( ply:Nick(), ply:SteamID64() )
  end
  self.Player.OnSelect = function( p, _, _, val )
    self.SteamIDLine:SetVisible( val == -1 )
    local to = not isnumber( val ) and val or
      tonumber( self.SteamID:GetValue() ) and self.SteamID:GetValue()
      or util.SteamIDTo64( self.SteamID:GetValue() )
    self.SteamIDErr:SetVisible( to == '0' )
    self.Send:SetDisabled( to == '0' )
  end

  self.SteamIDLine = self:NewLine()

  self.SteamIDLabel = self.SteamIDLine:orgs_AddLabel( 'Steam ID' )
  self.SteamIDLabel:Dock( LEFT )
  self.SteamIDLabel:SetWide( 105 )
  self.SteamIDLabel:SetContentAlignment( 6 )

  self.SteamID = self.SteamIDLine:Add( 'DTextEntry' )
  self.SteamID:orgs_Dock( LEFT, {l=15} )
  self.SteamID:SetSize( 185, 25 )
  self.SteamID.OnChange = function( p )

    local val, ply, to = p:GetValue(), ({self.Player:GetSelected()})[2]
    if not isnumber( ply ) then
      -- SteamID from combobox
      to = ply

    elseif tonumber( val ) then
      -- SteamID64 validation
      if val:len() < 5 then
        p.Value = false; self.SteamIDErr:Show(); self.Send:SetDisabled( true )
        return
      end

      local num = tonumber( val:sub(5) ) -1197960265728

      if not string.StartWith( val, '7656' )
      or num < 0 or num > 68719476736 then
        p.Value = false; self.SteamIDErr:Show(); self.Send:SetDisabled( true )
        return
      end

      to = val

    else
      -- SteamID validation
      if not val or val == ''
      or not string.find( val, '^STEAM_[0-1]:([0-1]):([0-9]+)$') then
        p.Value = false; self.SteamIDErr:Show(); self.Send:SetDisabled( true )
        return
      end

      to = util.SteamIDTo64( val )
    end

    p.Value = to; self.SteamIDErr:Hide(); self.Send:SetDisabled( false )

    return to
  end

  self.SteamIDErr = self.Body:orgs_AddLabel( 'Invalid Steam ID', 'orgs.Small', orgs.Colors.Error )
  self.SteamIDErr:orgs_Dock( TOP, {u=10} )
  self.SteamIDErr:SetWide( 100 )
  self.SteamIDErr:SetContentAlignment( 5 )


  self.Send = self.Body:Add( 'DButton' )
  self.Send:orgs_Dock( BOTTOM, {l=135,r=135,d=5} )
  self.Send:SetTall( 30 )
  self.Send:orgs_SetText( 'Send' )
  self.Send.DoClick = function( p )

    local to = self.SteamID:IsVisible() and self.SteamID.Value
      or self.Player.Value

    toPly = player.GetBySteamID64( to )
    netmsg.Send( 'orgs.Menu.Members.Invite', {to} ) ( function( tab )
      if tab[1] then
        orgs.Menu:SetError( 'Couldn\'t invite because ' ..orgs.InviteFails[tab[1]] )
      end

      self:AnimateHide()
    end )
  end

  self.Player:ChooseOptionID(1)
end

function PANEL:NewLine()

  local l = self.Body:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=10}, {l=10,r=10} )
  l:orgs_BGR( orgs.COLOR_NONE )

  return l
end

vgui.Register( 'orgs.Menu.Members.Invite', PANEL, 'orgs.Popup' )
