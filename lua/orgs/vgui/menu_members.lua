local PANEL = {}

-- From wiki.garrysmod.com/page/surface/DrawPoly
local drawCircle = function( x, y, radius, seg )
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
  self:orgs_BGR( orgs.C_GRAY )
  
  self.Desc = self:orgs_AddLabel( 'For more information secondary or double click members',
    'orgs.Small', orgs.C_WHITE )
  self.Desc:orgs_Dock( BOTTOM, {u=5,d=5} )
  self.Desc:SetContentAlignment(5)

  self.List = self:Add( 'DListView' )
  self.List.oldAddLine = vgui.GetControlTable( 'DListView' ).AddLine
  -- Negative margin to fix the last column having wrong width
  -- and to fix apparent 1px horizontal padding on lines
  self.List:orgs_Dock( FILL, {l=-1,r=-3} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 24 )
  self.List:SetMultiSelect( false )
  self.List:orgs_BGR( orgs.C_GRAY )

  local c
  for k, v in pairs( {
    {txt= '', w= 24},
    {txt= 'Member'},
    {txt= 'Rank', w=150},
    {txt= 'Salary', w= 125}
  } ) do
    c = self.List:AddColumn( v.txt )
    if v.w then c:SetFixedWidth( v.w ) end
    c.Header:orgs_SetText( nil, 'orgs.Medium', orgs.C_WHITE )
    c.Header:orgs_BGR( orgs.C_DARKBLUE )
  end

  self.List.AddLine = function( self, ply, ... )
    local tab, text = {...}, {}
    for k, v in pairs( tab ) do text[k] = istable(v) and v[1] or v end


    local l = self:oldAddLine( player.GetBySteamID64( ply ) and '' or ' ', unpack( text ) )
    l.Player = ply

    l.Paint = function( self, w, h )
      local col = orgs.C_NONE
      if self:IsSelected() then col = orgs.C_LIGHTGRAY end
      orgs.DrawRect( 0, 0, w, h, col )
    end

    l.Columns[1].Color = player.GetBySteamID64( ply ) and orgs.C_LIGHTGREEN or orgs.C_RED
    l.Columns[1].PaintOver = function( self, w, h )
      surface.SetDrawColor( self.Color )
      draw.NoTexture()
      drawCircle( 12, 12, 8, 24 )
    end

    for k, v in pairs( tab ) do
      if istable(v) and v[2] then l:SetSortValue( k, v[2] ) end
    end

    for k, c in pairs( l.Columns ) do
      c:orgs_SetText( nil, 'orgs.SmallLight', orgs.C_WHITE )
      c:SetContentAlignment(5)
    end

    self:GetParent().Players[ ply ] = l

    return l
  end

  self.List.OnRowRightClick = function( self, id, line )

    if line.Player ~= LocalPlayer():SteamID64()
    and orgs.Ranks[orgs.Members[line.Player].RankID].Immunity
    >= LocalPlayer():orgs_Rank().Immunity then
      return
    end

    self.Popup = DermaMenu( self )
    self.Popup:orgs_BGR( orgs.C_WHITE )

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

  for k, l in pairs( self.List:GetLines() ) do
    local member = orgs.Members[ l.Player ]
    if not member then self:RemoveLine( k ) continue end
    local rank = orgs.Ranks[ member.RankID ]
    l:SetColumnText( 1, player.GetBySteamID64( l.Player ) and '' or ' ' )
    l:SetColumnText( 2, member.Nick )
    l:SetColumnText( 3, rank.Name )
    l:SetColumnText( 4, member.Salary and orgs.FormatCurrency( member.Salary ) or 'none' )
  end

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

  self.Header.Title:SetText( 'Managing '.. self.Player.Nick )

  l = self:NewLine()

  self.RankLabel = l:orgs_AddLabel( 'Rank', 'orgs.Medium', orgs.C_WHITE, true )
  self.RankLabel:orgs_Dock( LEFT, {l=20} )
  self.RankLabel:SetWide( 50 )
  self.RankLabel:SetContentAlignment( 6 )

  self.Rank = l:Add( 'orgs.ComboBox' )
  self.Rank:orgs_Dock( LEFT, {l=15} )
  self.Rank:SetSize( 175, 25 )
  self.Rank.OnSelect = function( p, id )
    for k, v in pairs( orgs.PermCheckboxes ) do
      local box, perm = self[v[1]], orgs['PERM_'.. string.upper( v[1] )]
      box:SetChecked( string.find( orgs.Ranks[p.Value].Perms, perm )
       or ( self.Player.Perms and string.find( self.Player.Perms, perm ) ) )
      box:SetDisabled( string.find( orgs.Ranks[p.Value].Perms, perm )
        or not LocalPlayer():orgs_Has( perm ) )
    end
  end

  l = self:NewLine()

  self.SalaryLabel = l:orgs_AddLabel( 'Salary', 'orgs.Medium', orgs.C_WHITE, true )
  self.SalaryLabel:orgs_Dock( LEFT, {l=20} )
  self.SalaryLabel:SetWide( 50 )
  self.SalaryLabel:SetContentAlignment( 6 )

  self.Salary = l:Add( 'DTextEntry' )
  self.Salary:orgs_Dock( LEFT, {l=15} )
  self.Salary:SetSize( 150, 25 )
  self.Salary:SetFont( 'orgs.Medium' )
  self.Salary:SetNumeric( true )
  self.Salary.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_WHITE )
    p:DrawTextEntryText( orgs.C_DARKGRAY, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.Salary:orgs_SetText( self.Player.Salary )

  l = self:NewLine()

  self.PermsLabel = l:Add( 'DLabel' )
  self.PermsLabel:orgs_SetText( 'Permissions', 'orgs.Medium', orgs.C_WHITE )
  self.PermsLabel:orgs_Dock( LEFT, {l=-15}, nil, true )

  l = self:NewLine()
  for k, v in pairs( orgs.PermCheckboxes ) do

    self[v[1]] = l:Add( 'DCheckBoxLabel' )
    local box = self[v[1]]
    box:Dock( k %2 ~= 0 and LEFT or RIGHT )
    box.Label:orgs_SetText( v[2], 'orgs.Small', orgs.C_WHITE )
    box.Label:orgs_Dock( LEFT, {l=20} )
    box.Label:SetContentAlignment(4)
    if k %2 ~= 0 then box:SizeToContents()
    else box:SetWide( 130 ) end

    if k %2 == 0 then l = self:NewLine() end
  end

  local id = 1
  for k, rank in pairs( netmsg.safeTable( orgs.Ranks, true ) ) do
    if rank.Immunity > LocalPlayer():orgs_Rank().Immunity then continue end
    self.Rank:AddOption( rank.Name, rank.RankID, rank.Immunity )
    if rank.RankID == self.Player.RankID then self.Rank:Select( id ) end
    id = id +1
  end

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

    tab.Perms = perms ~= self.Player.Perms and perms or nil
    tab.Salary = tonumber(self.Salary:GetText()) ~= self.Player.Salary
      and math.floor( tonumber( self.Salary:GetText() ) ) or nil
    tab.RankID = self.Rank.Value ~= self.Player.RankID and self.Rank.Value or nil

    if table.Count( tab ) < 1 then
      self:AnimateHide()
      return
    end

    tab.Player = self.Player.SteamID

    netmsg.Send( 'orgs.Menu.Members.Manage', tab )( function( tab )
      if tab[1] and IsValid( orgs.Menu ) then
        orgs.Menu:SetError( 'Failed to manage member because '.. orgs.ManageFails[tab[1]] )
        return
      end
      if IsValid( orgs.Menu ) then
        orgs.Menu:SetMsg( 'Successfully managed '.. ( self.Player.SteamID
          == LocalPlayer():SteamID64()
          and 'yourself'
          or self.Player.Nick )
        )
        orgs.Menu:Update()
      end
      self:AnimateHide()
    end )
  end

end

function PANEL:NewLine()

  local l = self.Body:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=10}, {l=25,r=25} )
  l:orgs_BGR( orgs.C_NONE )

  return l
end

vgui.Register( 'orgs.Menu.Members.Manage', PANEL, 'orgs.Popup' )
