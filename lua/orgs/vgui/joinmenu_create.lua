local PANEL = {}

function PANEL:Init()

  self:DockPadding( 5, 0, 5, 15 )

  self.Desc = self:AddLabel( 'Create your own group for free', 'orgs.Small' )
  self.Desc:Dock( TOP, {u=75} )
  self.Desc:SetContentAlignment(5) -- TODO: Fix alignment?

  local l = self:NewLine()
  self.OrgNameLabel = l:AddLabel( 'Group name', 'orgs.Medium' )
  self.OrgNameLabel:Dock( LEFT )

  self.OrgName = l:Add( 'DTextEntry' )
  self.OrgName:SetWide( 225 )
  self.OrgName:SetFont( 'orgs.Medium' )
  self.OrgName:Dock( LEFT, {l=15} )
  self.OrgName.Paint = function( p, w, h )
    DrawRect( 0, 0, w, h, C_WHITE )
    p:DrawTextEntryText( C_DARKGRAY, C_GRAY, C_GRAY )
  end

  l = self:NewLine()
  l:SetTall( 22 )

  self.PublicLabel = l:AddLabel( 'Public ', 'orgs.Medium', C_WHITE )
  self.PublicLabel:SetTall( 22 )
  self.PublicLabel:Dock( LEFT, {r=10} )
  self.PublicLabel:SetContentAlignment(6)
  self.PublicLabel:SetMouseInputEnabled( true )

  self.Public = l:Add( 'DCheckBox' )
  self.Public:Dock( LEFT )
  self.Public:SetSize( 22, 22 )
  self.Public.Paint = function( p, w, h )
    DrawRect( 0, 0, w, h, p:GetDisabled() and C_LIGHTGRAY  or C_BLUE )
    DrawRect( 3, 3, w -6, h -6, p:GetChecked() and C_LIGHTGREEN or C_DARKRED )
  end

  self.PublicLabel.DoClick = function() self.Public:Toggle() end

  self.CreateButton = self:Add( 'DButton' )
  self.CreateButton:SetText( 'Create group', 'orgs.Medium', C_WHITE )
  self.CreateButton:SetContentAlignment( 5 )
  self.CreateButton:SetDrawBorder( false )
  self.CreateButton:BGR( C_DARKBLUE, C_BLUE )
  self.CreateButton:Dock( BOTTOM, {l=230,r=230} )
  self.CreateButton:SetTall( 30 )
  self.CreateButton.DoClick = function( p )
    p:SetDisabled( true )
    p:BGR( C_LIGHTGRAY )
    netmsg.Send( 'orgs.CreateGroup', {Name= self.OrgName:GetValue(),
      Public= self.Public:GetChecked() or nil} )
  end

  self.OrgName.OnEnter = function() self.CreateButton:DoClick() end
end

function PANEL:NewLine()

  local l = self:Add( 'DPanel' )
  l:Dock( TOP, {u=10}, {l=75,r=25} )
  l:BGR( C_NONE )

  return l
end

function PANEL:Update()

  self.OrgName:SetValue( '' )
  self.Public:SetValue( false )
  self.CreateButton:BGR( C_BLUE )
  self.CreateButton:SetDisabled( false )

end

vgui.Register( 'orgs.JoinMenu_Create', PANEL )

hook.Add( 'orgs.JoinedOrg', 'orgs.JoinedOrg', function()
  if not orgs.JoinMenu then return end

  orgs.JoinMenu:AnimateHide( function()
    orgs.Menu = vgui.Create( 'orgs.Menu' )
  end )

end )
