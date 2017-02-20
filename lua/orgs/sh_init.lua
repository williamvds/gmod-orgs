orgs = orgs or { List = {}, Loaded = {}, Ranks = {}, Members = {}, Invites = {}, Events = {},
  Colors= {} }

if SERVER then
  AddCSLuaFile 'vendor/sh_vercas_von.lua'
  AddCSLuaFile 'vendor/sh_box_netmsg.lua'
  AddCSLuaFile 'CONFIG.lua'
end
include 'vendor/sh_vercas_von.lua'
include 'vendor/sh_box_netmsg.lua'
include 'sh_util.lua'

-- Event enumerations
Enum( orgs, 'EVENT_', {
  'ORG_CREATE',
  'ORG_REMOVE',
  'ORG_EDIT',
  'BANK_DEPOSIT',
  'BANK_WITHDRAW',
  'BANK_TRANSFER',
  'SALARY',
  'RANK_ADD',
  'RANK_REMOVE',
  'RANK_EDIT',
  'INVITE',
  'INVITE_WITHDRAW',
  'MEMBER_JOIN',
  'MEMBER_LEAVEKICK',
  'MEMBER_EDIT',
} )

-- Permission enumerations
Enum( orgs, 'PERM_', {
  'INVITE',   -- Can invite players
  'BULLETIN', -- Can change bulletin
  'WITHDRAW', -- Can transfer money
  'PROMOTE',  -- Can promote or demote players, or alter their permissions
  'KICK',     -- Can kick members
  'RANKS',    -- Can modify ranks
  'MODIFY',   -- Can modify name, motto, tag, color
  'EVENTS',   -- View the actions of other members
} )

include 'CONFIG.lua'

Msg( string.rep( '\n', 3 ) )
orgs.Log( false, 'Loading Organisations...' )

if game.SinglePlayer() then
  orgs.LogError( false, 'Organisations cannot run in a single-player game!' )
  return
end

orgs.AddMoney = function() end
orgs.CanAfford = function() end

hook.Add( 'DarkRPFinishedLoading', 'orgs.DarkRPCompat', function()
  orgs.CurrencySymbol = GM.Config.currency
  orgs.CurrencySymbolLeft = GM.Config.currencyLeft
  orgs.CanAfford = FindMetaTable'Player'.canAfford
  orgs.AddMoney = FindMetaTable'Player'.addMoney
  if SERVER then
    DarkRP.defineChatCommand( orgs.Command, function( ply )
      if orgs._Provider.Failed then
        orgs.ChatLog( ply, 'Organisations couldn\'t connect to the database - '
          ..'please warn an admin as soon as possible!' )
        return ''
      end

      netmsg.Send( 'orgs.OpenMenu', nil, ply )
      return ''
    end )
  end
  DarkRP.declareChatCommand{
    command= orgs.Command,
    description= 'Open the menu to manage or join a group.',
    delay= 1
  }
end )

orgs.List.__subFilter = function( tab, ply, k, v )
  if v == nil then return nil end

  if ( k == 'Bulletin' or k == 'Balance' ) and tab.OrgID ~= ply:orgs_Org(0) then return end
  return v
end
netmsg.NetworkTable( orgs.List, 'orgs.List' )

local sameOrgIDFilter = function( tab, ply, k, v )
  if v == nil then return nil end

  if ply:orgs_Org(0) ~= v.OrgID then return end
  return v
end

orgs.Ranks.__filter = sameOrgIDFilter
netmsg.NetworkTable( orgs.Ranks, 'orgs.Ranks' )

orgs.Members.__filter = sameOrgIDFilter
netmsg.NetworkTable( orgs.Members, 'orgs.Members' )

orgs.Events.__filter = function( tab, ply, k, v )
  local steamID = ply:SteamID64()

  -- Allow event sync if player has perms or was the actor/victim
  if ply:orgs_Org(0) ~= v.OrgID or
  ( not ply:orgs_Has( orgs.PERM_EVENTS )
    and ( v.ActionBy and v.ActionBy ~= steamID )
    and ( v.ActionAgainst and v.ActionAgainst ~= steamID )
  ) then return end

  return v
end

orgs.Invites.__filter = function( tab, ply, k, v )
  if v == nil then return nil end

  if ply:SteamID64() ~= tab.To
  and not ( ply:orgs_Org(0) == tab.OrgID and ply:orgs_Has( orgs.PERM_KICK ) ) then
    return
  end

  return v
end
netmsg.NetworkTable( orgs.Invites, 'orgs.Invites' )

if CLIENT then
  orgs.Events.__onKeySync = function( tab, k, v )
    local string
    if v and v.Time > os.time() -5 then
      string = orgs.EventToString( table.Copy( v ), true )
      orgs.ChatLog( unpack( string ) )
    end

    if IsValid( orgs.Menu ) and orgs.Menu:IsVisible() then
      if string then orgs.Menu:SetMsg( table.concat( string ) ) end
      orgs.Menu:Update()
    end

  end
end
netmsg.NetworkTable( orgs.Events, 'orgs.Events' )

if SERVER then include 'sv_init.lua' end
if CLIENT then include 'cl_init.lua' end
