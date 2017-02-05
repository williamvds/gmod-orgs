orgs = orgs or { List = {}, Loaded = {}, Ranks = {}, Members = {}, Invites = {}, Events = {} }

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
  'ORG_CREATED',
  'ORG_DESTROYED',
  'ORG_NAME',
  'ORG_MOTTO',
  'ORG_TAG',
  'ORG_COLOR',
  'ORG_BULLETIN',
  'ORG_DEFAULTRANK',
  'ORG_OPEN',
  'ORG_TYPE',
  'BANK_DEPOSIT',
  'BANK_WITHDRAW',
  'BANK_TRANSFER',
  'SALARY',
  'RANK_ADDED',
  'RANK_RENAME',
  'RANK_PERMS',
  'RANK_IMMUNITY',
  'RANK_BANKLIMIT',
  'RANK_BANKCOOLDOWN',
  'RANK_REMOVED',
  'INVITE',
  'INVITE_WITHDRAWN',
  'MEMBER_ADDED',
  'MEMBER_LEFT',
  'MEMBER_KICKED',
  'MEMBER_RANK',
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
  if ( k == 'Bulletin' or k == 'Balance' ) and tab.OrgID ~= ply:orgs_Org(0) then return end
  return v
end
netmsg.NetworkTable( orgs.List, 'orgs.List' )

local sameOrgIDFilter = function( tab, ply, k, v )
  if v == nil then return v end
  if ply:orgs_Org(0) ~= v.OrgID then return end
  return v
end

orgs.Ranks.__filter = sameOrgIDFilter
netmsg.NetworkTable( orgs.Ranks, 'orgs.Ranks' )

orgs.Members.__filter = sameOrgIDFilter
netmsg.NetworkTable( orgs.Members, 'orgs.Members' )

orgs.Events.__filter = function( tab, ply, k, v )
  if ply:orgs_Org(0) ~= v.OrgID or not ply:orgs_Has( orgs.PERM_EVENTS ) then return end
  return v
end

orgs.Invites.__filter = function( tab, ply, k, v )
  if ply:SteamID64() ~= tab.To
  and not ( ply:orgs_Org(0) == tab.OrgID and ply:orgs_Has( orgs.PERM_KICK ) ) then
    return
  end

  return v
end
netmsg.NetworkTable( orgs.Invites, 'orgs.Invites' )

if CLIENT then
  orgs.Events.__onKeySync = function( tab, k, v )
    if not v or not orgs.Menu or not orgs.Menu:IsVisible() then return end
    orgs.Menu:Update()
  end
end
netmsg.NetworkTable( orgs.Events, 'orgs.Events' )

if SERVER then include 'sv_init.lua' end
if CLIENT then include 'cl_init.lua' end
