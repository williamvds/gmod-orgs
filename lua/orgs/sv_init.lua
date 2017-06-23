include 'sv_networking.lua'
include 'sv_data.lua'

AddCSLuaFile 'sh_util.lua'
AddCSLuaFile 'cl_init.lua'

for _, f in pairs( file.Find( 'orgs/vgui/*.lua', 'LUA' ) ) do AddCSLuaFile( 'orgs/vgui/' .. f ) end

hook.Add( 'orgs.AfterLoadPlayer', 'orgs.StartSalaryTimer', function( ply, orgID )

  local steamID = ply:SteamID64()
  timer.Create( 'orgs.SalaryTimer'.. steamID, orgs.SalaryDelay *60, 0, function()
    if not IsValid( ply ) then timer.Remove( 'orgs.SalaryTimer'.. steamID ) return end

    local org, member = ply:orgs_Org(), ply:orgs_Info()
    if not member then return end

    local salary = member.Salary
    if not org or not salary or salary == 0 or salary == '' then return end

    if salary > org.Balance then
      orgs.ChatLog( ply, 'Your group does not have enough money in the bank to pay your salary!' )
      return
    end

    orgs.updateOrg( ply:orgs_Org(0), {Balance= org.Balance -salary}, nil, function( _, err )
      if err or not IsValid( ply ) then return end
      ply:addMoney( salary *( 1 -orgs.Types[org.Type].Tax ) )
      orgs.LogEvent( orgs.EVENT_SALARY,
        {OrgID= org.OrgID, ActionValue= salary, ActionAgainst= steamID} )
      orgs.ChatLog( ply, 'You received a salary of %s after tax' %{orgs.FormatCurrency( salary )} )
    end )

  end )

end )
