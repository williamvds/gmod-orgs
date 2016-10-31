local PANEL = {}

local function altButton( text, parent, right )

  local b = vgui.Create( 'DButton', parent )
  b:SetText( '' )
  b.Paint = function( b, w, h )
    surface.SetDrawColor( C_GREEN )
    if b.Active or (b.HollowOnHover and b:IsHovered()) then
      surface.DrawOutlinedRect( right and b:GetWide() -b:GetTall() or 0, 0, b:GetTall(),
        b:GetTall() )

    else

      surface.DrawRect( right and b:GetWide() -b:GetTall() or 0, 0, b:GetTall(), b:GetTall() )
    end
  end

  b.Label = b:AddLabel( text, 'orgs.Medium', C_GREEN )
  b.Label:Dock( right and RIGHT or LEFT, right and {r=30} or {l=30} )

  b:SizeToChildren( true, true )
  b:SetWide( b:GetWide() +b:GetTall() )

  return b
end

local bankActions = {'Deposit', 'Withdraw', 'Transfer'}
local successMsg = {
  [1] = 'Deposited %s into the group\'s account',
  [2] = 'Withdrew %s from the group\'s account',
  [3] = 'Transferred %s to %s\'s account',
}
function PANEL:Init()
  self:BGR( C_DARKGREEN )
  self.Action = 1

  self.BankName = self:AddLabel( string.upper(orgs.BankName), 'orgs.Large', C_GREEN )
  self.BankName:SetContentAlignment(5)
  self.BankName:Dock( TOP, {u=5} )

  self.AccountName = self:AddLabel( '', 'orgs.Medium', C_GREEN )
  self.AccountName:SetContentAlignment( 5 )
  self.AccountName:Dock( TOP, {u=-2} )

  self.Left = self:Add( 'DPanel' )
  self.Left:BGR( C_NONE )
  self.Left:SetWide( 145 )
  self.Left:Dock( LEFT, nil, {l=15} )

  self.Deposit = altButton( 'DEPOSIT', self.Left )
  self.Deposit:Dock( TOP, {u=25} )
  self.Deposit.DoClick = function( b )
    b.Active, self.Action = true, 1
    self.ActionLabel:SetText( 'DEPOSIT' )
    self.TransferTo:Hide()
    self:InvalidateLayout()
    self.Withdraw.Active, self.Transfer.Active = false, false
  end
  self.Deposit:Dock( TOP, {u=25} )
  self.Deposit.Active = true

  self.Withdraw = altButton( 'WITHDRAW', self.Left )
  self.Withdraw.DoClick = function( b )
    b.Active, self.Action = true, 2
    self.ActionLabel:SetText( 'WITHDRAW' )
    self.TransferTo:Hide()
    self:InvalidateLayout()
    self.Deposit.Active, self.Transfer.Active = false, false
  end
  self.Withdraw:Dock( TOP, {u=20} )

  self.Transfer = altButton( 'TRANSFER', self.Left )
  self.Transfer.DoClick = function( b )
    b.Active, self.Action = true, 3
    self.ActionLabel:SetText( 'TRANSFER' )
    self.TransferTo:Show()
    self:InvalidateLayout()
    self.Deposit.Active, self.Withdraw.Active = false, false
  end
  self.Transfer:Dock( TOP, {u=20} )

  -- RIGHT PANEL

  self.Right = self:Add( 'DPanel' )
  self.Right:BGR( C_NONE )
  self.Right:SetWide( 145 )
  self.Right:Dock( RIGHT, nil, {r=15} )

  self.BalanceLabel = self.Right:AddLabel( 'BALANCE', 'orgs.Small', C_GREEN )
  self.BalanceLabel:SetContentAlignment( 5 )
  self.BalanceLabel:Dock( TOP )
  self.Balance = self.Right:AddLabel( '', 'orgs.Medium', C_GREEN )
  self.Balance:SetContentAlignment( 5 )
  self.Balance:Dock( TOP, {d=15} )

  self.InLabel = self.Right:AddLabel( 'LAST 24 HR IN', 'orgs.Small', C_GREEN )
  self.InLabel:SetContentAlignment( 5 )
  self.InLabel:Dock( TOP )
  self.In = self.Right:AddLabel( '', 'orgs.Medium', C_GREEN )
  self.In:SetContentAlignment( 5 )
  self.In:Dock( TOP, {d=15} )

  self.OutLabel = self.Right:AddLabel( 'LAST 24 HR OUT', 'orgs.Small', C_GREEN )
  self.OutLabel:SetContentAlignment( 5 )
  self.OutLabel:Dock( TOP )
  self.Out = self.Right:AddLabel( '', 'orgs.Medium', C_GREEN )
  self.Out:SetContentAlignment( 5 )
  self.Out:Dock( TOP, {d=15} )

  self.ActionLabel = self:AddLabel( 'DEPOSIT', 'orgs.Medium', C_GREEN )
  self.ActionLabel:SetContentAlignment( 5 )
  self.ActionLabel:Dock( TOP, {u=35} )

  self.TransferTo = self:Add( 'orgs.ComboBox' )
  self.TransferTo.Color = C_GREEN
  self.TransferTo.AltColor = C_DARKGREEN
  self.TransferTo:Hide()
  self.TransferTo:Dock( TOP, {u=5,d=5,l=50,r=50} )

  self.Value = self:Add( 'DTextEntry' )
  self.Value:SetFont( 'orgs.Medium' )
  self.Value:SetTall( 25 )
  self.Value:SetNumeric( true )
  self.Value:Dock( TOP, {u=5,l=50,r=50} )
  self.Value.Paint = function( p, w, h )
    DrawRect( 0, 0, w, h, C_GREEN )
    p:DrawTextEntryText( C_DARKGREEN, C_DARKGREEN, C_DARKGREEN )
  end
  self.Value.AllowInput = function( p, val )
    num = tonumber( p:GetText() ..val )
    if not num and val ~= '' then return true end
    return num < 0 or ( self.Action ~= 1 and num > LocalPlayer():orgs_Org().Balance )
      or ( self.Action == 1 and num > LocalPlayer():getDarkRPVar('money') )
  end

  self.Send = altButton( 'OK', self, true )
  self.Send.HollowOnHover = true
  self.Send:Dock( TOP, {u=10,l=185,r=50} )
  self.Send:SetZPos( 1 ) -- Fixes panel order when they are hidden/shown depending on mode
  self.Send.DoClick = function()
    local val = self.Value:GetText() ~= '' and tonumber( self.Value:GetText() ) or 0
    if self.Action ~= 1 and not LocalPlayer():orgs_Has( orgs.PERM_WITHDRAW )
    or self.Action == 1 and not orgs.CanAfford( LocalPlayer(), val )
    or val < 1
    then return end

    netmsg.Send( 'orgs.Menu.Bank.'.. bankActions[self.Action],
      {Val= val, To= (self.Action == 2 and self.TransferTo.Value or nil)} )( function( tab )
        if tab[1] or not IsValid( orgs.Menu ) then return end
        orgs.Menu:SetMsg( successMsg[self.Action] %{
          orgs.FormatCurrencyShort( self.Value:GetText() ),
          -- TODO: Format the transfer target
          } )
        -- orgs.Menu:Update()
      end )
    self.Value:RequestFocus()
  end

  self.Value.OnEnter = self.Send.DoClick
end

function PANEL:Update( org )

  self.AccountName:SetText( 'ACCOUNT: '.. string.upper( org.Name ) )
  self.Balance:SetText( orgs.FormatCurrency( org.Balance ) )

  local withdrawPerm = LocalPlayer():orgs_Has( orgs.PERM_WITHDRAW )
  self.Deposit:SetVisible( withdrawPerm )
  self.Withdraw:SetVisible( withdrawPerm )
  self.Transfer:SetVisible( withdrawPerm )

  local eventPerm = LocalPlayer():orgs_Has( orgs.PERM_EVENTS )
  self.InLabel:SetVisible( eventPerm )
  self.In:SetVisible( eventPerm )
  self.OutLabel:SetVisible( eventPerm )
  self.Out:SetVisible( eventPerm )

  if not eventPerm then return end

  local inVal, outVal, inTab, outTab = 0, 0,
    TruthTable( {orgs.EVENT_BANK_DEPOSIT} ),
    TruthTable( {orgs.EVENT_SALARY, orgs.EVENT_BANK_WITHDRAW} )

  for k, event in pairs( safeTable( orgs.Events, true ) ) do
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
