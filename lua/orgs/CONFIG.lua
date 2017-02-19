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
orgs.PrimaryCol    = Color( 52, 152, 219 )
orgs.TextCol       = Color( 245, 245, 245 )
orgs.HighlightCol  = Color( 46, 204, 113 )
orgs.ErrorCol      = Color( 228, 42, 46 )

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
    Price           = 0,       -- Price to upgrade to (n/a for lowest type)
    MembersRequired = 0,       -- Members needed to upgrade to this type
    MaxMembers      = 10,      -- Max number of members groups of this type can have
    MaxBalance      = 30000,   -- Max balance groups of this type can have in the bank
    Tax             = 0,       -- Tax on salary for members (percentage as decimal - 10% = 0.1)
    CanAlly         = false,   -- Can form formal alliances
    CanHide         = true,    -- Can hide - tag is not shown in chat or in hover information
  },

  { Name            = 'Organisation',
    Price           = 10000,
    MembersRequired = 15,
    MaxMembers      = 30,
    MaxBalance      = 100000,
    Tax             = 0.015,
    CanAlly         = true,
    CanJoinAlliance = false,
    CanFormAlliance = false,
    MaxAlliances    = 0,
    CanHide         = true },
}

-- If you really want to change the format of messages
-- It is recommended that you only change the strings (unless you know Lua)
orgs.EventStrings = {
  -- Group
  [orgs.EVENT_ORG_CREATE] = '[ActionBy] created a new organisation called [OrgID]',
  [orgs.EVENT_ORG_REMOVE] = '[ActionBy] dissolved the organisation [ActionAgainst]',
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
      :gsub( 'perms', 'permissions' ):gsub( 'rankid', 'rank' )

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
