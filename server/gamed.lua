local gameserver = require "gameserver"
local skynet = require "skynet"
local logger = require "logger"
local config = require "config"

local logind = tonumber (...)

local gamed = {}

function gamed.open (name)
	logger.log ("gamed opened")

	skynet.call (logind, "lua", "register", name, skynet.self ())	
	skynet.call (logind, "lua", "open", config.logind)	
end

gameserver.start (gamed)
