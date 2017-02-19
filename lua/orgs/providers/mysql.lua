local host = 'localhost'
local user = 'root'
local pass = 'root'
local database = 'orgs_test'
local port = 3306

-- End of config

local PROVIDER = { Name= 'MySQL' }
if not mysqloo then
  local res = pcall( require, 'mysqloo' )

  if not res then
    orgs.LogError( false, 'Failed to load mysqloo - make sure it\'s installed!\n'
      ..'See https://facepunch.com/showthread.php?t=1515853 for more information' )
    PROVIDER.Failed = true
    return
  end
end

local db = db or mysqloo.connect( host, user, pass, database, port )
db:setMultiStatements( false )
hook.Add( 'InitPostEntity', 'orgs.connectToDB', function()
  db:connect()
end )

local setupQuery = [[
SET FOREIGN_KEY_CHECKS = 0;
CREATE TABLE IF NOT EXISTS orgs(
  OrgID bigint UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  Type tinyint DEFAULT 1,
  Name varchar( %s ) NOT NULL,
  Tag varchar( %s ),
  Motto varchar( %s ),
  Bulletin varchar( %s ),
  Balance bigint UNSIGNED DEFAULT 0,
  DefaultRank bigint UNSIGNED,
  Color varchar( 11 ) DEFAULT '255,255,255',
  Public boolean DEFAULT false,
  CONSTRAINT FOREIGN KEY ( DefaultRank ) REFERENCES Ranks( RankID )
    ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS players(
  SteamID bigint UNSIGNED PRIMARY KEY NOT NULL,
  Nick varchar( 32 ),
  OrgID bigint UNSIGNED,
  RankID bigint UNSIGNED,
  Perms varchar( 15 ),
  Salary int,
  CONSTRAINT FOREIGN KEY ( OrgID ) REFERENCES orgs( OrgID )
    ON DELETE SET NULL
);
CREATE TABLE IF NOT EXISTS ranks(
  RankID bigint UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  OrgID bigint UNSIGNED NOT NULL,
  Name varchar( 15 ) NOT NULL,
  Perms varchar( 30 ),
  BankLimit bigint,
  BankCooldown bigint,
  Immunity smallint,
  CONSTRAINT FOREIGN KEY ( OrgID ) REFERENCES orgs( OrgID )
    ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS events(
  EventID bigint PRIMARY KEY AUTO_INCREMENT,
  OrgID bigint UNSIGNED,
  Type tinyint NOT NULL,
  ActionBy bigint UNSIGNED,
  ActionAttribute varchar( 12 ),
  ActionValue varchar( 100 ),
  ActionAgainst bigint UNSIGNED,
  Time bigint,
  CONSTRAINT FOREIGN KEY ( OrgID ) REFERENCES orgs( OrgID )
    ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS invites(
  InviteID int( 8 ) PRIMARY KEY AUTO_INCREMENT,
  OrgID bigint UNSIGNED,
  `From` bigint UNSIGNED NOT NULL,
  `To` bigint UNSIGNED NOT NULL,
  CONSTRAINT FOREIGN KEY ( OrgID ) REFERENCES orgs( OrgID )
    ON DELETE CASCADE
);
SET FOREIGN_KEY_CHECKS = 1
]] %{orgs.MaxNameLength, orgs.MaxTagLength, orgs.MaxMottoLength, orgs.MaxBulletinLength}

local tables = {
  orgs     = TruthTable{'Type','Name','Tag','Motto','Bulletin','Balance','DefaultRank',
    'Color', 'Public'},
  players  = TruthTable{'SteamID','Nick','OrgID','RankID','Perms','Salary'},
  ranks    = TruthTable{'OrgID','Name','Perms','BankLimit','BankCooldown','Immunity'},
  events   = TruthTable{'OrgID','Type','ActionBy','ActionValue','ActionAgainst',
    'ActionAttribute','Time'},
  invites  = TruthTable{'OrgID','From','To'},
}

--   Helpers
local function qmarks( tab, update, name )
  if update then
    local n, str = 1, ''
    for k, v in pairs( tab ) do
      str = '%s%s`%s` = ?' %{str, n ~= 1 and ', ' or '', k}
      n = n +1
    end
    return str
  else
    return '?'.. string.rep( ', ?', table.Count( tab ) -1 )
  end
end

local function columns( tab, name )
  local n, str = 1, ''
  for k, v in pairs( tab ) do
    str = '%s%s`%s`' %{str, n ~= 1 and ', ' or '', k}
    n = n +1
  end

  return str
end

local typeTab = {
  string= 'String',
  number= 'Number',
  boolean= 'Boolean',
  Entity= 'Null',
}
PROVIDER._sendQuery = function( sql, tab, done )
  local q = tab and db:prepare( sql ) or db:query( sql )

  q.onSuccess = function( q, data )
    if done then done( data, nil, q ) end
  end

  q.onError = function( q, err, sql )
    orgs.LogError( false, 'Error when running query\nError: ', err, '\nSQL: ', sql )
    if done then done( nil, err, q ) end
  end
  q.onAborted = q.onError

  if tab then
    for k, v in pairs( tab ) do
      q[ 'set'.. typeTab[type( v )] ]( q, k, v )
    end
  end

  q:start()
end

PROVIDER.insert = function( name, tab, done )

  for k, v in pairs( tab ) do
    if not tables[name][k] then
      orgs.LogError( false, 'Attempt to set value of unlisted field', k, 'in table', name )
      tab[k] = nil
    end
  end
  local cols, qs = columns( tab, name ), qmarks( tab )
  tab = table.ClearKeys( tab )

  PROVIDER._sendQuery( 'INSERT INTO %s( %s ) VALUES( %s );' %{name, cols, qs}, tab, done )
end

PROVIDER.update = function( name, tab, where, whereParams, done )
  for k, v in pairs( tab ) do
    if not tables[name][k] then
      orgs.LogError( false, 'Attempt to set value of unlisted field', k, 'in table', name )
      tab[k] = nil
    end
  end
  local qs = qmarks( tab, true, name )

  tab = table.ClearKeys( tab )
  if istable( whereParams ) then
    for k, v in pairs( whereParams ) do table.insert( tab, v ) end
  else table.insert( tab, whereParams ) end

  PROVIDER._sendQuery( 'UPDATE %s SET %s %s;' %{name, qs,
    where and 'WHERE '.. where or ''}, tab, done )
end

PROVIDER.delete = function( name, where, done )

  PROVIDER._sendQuery( 'DELETE FROM %s%s;' %{name,
    where and ' WHERE '.. where or ''}, nil, done )
end

-- Event helpers

PROVIDER.addEvent = function( type, tab, done )
  PROVIDER.insert( 'events', tab,
  function( data, err, q )
    if done then done( q:lastInsert(), err ) end
  end )
end

-- Invite helpers

PROVIDER.addInvite = function( to, from, orgID, done )
  PROVIDER.insert( 'invites', {To= to, From= from, OrgID= orgID}, function( d, e, q )
    if done then done( d, e, q:lastInsert() ) end
  end )
end

PROVIDER.removeInvite = function( id, done )
  PROVIDER.delete( 'invites', 'InviteID = '..id, done )
end

PROVIDER.getOrgInvites = function( id, done )
  PROVIDER._sendQuery( [[SELECT *, CONVERT( `From`, char ) AS `From`, CONVERT( `To`, char ) AS `To`
    FROM invites WHERE OrgID = %s;]] %{id}, nil, done )
end

PROVIDER.getPlayerInvites = function( id, done )
  PROVIDER._sendQuery( [[SELECT *, CONVERT( `From`, char ) AS `From`, CONVERT( `To`, char ) AS `To`
    FROM invites WHERE `To` = %s;]] %{id}, nil, done )
end

-- Player helpers

PROVIDER.addPlayer = function( steamID, nick, done )
  PROVIDER.insert( 'players', {SteamID= steamID, Nick= nick}, done )
end

PROVIDER.updatePlayer = function( steamID, tab, done )
  PROVIDER.update( 'players', tab, 'SteamID = ?', steamID, done )
end

PROVIDER.getPlayer = function( steamID, done )
  PROVIDER._sendQuery( [[SELECT *, CONVERT( SteamID, char ) AS SteamID
    FROM players WHERE SteamID = ? LIMIT 1;]], {steamID},
  function( data, err )
    if done then done( data[1], err ) end
  end )
end

PROVIDER.getOrgMembers = function( orgID, done )
  PROVIDER._sendQuery( [[SELECT *, CONVERT( SteamID, char ) AS SteamID FROM players
    WHERE OrgID = ?;]], {orgID}, done )
end

PROVIDER.addRank = function( orgID, tab, done )
  PROVIDER.insert( 'ranks', tab,
  function( data, err, q )
    if done then done( q:lastInsert(), err ) end
  end )
end

PROVIDER.updateRank = function( rankID, tab, done )
  PROVIDER.update( 'ranks', tab, 'RankID = ?', rankID, done )
end

PROVIDER.removeRank = function( rankID, done )
  PROVIDER.delete( 'ranks', 'RankID = '.. rankID, done )
end

PROVIDER.getOrgRanks = function( orgID, done )
  PROVIDER._sendQuery( 'SELECT * FROM ranks WHERE OrgID = ?;', {orgID}, done )
end

-- Organisation helpers

PROVIDER.addOrg = function( tab, done )
  PROVIDER.insert( 'orgs', tab,
  function( data, err, q )
    if done then done( q:lastInsert(), err ) end
  end )
end

PROVIDER.removeOrg = function( orgID, done )
  PROVIDER.delete( 'orgs', [[OrgID = '%s']] %{orgID}, done )
end

PROVIDER.updateOrg = function( orgID, tab, done )
  PROVIDER.update( 'orgs', tab, 'OrgID = ?', orgID, done )
end

PROVIDER.getOrgEvents = function( orgID, done )
  PROVIDER._sendQuery( [[SELECT *, CONVERT( ActionBy, char ) AS ActionBy,
    CONVERT( ActionAgainst, char ) AS ActionAgainst
    FROM events WHERE OrgID = ?;]], {orgID}, done )
end

PROVIDER.getAllOrgs = function( done )
  PROVIDER._sendQuery( [[SELECT orgs.*, ( SELECT COUNT(*) FROM players WHERE OrgID = orgs.OrgID )
    AS Members FROM orgs ORDER BY Balance DESC;]], {}, done )
end

db.onConnected = function()
  PROVIDER.Failed = false
  if PROVIDER.DoneFirstConnect then return end

  orgs.Log( true, 'Connected to database; running setup queries ...' )
  for k, sql in pairs( string.Explode( ';', setupQuery ) ) do
    PROVIDER._sendQuery( sql ..';' )
  end
  orgs.getAllOrgs( function( done, err )
    if not err then PROVIDER._loadedOrgs = true end
  end )

  PROVIDER.DoneFirstConnect = true
end

db.onConnectionFailed = function()
  orgs.LogError( false, 'Failed to connect to database %s@%s' %{user, database} )
  PROVIDER.Failed = true
end

-- For Lua autoreload
if orgs._Provider and orgs._Provider.Name == PROVIDER.Name then
  PROVIDER.DoneFirstConnect = orgs._Provider.DoneFirstConnect
  orgs._Provider = PROVIDER
  db:connect()
end
return PROVIDER
