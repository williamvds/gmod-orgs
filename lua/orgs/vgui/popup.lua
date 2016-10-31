local PANEL = {}

function PANEL:Init()
  self:SetSize( 200, 150 )
  self:SetDrawOnTop( true )
  self:SetRemoveOnHide( true )

  self.Header.Title:SetContentAlignment(5)

  self.Body = self:Add( 'DPanel' )
  self.Body:BGR( C_GRAY )
  self.Body:Dock( FILL, nil, {u=5,d=5,l=5,r=5} )

  self:AnimateShow( function() self:SetDrawOnTop( false ) end )
end
vgui.Register( 'orgs.Popup', PANEL, 'orgs.Frame' )


function orgs.Popup( title, text, buttons )
  if buttons and not istable( buttons ) then buttons = {buttons} end

  local p = vgui.Create( 'orgs.Popup' )
  p.Header.Title:SetText( title or '' )
  if text then
    p.Label = p.Body:AddLabel( text, 'orgs.Small', C_WHITE )
    p.Label:Dock( FILL, {u=5} )
    p.Label:SetContentAlignment( 5 )
    p.Label:SetAutoStretchVertical( true )
    p.Label:SetWrap( true )
  end

  if buttons then
    local bPnl = p.Body:Add( 'DPanel' )
    bPnl.Paint = function() end
    bPnl:SetTall( 35 )
    bPnl:Dock( BOTTOM )

    for k, tab in pairs( buttons ) do
      local b = bPnl:Add( 'DButton' )
      b:SetText( tab[1] or tab.Label or '', 'orgs.Medium', C_WHITE )
      b:Dock( (k %2 == 0 and RIGHT or LEFT), {l= (k %2 == 0 and 0 or 15),
        r= (k %2 == 0 and 15 or 0),u=5,d=5} )
      b.DoClick = tab.DoClick or function() p:AnimateHide() end
      b:BGR( tab.Color or C_DARKBLUE, tab.AltColor or C_BLUE )
      b.Popup = p
    end
  end

  return p
end
