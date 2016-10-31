local host = 'localhost'
local user = 'root'
local pass = 'root'
local database = 'orgs_test'
local port = 3306

-- End of config

local PROVIDER = orgs._Provider or { Name= 'MySQL' }
if not mysqloo then require( 'mysqloo' ) end

local setupQuery = [[
CREATE TABLE IF NOT EXISTS `orgs`(
  `OrgID` bigint UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `Type` tinyint DEFAULT 0,
  `Name` varchar( %s ) NOT NULL,
  `Tag` varchar( %s ),
  `Motto` varchar( %s ),
  `Bulletin` varchar( %s ),
  `Balance` int UNSIGNED DEFAULT 0,
  `DefaultRank` bigint UNSIGNED,
  FOREIGN KEY `DefaultRank` REFERENCES ranks( RankID ) ON DELETE SET NULL,
  `Color` varchar( 11 ) DEFAULT '255,255,255',
  `Public` boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS `players`(
  `SteamID` bigint UNSIGNED PRIMARY KEY,
  `Nick` varchar( 32 ),
  `OrgID` bigint UNSIGNED,
  FOREIGN KEY `OrgID` REFERENCES orgs( OrgID ) ON DELETE SET NULL,
  `RankID` bigint UNSIGNED,
  `Perms` varchar( 15 ),
  `Salary` int
);

CREATE TABLE IF NOT EXISTS `ranks`(
  `RankID` bigint UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  `OrgID` bigint UNSIGNED NOT NULL,
  FOREIGN KEY `OrgID` REFERENCES orgs( OrgID ) ON DELETE CASCADE,
  `Name` varchar( 15 ) NOT NULL,
  `Perms` varchar( 30 ),
  `BankLimit` bigint,
  `BankCooldown` bigint,
  `Immunity` smallint
);

CREATE TABLE IF NOT EXISTS `events`(
  `EventID` bigint PRIMARY KEY AUTO_INCREMENT,
  `OrgID` bigint UNSIGNED,
  `Type` tinyint NOT NULL,
  `ActionBy` bigint UNSIGNED,
  `ActionValue` varchar( 100 ),
  `ActionAgainst` bigint UNSIGNED,
  `Time` int( 32 )
);

CREATE TABLE IF NOT EXISTS `invites`(
  `InviteID` int( 8 ) PRIMARY KEY AUTO_INCREMENT,
  `OrgID` bigint UNSIGNED,
  FOREIGN KEY `OrgID` REFERENCES orgs( OrgID ) ON DELETE CASCADE,
  `From` bigint UNSIGNED NOT NULL,
  `To` bigint UNSIGNED NOT NULL
)
]] %{orgs.MaxNameLength, orgs.MaxTagLength, orgs.MaxMottoLength, orgs.MaxBulletinLength}

hook.Add( 'InitPostEntity', 'orgs.connectToDB', function()
  PROVIDER.db = mysqloo.connect( host, user, pass, database, port )

  PROVIDER.db.onConnected = function()
    PROVIDER.Failed = false
    orgs.Log( true, 'Setting up database tables...' )
    for k, sql in pairs( string.Explode( ';', setupQuery ) ) do PROVIDER._sendQuery( sql ) end
    orgs.getAllOrgs( function( done, err )
      if not err then PROVIDER._loadedOrgs = true end
    end)
  end
  PROVIDER.db.onConnectionFailed = function()
    orgs.LogError( false, 'Failed to connect to database' )
    PROVIDER.Failed = true
  end

  PROVIDER.db:connect()
end )

function escape( val )
  if isbool( val ) then return v and 1 or 0 end
  return '\''.. PROVIDER.db:escape( tostring( val ) ) ..'\''
end

function escapeTab( tab )

  for k, v in pairs( tab ) do
    if isbool( v ) then tab[k] = tostring( v ) continue end
    if not isstring( v ) then continue end
    tab[k] = escape( v )
  end

  return tab
end

--   Helpers
PROVIDER._sendQuery = function( sql, done )
  local q = PROVIDER.db:query( sql )
  -- print( sql )
  q.onSuccess = function( q, data )
    if done then done( data, nil, q ) end
  end

  q.onError = function( q, err, sql )
    orgs.LogError( false, 'Error when running query\nError: ', err, '\nSQL: ', sql )
    if done then done( nil, err, q ) end
  end

  q:start()
end

PROVIDER.addEvent = function( type, tab, done )
  tab = escapeTab( table.Copy( tab ) )

  PROVIDER._sendQuery( 'INSERT INTO `events`( %s ) VALUES( %s )' % {
    table.concat( table.GetKeys( tab ), ', ' ),
    table.concat( table.ClearKeys( tab ), ', ' )
  }, function( data, err, q )
    if done then done( q:lastInsert(), err ) end
  end )
end

-- Player helpers

PROVIDER.addPlayer = function( steamID, nick )
  PROVIDER._sendQuery( 'INSERT INTO `players`( SteamID, Nick ) VALUES( %s, %s );' % {
    steamID,
    escape(nick)
  } )
end

PROVIDER.updatePlayer = function( steamID, tab, done )
  tab = table.Copy( tab )
  for field, value in pairs( tab ) do
    tab[field] = [[`%s` = %s]] %{string.lower(field), value == NULL and 'NULL' or escape( value )}
  end
  local str = table.concat( table.ClearKeys( tab ), ',' )

  PROVIDER._sendQuery( 'UPDATE `players` SET ' .. str .. ' WHERE `SteamID` = \'%s\';' % {
    steamID
  }, done )
end

PROVIDER.getPlayer = function( steamID, done )
  PROVIDER._sendQuery( 'SELECT *, CONVERT( SteamID, char ) AS SteamID FROM `players` WHERE `SteamID` = %s LIMIT 1' % {
    steamID
  }, function( data, err )
    if done then done( data[1], err ) end
  end )
end

PROVIDER.getOrgMembers = function( orgID, done )
  PROVIDER._sendQuery( 'SELECT *, CONVERT( SteamID, char ) AS SteamID FROM `players` WHERE OrgID = ' .. orgID..';',
    function( data, err )
      if done then done( data, err ) end
  end )
end

PROVIDER.addRank = function( orgID, tab, done )
  tab = escapeTab( table.Copy( tab ) )

  PROVIDER._sendQuery( 'INSERT INTO `ranks`( %s ) VALUES( %s );' % {
    table.concat( table.GetKeys( tab ), ', ' ),
    table.concat( table.ClearKeys( tab ), ', ' )
  }, function( data, err, q )
    if done then done( q:lastInsert(), err ) end
  end )
end

PROVIDER.updateRank = function( rankID, tab, done )
  tab = table.Copy( tab )
  for field, value in pairs( tab ) do
    tab[field] = [[`%s` = %s]] %{string.lower(field), value == NULL and 'NULL' or escape(value)}
  end
  local str = table.concat( table.ClearKeys( tab ), ',' )

  PROVIDER._sendQuery( 'UPDATE `ranks` SET ' .. str .. ' WHERE `RankID` = \'%s\';' % {
    rankID
  }, done )
end

PROVIDER.removeRank = function( rankID, done )
  PROVIDER._sendQuery( 'DELETE FROM `ranks` WHERE RankID ='.. rankID..';', done )
end

PROVIDER.getOrgRanks = function( orgID, done )
  PROVIDER._sendQuery( 'SELECT * FROM `ranks` WHERE OrgID = ' .. orgID ..';', done )
end

-- Organisation helpers

PROVIDER.addOrg = function( tab, done )
  tab = escapeTab( table.Copy( tab ) )

  PROVIDER._sendQuery( 'INSERT INTO `orgs`( %s ) VALUES( %s );' % {
    table.concat( table.GetKeys( tab ), ', ' ),
    table.concat( table.ClearKeys( tab ), ', ' )
  }, function( data, err, q )
    if done then done( q:lastInsert(), err ) end
  end )
end

PROVIDER.removeOrg = function( orgID, done )
  PROVIDER._sendQuery( 'DELETE FROM `ranks` WHERE `OrgID` = %s;' %{orgID})
  PROVIDER._sendQuery( 'DELETE FROM `orgs` WHERE `OrgID` = %s;' %{orgID}, function( data, err )
    if done then done( data, err ) end
  end )
end

PROVIDER.updateOrg = function( orgID, tab, done )
  tab = table.Copy( tab )
  for field, value in pairs( tab ) do
    tab[field] = [[`%s` = %s]] %{field, value == NULL and 'NULL' or escape( value )}
  end
  local str = table.concat( table.ClearKeys( tab ), ',' )

  PROVIDER._sendQuery( 'UPDATE `orgs` SET ' .. str .. ' WHERE `OrgID` = %s LIMIT 1;' % {
    orgID
  }, done )
end

PROVIDER.getOrgEvents = function( orgID, done )
  PROVIDER._sendQuery( [[SELECT *, CONVERT( ActionBy, char ) AS ActionBy,
    CONVERT( ActionAgainst, char ) AS ActionAgainst
    FROM `events` WHERE OrgID = %s;]] %{orgID},
    function( data, err )
      if done then done( data, err ) end
  end )
end

PROVIDER.getAllOrgs = function( done )
  PROVIDER._sendQuery( 'SELECT orgs.*, ( SELECT COUNT(*) FROM `players` WHERE `OrgID` = orgs.OrgID )'
    ..' AS Members FROM `orgs`',
    function( data, err )
      if done then done( data, err ) end
  end )
end

-- For Lua autoreload
if orgs._Provider and orgs._Provider.Name == PROVIDER.Name then
  orgs._Provider = PROVIDER
end
return PROVIDER
