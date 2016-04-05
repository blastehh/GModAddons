require("bromsock")
CreateConVar("squery_bind_port", "-1", FCVAR_NONE, "Sets the port to use for outgoing source queries.")
local bindPort = GetConVar("squery_bind_port"):GetInt() or (tonumber(GetConVarString('hostport')) + 500)

cvars.AddChangeCallback( "squery_bind_port", function()
	if(GetConVar("squery_bind_port"):GetInt() != -1) then
		bindPort = GetConVar("squery_bind_port"):GetInt()
	end
end)

local function SourceQueryDecode(packetContents, ip, port)
	local pktLen = string.len(packetContents)
	local splitPositions = {}
	for i=1, pktLen do
		if string.byte(packetContents, i, i) == 0 then
			if #splitPositions == 4 and i < splitPositions[4]+10 then continue end
			splitPositions[#splitPositions+1] = i
		end
	end

	local queryTable = {}
	queryTable.protocol = string.byte(string.sub(packetContents, 6, 6))
	queryTable.name = string.sub(packetContents, 7, splitPositions[1]-1)
	queryTable.map = string.sub(packetContents, splitPositions[1]+1, splitPositions[2]-1)
	queryTable.game = string.sub(packetContents, splitPositions[2]+1, splitPositions[3]-1)
	queryTable.mod = string.sub(packetContents, splitPositions[3]+1, splitPositions[4]-1)
	queryTable.players = string.byte(string.sub(packetContents, splitPositions[4]+3, splitPositions[4]+3))
	queryTable.maxplayers = string.byte(string.sub(packetContents, splitPositions[4]+4, splitPositions[4]+4))
	queryTable.bots = string.byte(string.sub(packetContents, splitPositions[4]+5, splitPositions[4]+5))
	queryTable.type = string.sub(packetContents, splitPositions[4]+6, splitPositions[4]+6)
	queryTable.os = string.sub(packetContents, splitPositions[4]+7, splitPositions[4]+7)
	queryTable.passworded = string.byte(string.sub(packetContents, splitPositions[4]+8, splitPositions[4]+8)) == 1
	queryTable.vac = string.byte(string.sub(packetContents, splitPositions[4]+9, splitPositions[4]+9)) == 1
	queryTable.version = string.sub(packetContents, splitPositions[4]+10, splitPositions[5]-1)
	queryTable.ip = tostring(ip)..":"..tostring(port)
	
	return queryTable
end
--[[---------------------------------------------------------
	Name: SourceQuery(string IP, integer PORT, function CALLBACK)
	Desc: Sends a source engine query to target server then returns the response to provided callback function.
	Returns: callback( table RESULTS )
-----------------------------------------------------------]]
function SourceQuery(sendToIP, sendToPort, callback)
	if !sendToIP or !sendToPort or !callback then return true end

	local querySock = BromSock(BROMSOCK_UDP)
	local qPacket = BromPacket()

	querySock:SetCallbackReceiveFrom(function(sockobj, packet, ip, port)
		--print("[S] Received:", packet, ip, port)
		local packetContents = packet and packet:ReadStringAll()
		sockobj:Close()
		querySock = nil
		qPacket = nil
		if !packet then return end
		packet:Clear()
		callback(SourceQueryDecode(packetContents, ip, port))
	end)
	
	querySock:SetCallbackSendTo( function(sock, datalen, ip, port)
		--print("Packet sent to "..tostring(ip)..":"..tostring(port))
		sock:ReceiveFrom()
	end)
	
	querySock:SetCallbackDisconnect(function(sock)
		--print("[BS:S] Disconnected:", sock)
	end)
	
	querySock:Bind(bindPort)
	querySock:SetTimeout(500)
	
	qPacket:WriteByte(0xff)
	qPacket:WriteByte(0xff)
	qPacket:WriteByte(0xff)
	qPacket:WriteByte(0xff)
	qPacket:WriteByte(0x54)
	qPacket:WriteStringNT("Source Engine Query")
	querySock:SendTo(qPacket, sendToIP, tonumber(sendToPort))
	
end

concommand.Add("sendUDP", function(ply, str, tab, fullStr)
	if IsValid(ply) then return end
	if #string.Explode(" ", fullStr) != 1 then return end
	local srv = string.Explode(":", fullStr)
	if #srv != 2 then print("Invalid arguments!") return end
	local callback = function(input)
		PrintTable(input)
	end
	SourceQuery(srv[1], srv[2], callback)
end)