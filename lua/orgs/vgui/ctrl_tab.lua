local PANEL = {}

function PANEL:Init()

  self.Header = self:Add( 'DPanel' )
  self.Header.Paint = function() end
  self.Header:SetTall( 25 )
  self.Header:Dock( TOP )

  self.Body = self:Add( 'DPanel' )
  self.Body:BGR( C_GRAY )
  self.Body:Dock( FILL )

  local bar = self:Add( 'DPanel' )
  bar:Dock( TOP, {u=5} )
  bar:MoveToFront()
  bar:SetTall( 3 )
  bar:BGR( C_BLUE )

  self.Tabs = {}
  self:Dock( FILL )

end

function PANEL:RepositionTabs()
  for k, tab in pairs( self.Tabs ) do
    tab.Tab:Dock( LEFT, nil, nil, true )
    tab.Tab:SetSize( tab.Tab:GetWide() +20, 45 )
  end
end

function PANEL:AddTab( name, panel, col, altCol, id )

  id = id or #self.Tabs +1

  local tab = self.Header:Add( 'DButton' )
  tab:SetText( name, 'orgs.Medium', C_WHITE )

  tab:SetContentAlignment( 5 )
  tab:BGR( col or C_DARKBLUE, altCol or C_BLUE )
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

  new.Tab:SetText( new.Name, _, C_DARKGRAY )
  new.Tab:BGR( C_WHITE )

  if self.ActiveTab == id then return end

  if old and IsValid( old.Panel ) then
    old.Tab:SetText( old.Name, _, C_WHITE )
    old.Tab:BGR( old.Color or C_DARKBLUE, old.AltColor or C_BLUE )
    old.Panel:Hide()
  end

  -- TODO: Transitional animations
  -- Possibly do logic in the TabMenu's Think hook instead of using in-built methods?

  -- if instant then
  --   new.Panel:Dock( FILL )
  --   new.Panel:Show()
  -- else

  --   local dir = self.ActiveTab > id and LEFT or RIGHT

  --   old.Panel:Stop()
  --   old.Panel:MoveTo( old.Panel:GetWide() +10, self.y, 2, _, _,
  --     function()

  --       old.Panel:Hide()

  --   end )

  --   if new.Panel.m_AnimList and #new.Panel.m_AnimList > 0 then
  --     new.Panel:Stop()
  --   else
  --     new.Panel:Dock( NODOCK )
  --     new.Panel:SetSize( self.Body:GetWide() -20, self.Body:GetTall() -10 )
  --     new.Panel.x = -new.Panel:GetWide()
  --     new.Panel:Show()
  --   end

  --   new.Panel:MoveTo( 10, new.Panel.y, 2, .1, _, function()
  --     new.Panel:Dock( FILL )
  --   end )

  -- end
  if new.Panel.OnTabActive then new.Panel:OnTabActive() end
  new.Panel:Show()
  self.ActiveTab = id

end

vgui.Register( 'orgs.TabMenu', PANEL )
