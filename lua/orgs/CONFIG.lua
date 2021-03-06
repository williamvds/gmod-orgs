--[[ This file allows you to change the addon as you want, and should be the only file you touch
  unless you're using MySQL ]]

--[[ The data store used by the server. Can be 'mysql'
  If you're using MySQL, ensure you have defined the connection settings in ./providers/mysql.lua ]]
orgs.Provider = 'mysql'

-- The chat command prefix (DarkRP has its own setting)
orgs.CommandPrefix = '/'

-- Command to open the orgs menu
orgs.Command = 'orgs'

-- The bank name shown in the orgs menu
orgs.BankName = 'My bank PLC'

-- Currency symbol, if gamemode is not DarkRP
orgs.CurrencySymbol = '$'

-- If you want the currency symbol on the right, change to false
orgs.CurrencySymbolLeft = true

-- More detailed logging
if SERVER then
  orgs.Debug = true
end

-- Time (in minutes) between salary payments
orgs.SalaryDelay = 10

-- Length limits for groups - will not apply to existing groups if changed
orgs.MaxNameLength      = 35   -- Name length limit for groups and ranks
orgs.MaxTagLength       = 4
orgs.MaxMottoLength     = 120
orgs.MaxBulletinLength  = 1000
orgs.MaxRanks           = 20   -- Maximum number of ranks any group can have

-- Colors used in logs
orgs.Colors.Primary   = Color( 52, 152, 219 )
orgs.Colors.Secondary = Color( 46, 204, 113 )
orgs.Colors.Text      = Color( 245, 245, 245 )
orgs.Colors.Error     = Color( 228, 42, 46 )

if CLIENT then
  orgs.Colors.MenuPrimary       = Color( 27, 201, 224 )       -- Theme main
  orgs.Colors.MenuPrimaryAlt    = Color( 8, 147, 166 )        -- Hover/highlight against primary
  orgs.Colors.MenuSecondary     = Color( 42, 42, 61 )         -- Secondary background (see below)
  orgs.Colors.MenuSecondaryAlt  = Color( 29, 29, 46 )         -- Secondary background for menu
  orgs.Colors.MenuBackground    = Color( 14, 14, 24 )         -- Background
  orgs.Colors.MenuBackgroundAlt = Color( 22, 22, 34 )         -- Alternate background
  orgs.Colors.Close             = Color( 0, 0, 0, 0 )         -- Close buttons
  orgs.Colors.CloseAlt          = orgs.Colors.Error           -- Close buttons hover
  orgs.Colors.CloseText         = orgs.Colors.Text            -- Close buttons text

  orgs.Colors.MenuActive        = Color( 221, 162, 29 )       -- Highlighted/selected lines

  orgs.Colors.MenuButton        = orgs.Colors.MenuPrimary     -- Normal button (not including tabs)
  orgs.Colors.MenuButtonAlt     = orgs.Colors.MenuActive      -- Button hovered

  orgs.Colors.MenuIndicatorOn   = Color( 41, 235, 82 )        -- Online player indicator
  orgs.Colors.MenuIndicatorOff  = orgs.Colors.Error           -- Offline player indicator

  orgs.Colors.MenuButtonWarn    = orgs.Colors.Error           -- Leave buttons
  orgs.Colors.MenuButtonWarnAlt = Color( 207, 28, 27 )        -- Leave buttons hover

  orgs.Colors.MenuBank          = Color( 0, 40, 0 )           -- Bank background
  orgs.Colors.MenuBankAlt       = Color( 0, 203, 0 )          -- Bank background highlight

  orgs.Colors.MenuText          = Color( 173, 173, 198 )      -- Normal text on background
  orgs.Colors.MenuTextAlt       = orgs.Colors.MenuBackground  -- Text on primary

  -- Secondary color settings: false to use Primary, true to use Secondary
  -- Group statistics (Balance, Members, etc) table
  orgs.UsePrimaryInStats = false
  -- Table headers
  orgs.UsePrimaryInTables = false

end

--[[ Default ranks, follow the existing structure
Permission numbers:
0 = Invite other players  5 = Modify ranks
1 = Edit bulletin         4 = Kick members
2 = Withdraw money        6 = Modify the group (e.g. name, motto, tag)
3 = Promote members       7 = View group event log

Name - self-explanatory
Perms - list of permissions this group has. Use commas in between each number.
  Look at the list above to see what each number means

BankLimit - total amount a rank can withdraw from the bank inside their cooldown
BankCooldown - amount of time within which the BankLimit applies (minutes)
e.g. a rank with BankLimit of 1500 and BankCooldown 15 can withdraw no more than 1500 in 15 minutes

Immunity - Minimum immunity a rank has to have in order to perform actions (e.g. kick) against them

Leader - if the rank is given to the founder
Default - if the rank is the one that should be given to new members

Please remember your commas after each }  ]]
orgs.DefaultRanks = {
  { Name     = 'Leader',
    Perms    = '0,1,2,3,4,5,6,7',
    Immunity = 100,
    Leader   = true },

  { Name         = 'Deputy',
    Perms        = '0,1,2,3,4,5,7',
    BankLimit    = 5000,
    BankCooldown = 12,
    Immunity     = 50 },

  { Name         = 'Officer',
    Perms        = '0,1,2,3',
    BankLimit    = 2500,
    BankCooldown = 12,
    Immunity     = 25 },

  { Name     = 'Member',
    Perms    = '0',
    Immunity = 10,
    Default  = true },
}

orgs.Types = {
  { Name            = 'Group', -- Name shown in menus
    Class           = 0,       -- Class to 'group' tiers
    Price           = 0,       -- Price to upgrade to (n/a for lowest type)
    MaxMembers      = 12,      -- Max number of members groups of this type can have
    MaxBalance      = 1000000, -- Max balance groups of this type can have in the bank
    Tax             = 0,       -- Tax on salary for members (percentage as decimal: 10% = 0.1)
    CanAlly         = false,   -- Can form formal alliances
    CanJoinAlly     = false,   -- Can join formal alliances
    CanHide         = true,    -- Can hide - tag is not shown in chat or in hover information
    CanBePublic     = false,   -- Can be publicly listed in the join menu
    PublicCanJoin   = false,   -- Allow members of public to join without invite
    CanDeclareWar   = false,   -- Can publicly declare war against other groups
    WarLength       = 0,       -- Time in mins that declared wars last
    WarCooldown     = 0,       -- Time in mins that group must wait before delaring war again
  },

  { Name            = 'Gang',
    Class           = 1,
    Price           = 640000,
    MaxMembers      = 14,
    MaxBalance      = 4000000,
    Tax             = 0.015,
    CanAlly         = false,
    CanJoinAlly     = false,
    CanHide         = true,
    CanBePublic     = false,
    PublicCanJoin   = false,
    CanDeclareWar   = false,
    WarLength       = 0,
    WarCooldown     = 0,
  },

  { Name            = 'Association',
    Class           = 1,
    Price           = 1400000,
    MaxMembers      = 16,
    MaxBalance      = 6500000,
    Tax             = 0.025,
    CanAlly         = false,
    CanJoinAlly     = false,
    CanHide         = true,
    CanBePublic     = false,
    PublicCanJoin   = false,
    CanDeclareWar   = false,
    WarLength       = 0,
    WarCooldown     = 0,
  },

  { Name            = 'Organisation',
    Class           = 1,
    Price           = 2800000,
    MaxMembers      = 18,
    MaxBalance      = 6500000,
    Tax             = 0.040,
    CanAlly         = false,
    CanJoinAlly     = false,
    CanHide         = true,
    CanBePublic     = false,
    PublicCanJoin   = false,
    CanDeclareWar   = false,
    WarLength       = 0,
    WarCooldown     = 0,
  },

  { Name            = 'Institution',
    Class           = 1,
    Price           = 4200000,
    MaxMembers      = 20,
    MaxBalance      = 6500000,
    Tax             = 0.055,
    CanAlly         = false,
    CanJoinAlly     = false,
    CanHide         = true,
    CanBePublic     = false,
    PublicCanJoin   = false,
    CanDeclareWar   = false,
    WarLength       = 0,
    WarCooldown     = 0,
  },
}

-- If you really want to change the format of messages
-- It is recommended that you only change the strings (unless you know Lua)
orgs.EventStrings = {
  -- Group
  [orgs.EVENT_ORG_CREATE] = '[ActionBy] created a new organisation called [OrgID]',
  [orgs.EVENT_ORG_REMOVE] = '[ActionBy] dissolved the organisation [ActionValue]',
  [orgs.EVENT_ORG_EDIT] = function( tab )
    tab.ActionAttribute = tab.ActionAttribute:lower()

    if tab.ActionAttribute == 'type' then
      tab.ActionValue = orgs.Types[tonumber( tab.ActionValue )].Name

    elseif tab.ActionAttribute == 'defaultrank' then
      tab.ActionAttribute = 'default rank'
      tab.ActionValue = (orgs.Debug and '%s [%s]' or '%s')
        %{orgs.Ranks[tonumber( tab.ActionValue )].Name, orgs.Debug and tab.ActionValue or nil}

    elseif tab.ActionAttribute == 'public' then
      tab.ActionValue = tobool( tab.ActionValue ) and 'public' or 'private'
      return '[ActionBy] made [OrgID] [ActionValue]'

    elseif tab.ActionAttribute == 'bulletin' then
      return '[ActionBy] changed [OrgID]\'s [ActionAttribute]'

    end

    return '[ActionBy] changed [OrgID]\'s [ActionAttribute] to [ActionValue]'
  end,

  -- Rank
  [orgs.EVENT_RANK_ADD] = function( tab )
    local rankID = tonumber( tab.ActionValue )
    if orgs.Ranks[rankID] then
      tab.ActionValue = (orgs.Debug and '%s [%s]' or '%s')
        %{orgs.Ranks[rankID].Name, orgs.Debug and rankID or nil}
    end
    return '[ActionBy] added new rank [ActionValue] to [OrgID]'
  end,
  [orgs.EVENT_RANK_REMOVE] = function( tab )
    local rankID = tonumber( tab.ActionAgainst )
    if orgs.Ranks[rankID] then
      tab.ActionAgainst = (orgs.Debug and '%s [%s]' or '%s')
        %{orgs.Ranks[rankID].Name, orgs.Debug and rankID or nil}
    end
    return '[ActionBy] removed rank [ActionValue] from [OrgID]'
  end,
  [orgs.EVENT_RANK_EDIT] = function( tab )
    tab.ActionAttribute = tab.ActionAttribute:lower():gsub( 'perms', 'permissions' )
    :gsub( 'banklimit', 'withdraw limit' ):gsub( 'bankcooldown', 'withdraw cooldown' )

    local rankID = tonumber( tab.ActionAgainst )
    if orgs.Ranks[rankID] then
      tab.ActionAgainst = (orgs.Debug and '%s [%s]' or '%s')
        %{orgs.Ranks[rankID].Name, orgs.Debug and rankID or nil}
    end

    if tab.ActionAttribute == 'withdraw limit' then
      tab.ActionValue = orgs.FormatCurrency( tab.ActionValue )

    elseif tab.ActionAttribute == 'withdraw cooldown' then
      tab.ActionValue = tab.ActionValue ..'mins'

    end

    return '[ActionBy] changed [ActionAgainst]\'s [ActionAttribute] to [ActionValue]'
  end,

  -- Invite
  [orgs.EVENT_INVITE] = function( tab )
    tab.ActionAgainst = util.SteamIDFrom64( tab.ActionAgainst )
    return '[ActionAgainst] was invited to [OrgID] by [ActionBy]'
  end,
  [orgs.EVENT_INVITE_WITHDRAW] = function( tab )
    tab.ActionAgainst = util.SteamIDFrom64( tab.ActionAgainst )
    return '[ActionAgainst]\'s invitation to [OrgID] was withdrawn by [ActionBy]'
  end,

  -- Member
  [orgs.EVENT_MEMBER_JOIN] = '[ActionBy] joined [OrgID]',
  [orgs.EVENT_MEMBER_LEAVEKICK] = function( tab )
    return tab.ActionAgainst and '[ActionBy] kicked [ActionAgainst] from [OrgID]'
      or '[ActionBy] left [OrgID]'
  end,
  [orgs.EVENT_MEMBER_EDIT] = function( tab )
    tab.ActionAttribute = tab.ActionAttribute:lower()
      :gsub( 'perms', 'additional permissions' ):gsub( 'rankid', 'rank' )

    if CLIENT then
      tab.ActionAgainst = tab.ActionAgainst:gsub( LocalPlayer():SteamID64(), '(Your)' )
    end

    if tab.ActionAttribute == 'rank' then
      local rankID = tonumber( tab.ActionValue )
      if orgs.Ranks[rankID] then
        tab.ActionValue = (orgs.Debug and '%s [%s]' or '%s')
          %{orgs.Ranks[rankID].Name, orgs.Debug and rankID or nil}
      end

    elseif tab.ActionAttribute == 'salary' then
      tab.ActionValue = orgs.FormatCurrency( tab.ActionValue )

    end

    return CLIENT and tab.ActionAgainst == '(Your)'
      and '[ActionBy] changed [ActionAgainst] [ActionAttribute] to [ActionValue]'
      or '[ActionBy] changed [ActionAgainst]\'s [ActionAttribute] to [ActionValue]'
  end,

  -- Bank
  [orgs.EVENT_BANK_DEPOSIT] = function( tab )
    tab.ActionValue = orgs.FormatCurrency( tab.ActionValue )
    return '[ActionBy] deposited [ActionValue] into [OrgID]\'s account'
  end,
  [orgs.EVENT_BANK_WITHDRAW] = function( tab )
    tab.ActionValue = orgs.FormatCurrency( tab.ActionValue )
    return'[ActionBy] withdrew [ActionValue] from [OrgID]\'s account'
  end,
  [orgs.EVENT_BANK_TRANSFER] = function( tab )
    tab.ActionValue = orgs.FormatCurrency( tab.ActionValue )
    return '[ActionBy] transferred [ActionValue] from [OrgID] to [ActionAgainst]'
  end,
  [orgs.EVENT_SALARY] = function( tab )
    tab.ActionValue = orgs.FormatCurrency( tab.ActionValue )
    return '[OrgID] paid a salary of [ActionValue] to [ActionAgainst]'
  end
}
