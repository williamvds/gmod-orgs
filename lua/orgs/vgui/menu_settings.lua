local PANEL = {}

function PANEL:Init()

  self.Leave = self:Add( 'DButton' )
  self.Leave:SetText( 'Leave group', 'orgs.Medium', C_WHITE, true )
  self.Leave:BGR( C_DARKRED, C_RED )
  self.Leave:Dock( BOTTOM, {l=235,r=235,u=5,d=5} )
  self.Leave:SetTall( 30 )
  self.Leave.DoClick = function()
    local p = orgs.Popup( 'Confirmation', 'Are you sure you want to leave your group? '
      ..'Your rank will be reset and you may not be able to rejoin.', {
        {'No'},
        {Label= 'Yes', Color= C_DARKRED, AltColor= C_RED,
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
  if orgs.Menu then orgs.Menu:AnimateHide() end
end )
