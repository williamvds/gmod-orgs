local PANEL = {}

local function altButton( text, parent, right )

  local b = vgui.Create( 'DButton', parent )
  b:SetText( '' )
  b.Paint = function( b, w, h )
    surface.SetDrawColor( orgs.Colors.MenuBankAlt )
    if b.Active or (b.HollowOnHover and b:IsHovered()) then
      surface.DrawOutlinedRect( right and b:GetWide() -b:GetTall() or 0, 0, b:GetTall(),
        b:GetTall() )

    else

      surface.DrawRect( right and b:GetWide() -b:GetTall() or 0, 0, b:GetTall(), b:GetTall() )
    end
  end

  b.Label = b:orgs_AddLabel( text, 'orgs.Medium', orgs.Colors.MenuBankAlt )
  b.Label:orgs_Dock( right and RIGHT or LEFT, right and {r=30} or {l=30} )

  b:SizeToChildren( true, true )
  b:SetWide( b:GetWide() +b:GetTall() )

  return b
end

local function reset( self, tab )
  for k, v in pairs( tab ) do
    self[v].Active = false
  end
end

local bankActions = {'Deposit', 'Withdraw', 'Transfer'}
function PANEL:Init()
  self:orgs_BGR( orgs.Colors.MenuBank )

  self.BankName = self:orgs_AddLabel( string.upper(orgs.BankName), 'orgs.Large',
    orgs.Colors.MenuBankAlt )
  self.BankName:SetContentAlignment(5)
  self.BankName:orgs_Dock( TOP, {u=15} )

  self.AccountName = self:orgs_AddLabel( '', 'orgs.Medium', orgs.Colors.MenuBankAlt )
  self.AccountName:SetContentAlignment( 5 )
  self.AccountName:orgs_Dock( TOP, {u=-2} )

  self.Left = self:Add( 'DPanel' )
  self.Left:orgs_BGR( orgs.COLOR_NONE )
  self.Left:SetWide( 185 )
  self.Left:orgs_Dock( LEFT, nil, {l=15} )

  for k, v in pairs( bankActions ) do
    self[v] = altButton( v:upper(), self.Left )
    self[v].DoClick = function( b )
      self.Action = k
      self.ActionLabel:SetText( v:upper() )
      self.TransferTo:SetVisible( k == 3 )
      self:InvalidateLayout()
      reset( self, bankActions )
      b.Active = true
    end
    self[v]:orgs_Dock( TOP, {u=25} )

  end

  -- RIGHT PANEL

  self.Right = self:Add( 'DPanel' )
  self.Right:orgs_BGR( orgs.COLOR_NONE )
  self.Right:SetWide( 185 )
  self.Right:orgs_Dock( RIGHT, nil, {u=25,r=15} )

  for k, v in pairs( {Balance= 'Balance', In= 'Last 24 HR in', Out= 'Last 24 HR out'} ) do
    self[k ..'Label'] = self.Right:orgs_AddLabel( v:upper(), 'orgs.Small', orgs.Colors.MenuBankAlt )
    self[k ..'Label']:SetContentAlignment( 5 )
    self[k ..'Label']:Dock( TOP )
    self[k] = self.Right:orgs_AddLabel( '', 'orgs.Medium', orgs.Colors.MenuBankAlt )
    self[k]:SetContentAlignment( 5 )
    self[k]:orgs_Dock( TOP, {d=25} )
  end

  self.ActionLabel = self:orgs_AddLabel( 'DEPOSIT', 'orgs.Medium', orgs.Colors.MenuBankAlt )
  self.ActionLabel:SetContentAlignment( 5 )
  self.ActionLabel:orgs_Dock( TOP, {u=35} )

  self.TransferTo = self:Add( 'DComboBox' )
  self.TransferTo:orgs_Dock( TOP, {u=5,d=5,l=75,r=75} )
  self.TransferTo:orgs_BGR( orgs.Colors.MenuBankAlt )
  self.TransferTo.DropButton.Paint = function( p, w, h )
    surface.SetDrawColor( orgs.Colors.MenuBank )
    draw.NoTexture()
    surface.DrawPoly{
      {x=0, y=5}, {x=10, y=5}, {x=5, y=10}
    }
  end

  self.Value = self:Add( 'DTextEntry' )
  self.Value:SetFont( 'orgs.Medium' )
  self.Value:SetTall( 25 )
  self.Value:SetNumeric( true )
  self.Value:orgs_Dock( TOP, {u=5,l=75,r=75} )
  self.Value.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.Colors.MenuBankAlt )
    p:DrawTextEntryText( orgs.Colors.MenuBank, orgs.Colors.MenuBank, orgs.Colors.MenuBank )
  end
  self.Value.AllowInput = function( p, val )
    local num = tonumber( p:GetText() ..val )
    if not num and val ~= '' then return true end
    return num < 0
      or ( self.Action ~= 1 and num > LocalPlayer():orgs_Org().Balance )
      or ( self.Action == 1 and num > LocalPlayer():getDarkRPVar( 'money' )
          or num +LocalPlayer():orgs_Org().Balance
          > orgs.Types[LocalPlayer():orgs_Org().Type].MaxBalance )
  end

  -- Set active button
  self.Deposit:DoClick()

  self.Send = altButton( 'OK', self, true )
  self.Send.HollowOnHover = true
  self.Send:orgs_Dock( TOP, {u=10,l=185,r=75} )
  self.Send:SetZPos( 1 ) -- Fixes panel order when they are hidden/shown depending on mode
  self.Send.DoClick = function()
    local val = self.Value:GetText() ~= '' and tonumber( self.Value:GetText() ) or 0
    if self.Action ~= 1 and not LocalPlayer():orgs_Has( orgs.PERM_WITHDRAW )
    or self.Action == 1 and not orgs.CanAfford( LocalPlayer(), val )
    or val < 1
    then return end

    netmsg.Send( 'orgs.Menu.Bank.'.. bankActions[self.Action],
    {Val= val, To= self.Action == 3 and self.TransferTo.Value or nil} ) ( function( tab )
      if tab[1] then
        orgs.Menu:SetError( 'Transfer failed because '..
          ( tab[1] == true and 'something went wrong' or orgs.ModifyFails[tab[1]] ) )
      return end
    end )

    self.Value:RequestFocus()
  end
  self.Value.OnEnter = self.Send.DoClick

