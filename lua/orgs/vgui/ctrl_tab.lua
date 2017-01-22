local PANEL = {}

function PANEL:Init()

  self.Header = self:Add( 'DPanel' )
  self.Header.Paint = function() end
  self.Header:SetTall( 25 )
  self.Header:Dock( TOP )

  self.Body = self:Add( 'DPanel' )
  self.Body:orgs_BGR( orgs.C_GRAY )
  self.Body:Dock( FILL )

  local bar = self:Add( 'DPanel' )
  bar:orgs_Dock( TOP, {u=5} )
  bar:MoveToFront()
  bar:SetTall( 3 )
  bar:orgs_BGR( orgs.C_BLUE )

  self.Tabs = {}
  self:Dock( FILL )

end

function PANEL:RepositionTabs()
  for k, tab in pairs( self.Tabs ) do
    tab.Tab:orgs_Dock( LEFT, nil, nil, true )
    tab.Tab:SetSize( tab.Tab:GetWide() +20, 45 )
  end
end

function PANEL:AddTab( name, panel, col, altCol, id )

  id = id or #self.Tabs +1

  local tab = self.Header:Add( 'DButton' )
  tab:orgs_SetText( name, 'orgs.Medium', orgs.C_WHITE )

  tab:SetContentAlignment( 5 )
  tab:orgs_BGR( col or orgs.C_DARKBLUE, altCol or orgs.C_BLUE )
  tab.DoClick = function( tab ) self:SetActiveTab( id ) end
  tab.ID = id

  panel:SetParent( self.Body )
  panel:Dock( FILL )
  panel:Hide()

  self.Tabs[id] = { Name= name, Panel= panel, Tab= tab, Color= col, AltColor= altCol }
  self:RepositionTabs()

  if #self.Tabs == 1 then self:SetActiveTab( next( self.Tabs ) ) end
  return panel, self.Tabs[id]
end

function PANEL:RemoveTab( tab )

  if ispanel( tab ) then
    for k, v in pairs( self.Tabs ) do
      if v.Panel == tab then tab = k break end
    end
  end

  tab = self.Tabs[tab]
  tab.Tab:Remove()
  tab.Panel:Remove()
  self.Tabs[tab] = nil

  if self.Tabs[self.ActiveTab] == tab then
    self:SetActiveTab( next( self.Tabs ) )
  end

  self:RepositionTabs()

end

function PANEL:HideTab( tab )

  if ispanel( tab ) then
    for k, v in pairs( self.Tabs ) do
      if v.Panel == tab then tab = k break end
    end
  end

  if self.ActiveTab == tab then
    for k, v in pairs( self.Tabs ) do
      if k ~= tab then self:SetActiveTab(k) end
    end
  end
  self.Tabs[tab].Tab:Hide()
  self:RepositionTabs()

end

function PANEL:ShowTab( tab )

  if ispanel( tab ) then
    for k, v in pairs( self.Tabs ) do
      if v.Panel == tab then tab = k break end
    end
  end

  self.Tabs[tab].Tab:Show()
  self:RepositionTabs()

end

function PANEL:GetTabs() return self.Tabs end
function PANEL:GetTab( id ) return self.Tabs[id] end

function PANEL:GetActiveTab() return self:GetTab( self.ActiveTab ) end

function PANEL:SetActiveTab( id )
  local id = id or next(self.Tabs)
  local old, new = self:GetActiveTab(), self:GetTab( id )

  new.Tab:orgs_SetText( new.Name, _, orgs.C_DARKGRAY )
  new.Tab:orgs_BGR( orgs.C_WHITE )

  if self.ActiveTab == id then return end

  if old and IsValid( old.Panel ) then
    old.Tab:orgs_SetText( old.Name, _, orgs.C_WHITE )
    old.Tab:orgs_BGR( old.Color or orgs.C_DARKBLUE, old.AltColor or orgs.C_BLUE )

    local alpha1 = old.Panel:GetAlpha()
    old.Panel:AlphaTo( 0, .075, 0, function()
      self.ActiveTab = id
      old.Panel:Hide()
      old.Panel:SetAlpha( alpha1 )
      local alpha2 = new.Panel:GetAlpha()
      if new.Panel.OnTabActive then new.Panel:OnTabActive() end
      self.ActiveTab = id
      new.Panel:SetAlpha( 0 )
      new.Panel:Show()
      new.Panel:AlphaTo( alpha2, .075, 0 )
    end )
  else
    local alpha2 = new.Panel:GetAlpha()
    if new.Panel.OnTabActive then new.Panel:OnTabActive() end
    self.ActiveTab = id
    new.Panel:SetAlpha( 0 )
    new.Panel:Show()
    new.Panel:AlphaTo( alpha2, .075, 0 )
  end

end

vgui.Register( 'orgs.TabMenu', PANEL )
