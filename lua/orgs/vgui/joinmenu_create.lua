local PANEL = {}

function PANEL:Init()

  self:DockPadding( 5, 0, 5, 15 )

  self.Desc = self:orgs_AddLabel( 'Create your own group for free', 'orgs.Small' )
  self.Desc:orgs_Dock( TOP, {u=75} )
  self.Desc:SetContentAlignment(5) -- TODO: Fix alignment?

  local l = self:NewLine()
  self.OrgNameLabel = l:orgs_AddLabel( 'Group name' )
  self.OrgNameLabel:Dock( LEFT )

  self.OrgName = l:Add( 'DTextEntry' )
  self.OrgName:SetWide( 225 )
  self.OrgName:orgs_Dock( LEFT, {l=15} )

  l = self:NewLine()
  l:SetTall( 22 )

  self.PublicLabel = l:orgs_AddLabel( 'Public ', 'orgs.Medium' )
  self.PublicLabel:SetTall( 22 )
  self.PublicLabel:orgs_Dock( LEFT, {r=10} )
  self.PublicLabel:SetContentAlignment(6)
  self.PublicLabel:SetMouseInputEnabled( true )

  self.Public = l:Add( 'DCheckBox' )
  self.Public:Dock( LEFT )
  self.Public:SetSize( 22, 22 )
  self.PublicLabel.DoClick = function() self.Public:Toggle() end

  self.CreateButton = self:Add( 'DButton' )
  self.CreateButton:orgs_SetText( 'Create group', 'orgs.Medium', orgs.Colors.MenuTextAlt )
  self.CreateButton:SetContentAlignment( 5 )
  self.CreateButton:orgs_Dock( BOTTOM, {l=230,r=230} )
  self.CreateButton:SetTall( 30 )
  self.CreateButton:SetDisabled( LocalPlayer():orgs_Info() )
  self.CreateButton.DoClick = function( p )
    p:SetDisabled( true )

    netmsg.Send( 'orgs.JoinMenu.Create', {Name= self.OrgName:GetValue(),
      Public= self.Public:GetChecked() or nil} )( function( tab )
      if tab[1] then
        orgs.JoinMenu:SetError( 'Couldn\'t create group because ' .. orgs.ModifyFails[ tab[1] ] )
      end

      p:SetDisabled( false )
    end )

  end

  self.OrgName.OnEnter = function() self.CreateButton:DoClick() end
end

function PANEL:NewLine()

  local l = self:Add( 'DPanel' )
  l:orgs_Dock( TOP, {u=10}, {l=75,r=25} )

  return l
end

function PANEL:Update()

  self.OrgName:SetValue( '' )
  self.Public:SetValue( false )
  self.CreateButton:SetDisabled( false )

end

vgui.Register( 'orgs.JoinMenu_Create', PANEL )

hook.Add( 'orgs.JoinedOrg', 'orgs.JoinedOrg', function()
  if not orgs.JoinMenu then return end

  orgs.JoinMenu:AnimateHide( function()
    orgs.Menu = vgui.Create( 'orgs.Menu' )
  end )

end )
