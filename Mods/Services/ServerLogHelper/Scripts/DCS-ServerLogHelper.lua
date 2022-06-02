net.log("ServerLogHelper Hook called")



local base = _G

local lfs               = require('lfs')
local socket            = require("socket") 
local net               = require('net')
local DCS               = require("DCS") 
local Skin              = require('Skin')
local Gui               = require('dxgui')
local DialogLoader      = require('DialogLoader')
local Static            = require('Static')
local Tools             = require('tools')


ServerLogHelper = {
	config = {directory = lfs.writedir()..[[Logs\]]},
	logFile = io.open(lfs.writedir()..[[Logs\DCS-ServerLogHelper.log]], "w"),
	slotLookup = {}, -- key = sideID, value = table: key = slotID, value = table returned by DCS.getAvailableSlots
	currentLogFile = nil
}

-----------------------------------------------------------
-- CONFIG & UTILITY
ServerLogHelper.log = function(str, logFile, prefix)
    if not str and not prefix then 
        return
    end
	
	if not logFile then
		logFile = ServerLogHelper.logFile
	end
	
    if logFile then
		local msg = ''
		if prefix then msg = msg..prefix end
		if str then
			if type(str) == 'table' then
				msg = msg..'{'
				for k,v in pairs(str) do
					local t = type(v)
					msg = msg..k..':'..ServerLogHelper.obj2str(v)..', '
				end
				msg = msg..'}'
			else
				msg = msg..str
			end
		end
		logFile:write("["..os.date("%H:%M:%S").."] "..msg.."\r\n")
		logFile:flush()
    end
end

ServerLogHelper.obj2str = function(obj)
    if obj == nil then 
        return '??'
    end
	local msg = ''
	local t = type(obj)
	if t == 'table' then
		msg = msg..'{'
		for k,v in pairs(obj) do
			local t = type(v)
			msg = msg..k..':'..ServerLogHelper.obj2str(v)..', '
		end
		msg = msg..'}'
	elseif t == 'number' or t == 'string' or t == 'boolean' then
		msg = msg..obj
	else
		msg = msg..t
	end
	return msg
end

function ServerLogHelper.loadConfiguration()
    ServerLogHelper.log("Config load starting")
	
    local cfg = Tools.safeDoFile(lfs.writedir()..'Config/ServerLogHelper.lua', false)
	
    if (cfg and cfg.config) then
		for k,v in pairs(ServerLogHelper.config) do
			if cfg.config[k] ~= nil then
				ServerLogHelper.config[k] = cfg.config[k]
			end
		end        
    end
	
	ServerLogHelper.saveConfiguration()
end

function ServerLogHelper.saveConfiguration()
    U.saveInFile(ServerLogHelper.config, 'config', lfs.writedir()..'Config/ServerLogHelper.lua')
end

--error handler for xpcalls. wraps hitch_trooper.log_e:error
ServerLogHelper.catchError=function(err)
	ServerLogHelper.log(err)
end 

ServerLogHelper.safeCall = function(func,args)
	local op = func
	if args then 
		op = function()
			func(unpack(args))
		end
	end
	
	xpcall(op,ServerLogHelper.catchError)
end

--------------------------------------------------------------
ServerLogHelper.getPlayerUcid = function(id)
	if DCS.isServer() then 
		return net.get_player_info(id, 'ucid')
	end
	return "??"	
end

--------------------------------------------------------------
-- CALLBACKS

ServerLogHelper.onMissionLoadBegin = function()
	ServerLogHelper.safeCall(ServerLogHelper.doOnMissionLoadBegin)
end

ServerLogHelper.doOnMissionLoadBegin = function()
	ServerLogHelper.loadConfiguration()
	local log_file_name = string.gsub(DCS.getMissionName().."_"..os.date("%Y%m%d%H%M%S")..".log","[^%w%._%-]","")
	
	local subdir = 'ServerLogHelper'
	lfs.mkdir(ServerLogHelper.config.directory..subdir)
	
	local fulldir = ServerLogHelper.config.directory..subdir .."\\"
	
	ServerLogHelper.currentLogFile = io.open(fulldir .. log_file_name, "w")
	ServerLogHelper.log("Mission "..DCS.getMissionName().." loading",ServerLogHelper.currentLogFile)
end

ServerLogHelper.onMissionLoadEnd = function()
	ServerLogHelper.safeCall(ServerLogHelper.doOnMissionLoadEnd)
end

ServerLogHelper.doOnMissionLoadEnd = function()
	ServerLogHelper.log("Mission "..DCS.getMissionName().." loaded",ServerLogHelper.currentLogFile)
	
	ServerLogHelper.slotLookup={}
	local myCoalition = {blue = base.coalition.BLUE, red = base.coalition.RED}
	for k,v in pairs(myCoalition) do
		local coaSlots = {}
		local rawCoaSlots = DCS.getAvailableSlots(k)
		ServerLogHelper.log(rawCoaSlots)
		if type(rawCoaSlots) == 'table' then
			for l,w in pairs(rawCoaSlots) do
				coaSlots[w.unitId] = w
			end
		end
		ServerLogHelper.slotLookup[v] = coaSlots
	end
	
	ServerLogHelper.log(ServerLogHelper.slotLookup,ServerLogHelper.currentLogFile,"Available slots:\n")
end

ServerLogHelper.onPlayerConnect = function(id)
	ServerLogHelper.safeCall(ServerLogHelper.doOnPlayerConnect,{id})
end

ServerLogHelper.doOnPlayerConnect = function(id)
	local name = net.get_player_info(id, 'name')
	local ucid = ServerLogHelper.getPlayerUcid(id)
	
	ServerLogHelper.log("Player connected: "..name..". Player ID: "..ucid,ServerLogHelper.currentLogFile)
end

ServerLogHelper.onPlayerDisconnect = function(id)
	ServerLogHelper.safeCall(ServerLogHelper.doOnPlayerDisconnect,{id})
end

ServerLogHelper.doOnPlayerDisconnect = function(id)
	local name = net.get_player_info(id, 'name')
	local ucid = ServerLogHelper.getPlayerUcid(id)
	
	local stats = {kills_veh = net.get_stat(id,net.PS_CAR),
				   kills_air = net.get_stat(id,net.PS_PLANE),
				   kills_sea = net.get_stat(id,net.PS_SHIP),
				   landings = net.get_stat(id,net.PS_LAND),
				   ejected = net.get_stat(id,net.PS_EJECT),
				   crashed = net.get_stat(id,net.PS_CRASH)}
	
	ServerLogHelper.log(stats,ServerLogHelper.currentLogFile, "Player disconnected: "..name..". Player ID: "..ucid.."\n")
end

ServerLogHelper.onPlayerChangeSlot = function(id)
	ServerLogHelper.safeCall(ServerLogHelper.doOnPlayerChangeSlot,{id})
end

ServerLogHelper.doOnPlayerChangeSlot = function(id)
	
	local name = net.get_player_info(id, 'name')
	local ucid = ServerLogHelper.getPlayerUcid(id)
	local sideId,slotId =  net.get_slot(id)
	local slotData
	if ServerLogHelper.slotLookup[sideId] then
		slotData = ServerLogHelper.slotLookup[sideId][slotId]
	end
	
	ServerLogHelper.log(slotData,ServerLogHelper.currentLogFile, "Player changed slot: "..name..". Player ID: "..ucid..". \n")
end

--------------------------------------------------------------
DCS.setUserCallbacks(ServerLogHelper)