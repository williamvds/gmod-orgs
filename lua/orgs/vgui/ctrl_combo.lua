local COMBOBOX = {}

function COMBOBOX:Init()

  self.Options = {}

  self:SetFont( 'orgs.Medium' )
  self:SetTextColor( orgs.C_DARKGRAY )
  self:SetText( '' )
  self:SetContentAlignment( 4 )
  self:SetTextInset( 4, 0 )
  self.Paint = function( p, w, h )
    orgs.DrawRect( 0, 0, w, h, self.Color or orgs.C_WHITE )
  end

  self.Arrow = self:Add( 'DPanel' )
  self.Arrow:SetMouseInputEnabled( false )
  self.Arrow:orgs_Dock( RIGHT, {r=8, u=10} )
  self.Arrow:SetSize( 10, 10 )
  self.Arrow.Paint = function( p, w, h )
    surface.SetDrawColor( p:GetParent().AltColor or orgs.C_DARKGRAY )
    draw.NoTexture()
    surface.DrawPoly{
      {x=0, y=0}, {x=10, y=0}, {x=5, y=5}
    }
  end

end

function COMBOBOX:ShowList()

  self.List = self:Add( 'DScrollPanel' )
  self.List:SetWide( self:GetWide() )
  --self.List.VBar.Paint = self.List.VBar:orgs_BGR( orgs.C_WHITE )

  self.List.Think = function()

    local x, y = self:ScreenToLocal( gui.MouseX(), gui.MouseY() )
    if x < 0 or x > self:GetWide() then self.List:Remove() end
    if y < 0 or y > self:GetTall() +1 +self.List:GetTall() then self.List:Remove() end

    self.List:SetPos( self:LocalToScreen( 0, self:GetTall() +1 ) )

  end

  local tab = {}
  for k, v in pairs( self.Options ) do
    tab[k] = {v.Label,v.SortValue or v.Label,k}
  end
  table.SortByMember( tab, 2, true )

  for id, opt in ipairs( tab ) do
    local label = self.List:orgs_AddLabel( opt[1], 'orgs.Medium', orgs.C_DARKGRAY )
    label:orgs_BGR( orgs.C_WHITE, orgs.C_LIGHTGRAY )
    label:SetContentAlignment( 4 )
    label:SetTextInset( 4, 0 )
    label.DoClick = function() self:Select( opt[3] ) end
    label:Dock( TOP )

    self.List:AddItem( label )

    if id < 4 then self.List:SetTall( label:GetTall() *3 ) end
  end

  self.List:SetDrawOnTop( true )
  self.List:SetFocusTopLevel( true )
  self.List:MakePopup()

end

function COMBOBOX:Select( id )
  if IsValid( self.List ) then self.List:Remove() end

  self:orgs_SetText( self.Options[id].Label )
  self.Value = self.Options[id].Value

  if self.OnSelect then self:OnSelect( id ) end
end

function COMBOBOX:OnRemove()
  if IsValid( self.List ) then self.List:Remove() end
end

function COMBOBOX:DoClick()
  if IsValid( self.List ) then self.List:Remove()
  else self:ShowList() end
end

function COMBOBOX:AddOptions( tab )
  for k, v in pairs( tab ) do
    if istable( v ) then table.insert( self.Options, {Label= v[1], Value= v[2], SortValue= v[3]} )
    else table.insert( self.Options, {Label= v, Value= v} ) end
  end
end

function COMBOBOX:AddOption( label, value, sortValue )
  table.insert( self.Options, {Label= label, Value= value and value or label, SortValue= sortValue} )
end

vgui.Register( 'orgs.ComboBox', COMBOBOX, 'DButton' )
