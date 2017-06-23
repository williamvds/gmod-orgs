local PANEL = {}

function PANEL:Init()
  self:orgs_Frame()
  self:SetSize( 200, 150 )
  self:SetDrawOnTop( true )
  self:SetRemoveOnHide( true )
  self:SetBackgroundBlur( true )

  self.Body = self:Add( 'DPanel' )
  self.Body:orgs_Dock( FILL, {u=5,d=5,l=5,r=5}, {u=5,d=5,l=5,r=5} )

  self:AnimateShow( function() self:SetDrawOnTop( false ) end )
end
vgui.Register( 'orgs.Popup', PANEL, 'DFrame' )

function orgs.Popup( title, text, buttons )
  if buttons and not istable( buttons ) then buttons = {buttons} end

  local p = vgui.Create( 'orgs.Popup' )
  p:SetTitle( title or '' )
  if text then
    p.Label = p.Body:orgs_AddLabel( text, 'orgs.Small' )
    p.Label:orgs_Dock( FILL, {u=5} )
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
      b:orgs_SetText( tab[1] or tab.Label or '', 'orgs.Medium', orgs.Colors.MenuTextAlt )
      b:orgs_Dock( k %2 == 0 and RIGHT or LEFT, {l= k %2 == 0 and 0 or 15,
        r= k %2 == 0 and 15 or 0, u=5, d=5} )
      b.DoClick = tab.DoClick or function() p:AnimateHide() end
      b.Popup = p
    end
  end

  return p
end
