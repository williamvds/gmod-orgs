local PANEL = {}

function PANEL:Init()
  local org, l = LocalPlayer():orgs_Org()
  self:SetSize( 400, 385 )
  self:SetTitle( 'Change group type' )
  self:AnimateShow()

  l = self:NewLine()
  l:orgs_Dock( TOP, {d=10} )
  self.TypeLabel =  l:orgs_AddLabel( 'Change to', 'orgs.Medium', orgs.Colors.Text )
  self.TypeLabel:Dock( LEFT )
  self.TypeLabel:SetContentAlignment( 8 )
  --self.TypeLabel:SetWide( 90 )

  self.Type = l:Add( 'orgs.ComboBox' )
  self.Type:orgs_Dock( LEFT, {l=15} )
  self.Type:SetSize( 150, 25 )
  self.Type.OnSelect = function( p, id )
    local tp = orgs.Types[p.Value]
    self.Price:orgs_SetText( orgs.FormatCurrency( tp.Price ), nil,
      orgs.CanAfford( LocalPlayer(), tp.Price ) and orgs.Colors.Text or orgs.Colors.Error )
    self.WalletWarning.l:SetVisible( not orgs.CanAfford( LocalPlayer(), tp.Price ) )

    self.MembersRequired:orgs_SetText( tp.MembersRequired, nil,
      org.Members < tp.MembersRequired and orgs.Colors.Error or orgs.Colors.Text )
    if org.Members < tp.MembersRequired then
      self.MembersRequired:SetText( self.MembersRequired:GetText()
        ..' - you have too few members!' )
    end

    self.MaxMembers:orgs_SetText( tp.MaxMembers, nil,
      org.Members > tp.MaxMembers and orgs.Colors.Error or orgs.Colors.Text )
    if org.Members > tp.MaxMembers then
      self.MaxMembers:orgs_SetText( self.MaxMembers:GetText()
        ..' - you have too many members!' )
    end

    self.MaxBalance:orgs_SetText( tp.MaxBalance, nil,
      org.Members > tp.MaxBalance and orgs.Colors.Error or orgs.Colors.Text )
    if org.Members > tp.MaxBalance then
      self.MaxBalance:SetText( self.MaxMembers:GetText()
        ..' - you have too much money in your bank, it will be lost!' )
    end

    self.MaxBalance:orgs_SetText( orgs.FormatCurrency( tp.MaxBalance ), nil,
      org.Balance > tp.MaxBalance and orgs.Colors.Error or orgs.Colors.Text )
    self.BankWarning.l:SetVisible( org.Balance > tp.MaxBalance )

    self.Tax:SetText( tp.Tax *100 ..'%' )

    self.CanAlly:orgs_SetText( tp.CanAlly and 'Yes' or 'No', nil,
      true and orgs.Colors.Text or orgs.Colors.Error ) -- TODO: Check alliances once implemeneted

    self.CanHide:orgs_SetText( tp.CanHide and 'Yes' or 'No', nil,
      true and orgs.Colors.Text or orgs.Colors.Error ) -- TODO: Check hiding once implemeneted

    self.Body:InvalidateLayout()
  end

  for k, tp in pairs( orgs.Types ) do
    if k == LocalPlayer():orgs_Org().Type then continue end
    self.Type:AddOption( tp.Name, k, tp.Price )
  end

  for k, v in pairs( {{'Price','Cost to change'}, {'WalletWarning'},
    {'MembersRequired','Members required'}, {'MaxMembers','Member limit'},
    {'MaxBalance','Maximum bank balance'}, {'BankWarning'}, {'Tax','Salary tax'},
    {'CanAlly','Can ally'}, {'CanHide','Can hide from public'}} ) do

    l = self:NewLine()
    if v[2] then
      self[v[1] ..'Label'] = l:orgs_AddLabel( v[2] ..':', 'orgs.MediumLight', orgs.Colors.Text )
      self[v[1] ..'Label']:orgs_Dock( LEFT, {l=10} )
      self[v[1] ..'Label']:SetContentAlignment( 9 )
    end
    self[v[1]] = l:orgs_AddLabel( '', 'orgs.Small', orgs.Colors.Text )
    self[v[1]]:orgs_Dock( LEFT, {l=5} )
    self[v[1]]:SetContentAlignment( 4 )
    self[v[1]]:SetWide( 500 )
    self[v[1]].l = l
  end
  self.WalletWarning:orgs_SetText( 'You don\'t have enough money in your wallet to pay!', nil,
    orgs.Colors.Error )
  self.WalletWarning.l:orgs_Dock( TOP, {u=0} )
  self.WalletWarning.l:Hide()

  self.BankWarning:orgs_SetText( 'You have too much money in the bank - some will be lost!', nil,
    orgs.Colors.Error )
  self.BankWarning.l:orgs_Dock( TOP, {u=0} )
  self.BankWarning.l:Hide()

  self.Type:Select( 1 )

  self.Confirm = self.Body:Add( 'DButton' )
  self.Confirm:orgs_BGR( orgs.Colors.MenuPrimary, orgs.Colors.MenuPrimaryAlt )
  self.Confirm:orgs_Dock( BOTTOM, {l=150,r=150} )
  self.Confirm:SetTall( 30 )
  self.Confirm:orgs_SetText( 'Confirm', 'orgs.Medium', orgs.Colors.Text )
  self.Confirm.DoClick = function( p )
    local tp = self.Type.Value
    netmsg.Send( 'orgs.Menu.Manage.Edit', {Type= self.Type.Value} )( function( tab )
      if tab[1] then
        orgs.Menu:SetError( 'Failed to upgrade group - '.. orgs.ModifyFails[tab[1]] )
        return
      end
      self:AnimateHide()
    end )
  end
end

function PANEL:NewLine()

  local l = self.Body:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=5}, {l=10,r=10} )
  l:orgs_BGR( orgs.COLOR_NONE )

  return l
end

vgui.Register( 'orgs.Menu.Manage_Upgrade', PANEL, 'orgs.Popup' )
