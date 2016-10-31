local menuSize = {600,400}
local bodyHeight = menuSize[2] -100
local statsWidth = 242
local mottoWidth = menuSize[1] -statsWidth -15

local PANEL = {}

function PANEL:Init()
  self:SetSize( unpack(menuSize) )
  self:DockPadding( 5, 0, 5, 5 )
  self.Org = LocalPlayer():orgs_Org()

  self.Header.Title:Remove()
  self.Header:SetTall( 35 )

  self.ColorCube = self.Header:Add( 'DPanel' )
  self.ColorCube.Color = C_WHITE
  self.ColorCube.Paint = function( p, w, h )
    DrawRect( 0, 0, w, h, C_WHITE )
    DrawRect( 1, 1, w -2, h -2, p.Color )
  end
  self.ColorCube:SetSize( 20, 20 )
  self.ColorCube:SetPos( 0, 7 )

  self.Name = self.Header:AddLabel( '', 'orgs.Large', C_WHITE )
  self.Name:Dock( LEFT, {l=20,u=2}, _, true )
  self.Name:SetAutoStretchVertical( true )

  self.Tag = self.Header:AddLabel( '', 'orgs.Large', C_WHITE )
  self.Tag:Dock( LEFT, {l=5,u=2}, _, true )

  self.Motto = self:AddLabel( '', 'orgs.Small', C_WHITE, true )
  -- self.Motto:SetContentAlignment( 4 ) TODO: Change to 7?
  self.Motto:SetWide( mottoWidth )
  self.Motto:Dock( LEFT )

  self.Divider = self:Add( 'DPanel' )
  self.Divider:SetTall( 4 )
  self.Divider:MoveToBack()
  self.Divider:Dock( BOTTOM )
  self.Divider:BGR( C_BLUE )

  self.Body = self:Add( 'DPanel' )
  self.Body:MoveToBack()
  self.Body:SetTall( bodyHeight )
  self.Body:Dock( BOTTOM )
  self.Body:BGR( C_DARKGRAY )

  self.TabMenu = self.Body:Add( 'orgs.TabMenu' )
  self.Bulletin = self.TabMenu:AddTab( 'BULLETIN', vgui.Create( 'orgs.Menu.Bulletin' ) )
  self.Members = self.TabMenu:AddTab( 'MEMBERS', vgui.Create( 'orgs.Menu.Members' ) )
  self.Bank = self.TabMenu:AddTab( 'BANK', vgui.Create( 'orgs.Menu.Bank' ) )
  self.Manage = self.TabMenu:AddTab( 'MANAGE', vgui.Create( 'orgs.Menu.Manage' ),
    nil, nil, 'manage' )
  self.TabMenu:AddTab( 'SETTINGS', vgui.Create( 'orgs.Menu.Settings' ) )

  self.Msg = self:AddLabel( '', 'orgs.Small', C_WHITE )
  self.Msg:Hide()
  self.Msg:SetContentAlignment( 5 )
  self.Msg:MoveToBack()
  self.Msg:Dock( BOTTOM, {u=2} )

  self:BuildStats()
  self:Update()
  self:AnimateShow()

end

