local PANEL = {}

function PANEL:Init()

  self.NoBulletin = self:orgs_AddLabel( 'No bulletin is currently set', 'orgs.Large' )
  self.NoBulletin:Dock( FILL )
  self.NoBulletin:SetContentAlignment( 5 )

  self.Text = self:Add( 'DTextEntry' )
  self.Text:orgs_SetText( '', 'orgs.SmallLight', orgs.Colors.Text )
  self.Text:SetVerticalScrollbarEnabled( true )
  self.Text:SetMultiline( true )
  self.Text:SetWrap( true )
  self.Text:SetCursor( 'arrow' )
  self.Text.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, self.Editing and orgs.Colors.Text or orgs.COLOR_NONE )
    p:DrawTextEntryText( self.Editing and orgs.Colors.MenuBackground or orgs.Colors.Text,
      orgs.Colors.MenuBackgroundAlt, orgs.Colors.MenuBackgroundAlt )
  end
  self.Text.AllowInput = function( p )
    return not self.Editing or p:GetText():len() +1 > orgs.MaxBulletinLength
  end

  self.Edit = self:Add( 'DButton' )
  self.Edit:orgs_SetText( 'Edit', 'orgs.Medium', orgs.Colors.Text, true )
  self.Edit:orgs_BGR( orgs.Colors.MenuPrimary, orgs.Colors.MenuPrimaryAlt )
  self.Edit:SetTall( 30 )
  self.Edit:SetVisible( false )
  self.Edit.DoClick = function()
    if not self.Editing then self.oldBulletin = self.Text:GetText() end
    self.Editing = not self.Editing

    self.Text:SetDisabled( not self.Editing )
    self.Text:SetVisible( self.Editing or (not self.Editing and self.Text:GetText() ~= '' ) )
    self.NoBulletin:SetVisible( self.Text:GetText() == '')

    self.Text:SetCursor( self.Editing and 'beam' or 'arrow' )
    self.Text:RequestFocus()
    self.Edit:SetText( self.Editing and 'Save' or 'Edit' )

    if not self.Editing and self.Text:GetText() ~= self.oldBulletin then
      netmsg.Send( 'orgs.Menu.Bulletin', {self.Text:GetText()} )( function( tab )
        if tab[1] then
          orgs.Menu:SetError( 'Something went wrong - '.. orgs.ModifyFails[tab[1]] )
        end
      end)
    end
  end

  -- TODO: Add 'last edited by' using event logs
end

function PANEL:PerformLayout()
  self.Text:Dock( FILL )
  self.Edit:orgs_Dock( BOTTOM, {l=265,r=265,u=5,d=5} )
end

function PANEL:Update( org )

  if not LocalPlayer():orgs_Has( orgs.PERM_BULLETIN ) and self.Edit:IsVisible() then
    if self.Editing then self.Edit:DoClick() end
    self.Edit:Hide() self:InvalidateLayout()
  elseif LocalPlayer():orgs_Has( orgs.PERM_BULLETIN ) and not self.Edit:IsVisible() then
    self.Edit:Show() self:InvalidateLayout()
  end

  if not self.Editing then self.Text:orgs_SetText( org.Bulletin ) end
  self.Text:SetVisible( org.Bulletin )
  self.NoBulletin:SetVisible( not org.Bulletin )

end

vgui.Register( 'orgs.Menu.Bulletin', PANEL, 'EditablePanel' )
