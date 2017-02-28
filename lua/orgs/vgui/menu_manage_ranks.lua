local PANEL = {}

function PANEL:Init()
  self.Lines = {}
  self:Dock( FILL )

  self.List = self:Add( 'DListView' )
  self.List:orgs_Dock( FILL, {l=-1,r=-3} )
  self.List:SetHeaderHeight( 25 )
  self.List:SetDataHeight( 24 )
  self.List:SetMultiSelect( false )

  self.Desc = self:orgs_AddLabel( 'Manage ranks by double clicking them',
    'orgs.Small' )
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
  end

  local oldAddLine = vgui.GetControlTable( 'DListView' ).AddLine

  -- List AddLine
  self.List.AddLine = function( p, rank, ... )
    local tab, text = {...}, {}
    for k, v in pairs( tab ) do text[k] = istable(v) and v[1] or v end

    local l = oldAddLine( p, unpack{...} )
    l.Rank = rank.RankID

    for k, v in pairs( tab ) do
      if istable(v) and v[2] then l:SetSortValue( k, v[2] ) end
    end

    self.Lines[ rank.RankID ] = l

    return l
  end

  -- List OnRowRightClick
  self.List.OnRowRightClick = function( p, id, line )

    CloseDermaMenus()
    self.Popup = self:Add( 'DMenu' )

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

          self.List:RemoveLine( id )
        end )

      end )

    end

    self.Popup:AddOption( 'Add new rank', function()
      vgui.Create( 'orgs.Menu.Manage_Ranks.Edit' )
    end )

    self.Popup:Open()
  end
  self.List.DoDoubleClick = self.List.OnRowRightClick

end

function PANEL:Update( org )

  for k, l in pairs( self.List.Lines ) do
    if not orgs.Ranks[l.Rank] then self.List:RemoveLine( k ) end
  end

  for k, rank in pairs( netmsg.safeTable( orgs.Ranks, true ) ) do
    if self.Lines[ rank.RankID ] then
      local l = self.Lines[ rank.RankID ]
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

  self.NameLabel = l:orgs_AddLabel( 'Name' )
  self.NameLabel:orgs_Dock( LEFT, {l=35} )
  self.NameLabel:SetWide( 80 )
  self.NameLabel:SetContentAlignment( 6 )

  self.Name = l:Add( 'DTextEntry' )
  self.Name:orgs_Dock( LEFT, {l=15} )
  self.Name:SetSize( 150, 25 )
  self.Name:orgs_SetText( self.Rank.Name )

  l = self:NewLine()

  self.ImmunityLabel = l:orgs_AddLabel( 'Immunity' )
  self.ImmunityLabel:orgs_Dock( LEFT, {l=35} )
  self.ImmunityLabel:SetWide( 80 )
  self.ImmunityLabel:SetContentAlignment( 6 )

  self.Immunity = l:Add( 'DTextEntry' )
  self.Immunity:orgs_Dock( LEFT, {l=15} )
  self.Immunity:SetSize( 35, 25 )
  self.Immunity:SetText( '0' )
  self.Immunity:SetNumeric( true )
  self.Immunity:orgs_SetText( self.Rank.Immunity )

  l = self:NewLine()

  self.PermsLabel = l:Add( 'DLabel' )
  self.PermsLabel:orgs_SetText( 'Permissions' )
  self.PermsLabel:orgs_Dock( LEFT, {l=-15}, nil, true )

  l = self:NewLine()

  for k, v in pairs( orgs.PermCheckboxes ) do
    self[v[1]] = l:Add( 'DCheckBoxLabel' )
    local box, perm = self[v[1]], orgs['PERM_'.. string.upper( v[1] )]
    box:Dock( k %2 ~= 0 and LEFT or RIGHT )
    box.Label:orgs_SetText( v[2], 'orgs.Small' )
    box.Label:orgs_Dock( LEFT, {l=20} )
    box.Label:SetContentAlignment(4)
    if k %2 ~= 0 then box:SizeToContents()
    else box:SetWide( 150 ) end

    if self.Rank.RankID then
      box:SetChecked( orgs.RankHas( self.Rank.RankID, perm ) )
    end
    box:SetDisabled( not LocalPlayer():orgs_Has( perm ) )

    if k %2 == 0 then l = self:NewLine() end
  end

  self.WithdrawLabel = l:orgs_AddLabel( 'Withdraw limit' )
  self.WithdrawLabel:orgs_Dock( LEFT, {l=-15} )
  self.WithdrawLabel:SetWide( 120 )
  self.WithdrawLabel:SetContentAlignment( 8 )

  self.BankLimit = l:Add( 'DTextEntry' )
  self.BankLimit:orgs_Dock( LEFT, {l=15} )
  self.BankLimit:SetSize( 85, 25 )
  self.BankLimit:SetNumeric( true )
  self.BankLimit:orgs_SetText( self.Rank.BankLimit )

  self.WithdrawLabel2 = l:orgs_AddLabel( 'every' )
  self.WithdrawLabel2:orgs_Dock( LEFT, {l=5} )
  self.WithdrawLabel2:SetWide( 45 )
  self.WithdrawLabel2:SetContentAlignment( 8 )
  self.WithdrawLabel2:SetZPos( 1 )

  self.BankCooldown = l:Add( 'DTextEntry' )
  self.BankCooldown:orgs_Dock( LEFT, {l=5} )
  self.BankCooldown:SetSize( 25, 25 )
  self.BankCooldown:SetNumeric( true )
  self.BankCooldown:orgs_SetText( self.Rank.BankCooldown )
  self.BankCooldown:SetZPos( 2 )

  self.WithdrawLabel3 = l:orgs_AddLabel( 'mins' )
  self.WithdrawLabel3:orgs_Dock( LEFT, {l=5} )
  self.WithdrawLabel3:SetWide( 40 )
  self.WithdrawLabel3:SetContentAlignment( 8 )
  self.WithdrawLabel3:SetZPos( 3 )

  self.Save = self.Body:Add( 'DButton' )
  self.Save:orgs_Dock( BOTTOM, {l=150,r=150} )
  self.Save:SetTall( 30 )
  self.Save:orgs_SetText( 'Save' )
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

        self:AnimateHide()
      end )

    else
      netmsg.Send( 'orgs.Menu.Manage.AddRank', tab )( function( res )
        if res[1] and IsValid( orgs.Menu ) then
          orgs.Menu:SetError( 'Failed to add rank' )
          return
        end

        self:AnimateHide()
      end )

    end
  end

end

function PANEL:NewLine()

  local l = self.Body:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=10}, {l=25,r=25} )
  l:orgs_BGR( orgs.COLOR_NONE )

  return l
end

vgui.Register( 'orgs.Menu.Manage_Ranks.Edit', PANEL, 'orgs.Popup' )