function PANEL:BuildStats()

  if not self.Stats then

    self.Stats = self:Add( 'DPanel' )
    self.Stats:SetSize( statsWidth )
    self.Stats:Dock( RIGHT, nil, {l=5} )
    self.Stats:BGR( C_DARKBLUE )

    self.StatTab = {
      { label = 'RANK', func = function()
        local tab = safeTable( orgs.List, true )

        local rank = 0
        for k, v in SortedPairsByMemberValue( tab, 'Balance', true ) do
          rank = rank +1
          if v.OrgID == self.Org.OrgID then return tostring( rank ) end
        end

        return '0'
      end },
      { label = 'BALANCE', func = function()
        return orgs.FormatCurrencyShort( self.Org.Balance )
      end },
      { label = 'MEMBERS', func = function() return table.Count( orgs.Members ) -1 end },
    }

    for k, stat in pairs( self.StatTab ) do

      local pnl = self.Stats:Add( 'DPanel' )
      pnl:BGR( C_DARKBLUE )
      pnl:Dock( LEFT, {r=5} )
      pnl:SetWide( (statsWidth/#self.StatTab) -5 -(3/#self.StatTab) )

      pnl.Label = pnl:AddLabel( stat.label, 'orgs.Small', C_WHITE )
      pnl.Label:Dock( TOP, {u=9} )
      pnl.Label:SetContentAlignment( 5 )

      pnl.Value = pnl:AddLabel( '', 'orgs.Medium', C_WHITE )
      pnl.Value:Dock( TOP )
      pnl.Value:SetContentAlignment( 5 )
      self.Stats[ stat.label ] = pnl

    end

  else
    for k, stat in pairs( self.StatTab ) do
      self.Stats[ stat.label ].Value:SetText( stat.func() )
    end
  end

end

function PANEL:Update()

  self.Org = LocalPlayer():orgs_Org()
  if not self.Org then return end
  self.Org = table.Copy( self.Org ) self.Org.__tabID = nil

  self.Name:SetText( self.Org.Name, _, _, true )
  self.ColorCube.Color = istable( self.Org.Color ) and self.Org.Color
    or Color( unpack( string.Explode( ',', self.Org.Color ) ) )
  self.Tag:SetText( self.Org.Tag and '['..self.Org.Tag..']' or '', nil, nil, true )
  self.Motto:SetText( self.Org.Motto or '' )
  self:BuildStats()

  if not LocalPlayer():orgs_Has( orgs.PERM_MODIFY )
  and not LocalPlayer():orgs_Has( orgs.PERM_EVENTS )
  and not LocalPlayer():orgs_Has( orgs.PERM_RANK )
  and self.TabMenu.Tabs['manage'].Tab:IsVisible() then
    self.TabMenu:HideTab( 'manage' )
  elseif LocalPlayer():orgs_Has( orgs.PERM_MODIFY )
  or LocalPlayer():orgs_Has( orgs.PERM_EVENTS )
  or LocalPlayer():orgs_Has( orgs.PERM_RANK )
  and not self.TabMenu.Tabs['manage'].Tab:IsVisible() then
    self.TabMenu:ShowTab( 'manage' )
  end

  for k, tab in pairs( self.TabMenu.Tabs ) do
    if tab.Panel.Update then tab.Panel:Update( self.Org ) end
  end

end

function PANEL:SetMsg( text, col, time )
  time = time or 4

  if text == '' then
    self.Msg:AlphaTo( 0, .3, 0, function()
      self:SetTall( menuSize[2] )
      self.Msg:Hide()
    end )
    return

  else orgs.ChatLog( col, text ) end

  self:SetTall( menuSize[2] +self.Msg:GetTall() +2 )

  if self.Msg:IsVisible() then
    self.Msg:AlphaTo( 0, .2, 0, function()
      self.Msg:SetText( text )
      self.Msg:SetTextColor( col or C_WHITE )
      self.Msg:AlphaTo( 255, .2, 0 )
    end )

  else
    self.Msg:SetTextColor( col or C_WHITE )
    self.Msg:SetText( text )
    self.Msg:SetAlpha( 0 )
    self.Msg:Show()
    self.Msg:AlphaTo( 255, .3, 0 )

  end

  if timer.Exists( 'orgs.Menu.HideMsg' ) then
    timer.Adjust( 'orgs.Menu.HideMsg', time, 0 )
    timer.Start( 'orgs.Menu.HideMsg' )

  else
    timer.Create( 'orgs.Menu.HideMsg', time, 0, function()
      if IsValid( orgs.Menu ) then orgs.Menu:SetMsg( '' ) end
      timer.Stop( 'orgs.Menu.HideMsg' )
    end )

  end

end

function PANEL:SetError( text, time )
  self:SetMsg( text, C_RED, time )
end

vgui.Register( 'orgs.Menu', PANEL, 'orgs.Frame' )

concommand.Add( 'orgs_newmenu', function()
  orgs.Menu = vgui.Create( 'orgs.Menu' )
end )
