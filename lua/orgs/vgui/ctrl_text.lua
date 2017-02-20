local PANEL = {}
AccessorFunc( PANEL, 's_Text', 'Text' )
AccessorFunc( PANEL, 's_Font', 'Font' )
AccessorFunc( PANEL, 'c_Color', 'TextColor' )

function PANEL:Init()
  self:SetText( 'Text teat sd asdetasd' )
  self:SetFont( 'orgs.Medium' )
  self:SetTextColor( orgs.Colors.Text )
  self:SetSize( 200, 20 )
  local text = self:GetText()
  text = string.Explode( ' ', text )

  surface.SetFont( self:GetFont() )
  local lineW, lineH = 0, surface.GetTextSize( '█' )
  for k, v in pairs( text ) do
    local w = surface.GetTextSize( v )
    if lineW +w > self:GetWide() then
      table.insert( text, k, '\n' )
      lineW = 0
      break
    else lineW = lineW +w end
  end

  self.text = string.Explode( '\n', string.Implode( ' ', text ) )
  self.textH = (lineH +4) *(#text -1)
  self:SetTall( self.TextH )

end

function PANEL:Paint()

  for k, v in pairs( self.text ) do
    draw.SimpleText( v:gsub( '^ ', '' ), self:GetFont(), 0, (lineH +4) *(k-1),
      self:GetTextColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
  end

end

vgui.Register( 'orgs.Text', PANEL, 'DPanel' )