end

function PANEL:Update( org )

  self.AccountName:SetText( 'ACCOUNT: '.. string.upper( org.Name ) )
  self.Balance:SetText( orgs.FormatCurrency( org.Balance ) )

  local withdrawPerm = LocalPlayer():orgs_Has( orgs.PERM_WITHDRAW )
  orgs.DebugLog( 'menu_bank: Local player PERM_WITHDRAW = ', tostring( withdrawPerm ) )
  self.Deposit:SetVisible( withdrawPerm )
  self.Withdraw:SetVisible( withdrawPerm )
  self.Transfer:SetVisible( withdrawPerm )

  if not withdrawPerm then
    self.Deposit:DoClick()
  end

  local eventPerm = LocalPlayer():orgs_Has( orgs.PERM_EVENTS )
  orgs.DebugLog( 'menu_bank: Local player PERM_EVENTS = ', tostring( eventPerm ) )
  self.InLabel:SetVisible( eventPerm )
  self.In:SetVisible( eventPerm )
  self.OutLabel:SetVisible( eventPerm )
  self.Out:SetVisible( eventPerm )

  if not eventPerm then return end

  local inVal, outVal, inTab, outTab = 0, 0,
    TruthTable( {orgs.EVENT_BANK_DEPOSIT} ),
    TruthTable( {orgs.EVENT_SALARY, orgs.EVENT_BANK_WITHDRAW} )

  for k, event in pairs( netmsg.safeTable( orgs.Events, true ) ) do
      if event.Time < os.time() -86400 then continue end -- Only last 24hr

      if inTab[event.Type] then inVal = inVal +tonumber( event.ActionValue )
      elseif outTab[event.Type] then outVal = outVal +tonumber( event.ActionValue )
      elseif event.Type == orgs.EVENT_BANK_TRANSFER then
        outVal = outVal +( event.OrgID == org.OrgID and event.ActionValue or 0 )
        inVal = inVal +( event.OrgID == org.OrgID and event.ActionValue or 0 )
      end
  end

  self.In:SetText( orgs.FormatCurrency( inVal ) )
  self.Out:SetText( orgs.FormatCurrency( outVal ) )

end

vgui.Register( 'orgs.Menu.Bank', PANEL, 'EditablePanel' )
