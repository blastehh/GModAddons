local action = "sban" -- Choose from "kick", "ban", "sban","sban_new"
local banTime = 5 -- Ban time in minutes, 0 for permanent
local spoofReason = "Name spoofing"

local blankSequences = {
	"\226\129\161",
	"\226\129\162",
	"\226\129\163",
	"\226\129\164",
	"\226\128\139",
	"\226\128\140",
	"\226\128\141",
	"\226\128\142",
	"\226\128\143",
	"\225\133\154"
}

local nameCache = setmetatable({},{__mode="k"})
gameevent.Listen("player_changename")

local function PunishPlayer(ply)
	ServerLog("[AntiNameSpoof] "..(((action == "ban" or action == "sban" or action == "sban_new") and "Banned ") or "Kicked ")..ply:Nick().." for name spoofing!\n")
	if action == "kick" then
		ply:Kick(spoofReason)
	elseif action == "ban" then
		ply:Ban(banTime, false)
		ply:Kick(spoofReason)
	elseif action == "sban" then
		SBAN_banplayer( ply, (banTime*60), spoofReason, 0)
	elseif action == "sban_new" then
		SBAN.Player_Ban( ply, (banTime*60), spoofReason, 0)
	end
end

local function NameIsValid(nick)
	local invalidName = false
	for k,v in pairs(blankSequences) do
		if string.find(nick, v, 1, true) then
			invalidName = true
			break
		end
	end
	return !invalidName
end

local function CheckPlayerName(ply)
	if !IsValid(ply) then return end
	local nick = ply:Nick()
	if nameCache[ply]~= nick then
	
		if !NameIsValid(nick) then
			PunishPlayer(ply)	
		else
			nameCache[ply] = nick
		end
	end
end

hook.Add("player_changename", "NameSpoofCheck", function(data)
	local nick = data.newname
	local ply = Player(data.userid)
	
	if !NameIsValid(nick) then
		PunishPlayer(ply)
	end

end)

hook.Add("PlayerInitialSpawn", "NameSpoofConnect", function(ply)
	timer.Simple(3, function() CheckPlayerName(ply) end)
end)