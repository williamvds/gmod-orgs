local Panel = FindMetaTable( 'Panel' )

function Panel:orgs_SetText( txt, font, col, resize )

  if txt then self:SetText( txt ) end
  if font then self:SetFont( font ) end
  if col then self:SetTextColor( col ) end
  if resize then self:SizeToContents() end

end

function Panel:orgs_AddLabel( text, font, col, wrap, noresize )
  local l = self:Add( 'DLabel' )

  if wrap then
    l:SetWrap( true )
    l:SetAutoStretchVertical( true )
  end
  l:orgs_SetText( text, font, col or orgs.C_WHITE, not noresize )

  return l
end

function Panel:orgs_Dock( dir, m, p, resize )

  self:Dock( dir or NODOCK )
  if m then self:DockMargin( m.l or 0, m.u or 0, m.r or 0, m.d or 0 ) end
  if p then self:DockPadding( p.l or 0, p.u or 0, p.r or 0, p.d or 0 ) end
  if resize then self:SizeToContents() end

end

function Panel:Debug()

  self.oldPaint = self.Paint
  self.Paint = function( self, w, h )
    orgs.DrawRect( 0, 0, w, h, orgs.C_RED )
    if self.oldPaint then self:oldPaint( w, h ) end
  end

end

function Panel:orgs_BGR( col, hover, depressed )

  self.Paint = function( self, w, h )
    local col = ( depressed and self.IsDown() ) and depressed or ( hover and self:IsHovered() ) and hover or col
    orgs.DrawRect( 0, 0, w, h, col )
  end

end

local SKIN = {}
SKIN.colNumberWangBG = orgs.C_WHITE
SKIN.control_color_bright = orgs.C_WHITE
SKIN.tooltip = orgs.C_WHITE
derma.DefineSkin( 'orgs.default', '', SKIN )

SKIN = {}
SKIN.colTextEntryTextHighlight  = orgs.C_NONE
SKIN.colTextEntryTextCursor = orgs.C_NONE

derma.DefineSkin( 'orgs.blankTextBox', '', SKIN )
