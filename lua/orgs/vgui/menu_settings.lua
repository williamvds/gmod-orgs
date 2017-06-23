local PANEL = {}

function PANEL:Init()

  self.Leave = self:Add( 'DButton' )
  self.Leave:orgs_SetText( 'Leave group' )
  self.Leave:orgs_BGR( orgs.Colors.MenuButtonWarn, orgs.Colors.MenuButtonWarnAlt, 
    orgs.Colors.MenuButtonWarnAlt )
  self.Leave:orgs_Dock( BOTTOM, {l=235,r=235,u=5,d=5} )
  self.Leave:SetTall( 30 )
  self.Leave.DoClick = function()
    local p = orgs.Popup( 'Confirmation', 'Are you sure you want to leave your group? '
      ..'Your rank will be reset and you may not be able to rejoin.', {
        {'No'},
        {Label= 'Yes', Color= orgs.Colors.MenuButtonWarn, AltColor= orgs.Colors.MenuButtonWarnAlt,
          DoClick = function( b )
            netmsg.Send( 'orgs.LeaveOrg' )
            b.Popup:AnimateHide()
        end }
      } )
    p:SetSize( 200, 160 )
    --p:Center()
  end

end

vgui.Register( 'orgs.Menu.Settings', PANEL, 'EditablePanel' )

hook.Add( 'orgs.LeftOrg', '', function()
  if IsValid( orgs.Menu ) then orgs.Menu:AnimateHide() end
end )
