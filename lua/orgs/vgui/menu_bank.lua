local PANEL = {}

local function altButton( text, parent, right )

  local b = vgui.Create( 'DButton', parent )
  b:SetText( '' )
  b.Paint = function( b, w, h )
    surface.SetDrawColor( orgs.C_GREEN )
    if b.Active or (b.HollowOnHover and b:IsHovered()) then
      surface.DrawOutlinedRect( right and b:GetWide() -b:GetTall() or 0, 0, b:GetTall(),
        b:GetTall() )

    else

      surface.DrawRect( right and b:GetWide() -b:GetTall() or 0, 0, b:GetTall(), b:GetTall() )
    end
  end

  b.Label = b:orgs_AddLabel( text, 'orgs.Medium', orgs.C_GREEN )
  b.Label:orgs_Dock( right and RIGHT or LEFT, right and {r=30} or {l=30} )

  b:SizeToChildren( true, true )
  b:SetWide( b:GetWide() +b:GetTall() )

  return b
end

local bankActions = {'Deposit', 'Withdraw', 'Transfer'}
local successMsg = {
  'Deposited %s into the group\'s account',
  'Withdrew %s from the group\'s account',
  'Transferred %s to %s\'s account',
}
function PANEL:Init()
  self:orgs_BGR( orgs.C_DARKGREEN )
  self.Action = 1

  self.BankName = self:orgs_AddLabel( string.upper(orgs.BankName), 'orgs.Large', orgs.C_GREEN )
  self.BankName:SetContentAlignment(5)
  self.BankName:orgs_Dock( TOP, {u=15} )

  self.AccountName = self:orgs_AddLabel( '', 'orgs.Medium', orgs.C_GREEN )
  self.AccountName:SetContentAlignment( 5 )
  self.AccountName:orgs_Dock( TOP, {u=-2} )

  self.Left = self:Add( 'DPanel' )
  self.Left:orgs_BGR( orgs.C_NONE )
  self.Left:SetWide( 185 )
  self.Left:orgs_Dock( LEFT, nil, {l=15} )

  self.Deposit = altButton( 'DEPOSIT', self.Left )
  self.Deposit:orgs_Dock( TOP, {u=25} )
  self.Deposit.DoClick = function( b )
    b.Active, self.Action = true, 1
    self.ActionLabel:SetText( 'DEPOSIT' )
    self.TransferTo:Hide()
    self:InvalidateLayout()
    self.Withdraw.Active, self.Transfer.Active = false, false
  end
  self.Deposit:orgs_Dock( TOP, {u=25} )
  self.Deposit.Active = true

  self.Withdraw = altButton( 'WITHDRAW', self.Left )
  self.Withdraw.DoClick = function( b )
    b.Active, self.Action = true, 2
    self.ActionLabel:SetText( 'WITHDRAW' )
    self.TransferTo:Hide()
    self:InvalidateLayout()
    self.Deposit.Active, self.Transfer.Active = false, false
  end
  self.Withdraw:orgs_Dock( TOP, {u=20} )

  self.Transfer = altButton( 'TRANSFER', self.Left )
  self.Transfer.DoClick = function( b )
    b.Active, self.Action = true, 3
    self.ActionLabel:SetText( 'TRANSFER' )
    self.TransferTo:Show()
    self:InvalidateLayout()
    self.Deposit.Active, self.Withdraw.Active = false, false
  end
  self.Transfer:orgs_Dock( TOP, {u=20} )

  -- RIGHT PANEL

  self.Right = self:Add( 'DPanel' )
  self.Right:orgs_BGR( orgs.C_NONE )
  self.Right:SetWide( 185 )
  self.Right:orgs_Dock( RIGHT, nil, {u=25,r=15} )

  self.BalanceLabel = self.Right:orgs_AddLabel( 'BALANCE', 'orgs.Small', orgs.C_GREEN )
  self.BalanceLabel:SetContentAlignment( 5 )
  self.BalanceLabel:Dock( TOP )
  self.Balance = self.Right:orgs_AddLabel( '', 'orgs.Medium', orgs.C_GREEN )
  self.Balance:SetContentAlignment( 5 )
  self.Balance:orgs_Dock( TOP, {d=25} )

  self.InLabel = self.Right:orgs_AddLabel( 'LAST 24 HR IN', 'orgs.Small', orgs.C_GREEN )
  self.InLabel:SetContentAlignment( 5 )
  self.InLabel:Dock( TOP )
  self.In = self.Right:orgs_AddLabel( '', 'orgs.Medium', orgs.C_GREEN )
  self.In:SetContentAlignment( 5 )
  self.In:orgs_Dock( TOP, {d=25} )

  self.OutLabel = self.Right:orgs_AddLabel( 'LAST 24 HR OUT', 'orgs.Small', orgs.C_GREEN )
  self.OutLabel:SetContentAlignment( 5 )
  self.OutLabel:Dock( TOP )
  self.Out = self.Right:orgs_AddLabel( '', 'orgs.Medium', orgs.C_GREEN )
  self.Out:SetContentAlignment( 5 )
  self.Out:orgs_Dock( TOP, {d=25} )

  self.ActionLabel = self:orgs_AddLabel( 'DEPOSIT', 'orgs.Medium', orgs.C_GREEN )
  self.ActionLabel:SetContentAlignment( 5 )
  self.ActionLabel:orgs_Dock( TOP, {u=35} )

  self.TransferTo = self:Add( 'orgs.ComboBox' )
  self.TransferTo.Color = orgs.C_GREEN
  self.TransferTo.AltColor = orgs.C_DARKGREEN
  self.TransferTo:Hide()
  self.TransferTo:orgs_Dock( TOP, {u=5,d=5,l=75,r=75} )

  self.Value = self:Add( 'DTextEntry' )
  self.Value:SetFont( 'orgs.Medium' )
  self.Value:SetTall( 25 )
  self.Value:SetNumeric( true )
  self.Value:orgs_Dock( TOP, {u=5,l=75,r=75} )
  self.Value.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_GREEN )
    p:DrawTextEntryText( orgs.C_DARKGREEN, orgs.C_DARKGREEN, orgs.C_DARKGREEN )
  end
  self.Value.AllowInput = function( p, val )
    num = tonumber( p:GetText() ..val )
    if not num and val ~= '' then return true end
    return num < 0 or ( self.Action ~= 1 and num > LocalPlayer():orgs_Org().Balance )
      or ( self.Action == 1 and num > LocalPlayer():getDarkRPVar('money') )
  end

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
      {Val= val, To= (self.Action == 2 and self.TransferTo.Value or nil)} )( function( tab )
        if tab[1] or not IsValid( orgs.Menu ) then return end
        orgs.ChatLog( successMsg[self.Action] %{
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
