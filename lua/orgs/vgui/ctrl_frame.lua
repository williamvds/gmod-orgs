local HEADER = { Base = 'Panel' }

function HEADER:Init()
  self:orgs_Dock( TOP, nil, {r=5, l=5, d=5} )

  self.Title = self:orgs_AddLabel( 'Title', 'orgs.Medium' )
  self.Title:orgs_Dock( FILL, {l=5, r=self:GetParent():GetCloseWide()+5}, nil, true )
  self.Title:SetContentAlignment(4)
  self.Title:SetAutoStretchVertical( true )

  self.Close = self:Add( 'DButton' )
  self.Close:orgs_SetText( '✕', 'orgs.SmallLight', orgs.Colors.MenuText )
  self.Close:SetContentAlignment(8)
  self.Close:orgs_BGR( orgs.COLOR_NONE, orgs.Colors.Close )
  self.Close.DoClick = function() self:GetParent():AnimateHide() end
  self.Close:SetSize( self:GetParent():GetCloseWide(), 20 )

  self:SizeToChildren( true, true )
end

function HEADER:PerformLayout()
  self.Close:AlignRight()
end

function HEADER:Paint( w, h )
  orgs.DrawRect( 0, 0, w, h, self:GetParent():GetHeaderColor() )
end

function HEADER:Think()
  local p = self:GetParent()

  if self.Dragging then
    local mousex = math.Clamp( gui.MouseX(), 1, ScrW()-1 )
    local mousey = math.Clamp( gui.MouseY(), 1, ScrH()-1 )

    local x = math.Clamp( mousex -self.Dragging[1], 0, ScrW() -p:GetWide() )
    local y = math.Clamp( mousey -self.Dragging[2], 0, ScrH() -p:GetTall() )

    p:SetPos( x, y )
  end
end

function HEADER:OnMousePressed( code )
  if code ~= MOUSE_LEFT then return end

  self.Dragging = { gui.MouseX() -self:GetParent().x, gui.MouseY() -self:GetParent().y }
  self:SetCursor( 'sizeall' )
  self:MouseCapture( true )
end

function HEADER:OnMouseReleased( code )
  if code ~= MOUSE_LEFT then return end

  self.Dragging = nil
  self:SetCursor( 'arrow' )
  self:MouseCapture( false )
end

local FRAME = { Base = 'Panel' }

AccessorFunc( FRAME, 'c_main_color', 'Color' )
AccessorFunc( FRAME, 'c_header_color', 'HeaderColor' )
AccessorFunc( FRAME, 'b_drawbgblur', 'BackgroundBlur', FORCE_BOOL )
AccessorFunc( FRAME, 'b_remove_on_close', 'RemoveOnHide', FORCE_BOOL )
AccessorFunc( FRAME, 'n_close_button_wide', 'CloseWide', FORCE_NUMBER )

-- Automatically set the skin of child panels
local frameAdd = function( self, p )
  local new = FindMetaTable'Panel'.Add( self, p )
  if new.SetSkin then new:SetSkin( 'orgs' ) end
  new.Add = frameAdd

  return new
end

function FRAME:Init()
  self.Add = frameAdd

  self:SetSkin( 'orgs' )
  self:orgs_Dock( nil, nil, {r=5, l=5, d=5} )

  self._createdTime = SysTime()

  self:SetColor( orgs.Colors.MenuBackground )
  self:SetHeaderColor( orgs.COLOR_NONE )
  self:SetCloseWide( 40 )
  self:SetSize( 150, 100 )

  self.Header = self:Add( HEADER )
end

function FRAME:Paint( w, h )
  orgs.DrawRect( 0, 0, w, h, self:GetColor() )
  if self:GetBackgroundBlur() then
    Derma_DrawBackgroundBlur( self, self._createdTime )
  end
end

function FRAME:SetTitle( txt, font, color )
  self.Header.Title:orgs_SetText( txt, font, color, true )
  self.Header:SizeToChildren( true, true )
end

function FRAME:AnimateShow( done )

  self:Show()
  self:SetPos( ScrW()/2 -self:GetWide()/2, -self:GetTall() )
  self:MoveTo( ScrW()/2 -self:GetWide()/2, ScrH() /2 -self:GetTall() /2, .25, nil, nil,
    function()
      self:MakePopup()
      if done then done() end
    end )

end

function FRAME:AnimateHide( done )
  if self.Hiding then return end
  self.Hiding = true

  self:MoveTo( self.x, -self:GetTall(), .25, nil, nil,
    function( tab )
      self.Hiding = false
      self:Hide()
      if self:GetRemoveOnHide() then self:Remove() end
      if done then done() end
  end )

  CloseDermaMenus()
end

function FRAME:Think()
  if not self.NoEscape and input.IsKeyDown( KEY_ESCAPE ) then self:AnimateHide() end
end

vgui.Register( 'orgs.Frame', FRAME, 'EditablePanel' )
