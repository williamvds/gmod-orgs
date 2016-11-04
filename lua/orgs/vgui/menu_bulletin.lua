local PANEL = {}

function PANEL:Init()

  self.NoBulletin = self:orgs_AddLabel( [[No bulletin is currently set]],
    'orgs.Large' )
  self.NoBulletin:Dock( FILL )
  self.NoBulletin:SetContentAlignment( 5 )

  self.Text = self:Add( 'DTextEntry' )
  self.Text:orgs_SetText( '', 'orgs.SmallLight', orgs.C_WHITE )
  self.Text:SetVerticalScrollbarEnabled( true )
  self.Text:SetDrawBackground( false )
  self.Text:SetSkin( 'orgs.blankTextBox' )
  self.Text:SetMultiline( true )
  self.Text:SetWrap( true )
  self.Text:SetCursor( 'arrow' )
  self.Text.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, p.Editing and orgs.C_WHITE or orgs.C_NONE )
    p:DrawTextEntryText( p.Editing and orgs.C_DARKGRAY or orgs.C_WHITE, orgs.C_GRAY, orgs.C_GRAY )
  end
  self.Text.AllowInput = function( p )
    return not p.Editing or p:GetText():len() +1 > orgs.MaxBulletinLength
  end -- Don't ask me why it's true to prevent input

  self.Edit = self:Add( 'DButton' )
  self.Edit:orgs_SetText( 'Edit', 'orgs.Medium', orgs.C_WHITE, true )
  self.Edit:orgs_BGR( orgs.C_DARKBLUE, orgs.C_BLUE )
  self.Edit:SetTall( 30 )
  self.Edit:SetVisible( false )
  self.Edit.DoClick = function()
    if not self.Text.Editing then self.oldBulletin = self.Text:GetText() end
    self.Text.Editing = not self.Text.Editing

    self.Text:SetSkin( self.Text.Editing and 'Default' or 'orgs.blankTextBox' )
    self.Text:SetDrawBackground( self.Text.Editing and true or false )
    self.Text:SetTextColor( self.Text.Editing and orgs.C_GRAY or orgs.C_WHITE )
    self.Text:SetCursor( self.Text.Editing and 'hand' or 'arrow' )
    self.Text:RequestFocus()
    self.Edit:SetText( self.Text.Editing and 'Save' or 'Edit' )

    self.NoBulletin:SetVisible( not self.Text.Editing
      and not self.Text:GetText() or self.Text:GetText() == '' )
    self.Text:SetVisible( self.Text.Editing or self.Text:GetText() and self.Text:GetText() ~= ''  )

    if not self.Text.Editing and self.Text:GetText() ~= self.oldBulletin then
      netmsg.Send( 'orgs.Menu.Bulletin', {self.Text:GetText()} )( function( tab )
        if tab[1] then
          self.Text:SetText( self.oldBulletin )
          orgs.Menu:SetError( 'Something went wrong - '..
            (tab[1] == 11 and 'the bulletin is too long!'
            or 'you don\'t have permission to change the bulletin!') )
        else
          orgs.Menu:SetMsg( 'Edited the bulletin successfully' )
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
    if self.Text.Editing then self.Edit:DoClick() end
    self.Edit:Hide() self:InvalidateLayout()
  elseif LocalPlayer():orgs_Has( orgs.PERM_BULLETIN ) and not self.Edit:IsVisible() then
    self.Edit:Show() self:InvalidateLayout()
  end

  self.Text:orgs_SetText( org.Bulletin )
  self.Text:SetVisible( org.Bulletin and org.Bulletin ~= '' )
  self.NoBulletin:SetVisible( not org.Bulletin or org.Bulletin == '')

end

vgui.Register( 'orgs.Menu.Bulletin', PANEL, 'EditablePanel' )
