local gameserver = require "gameserver"
local skynet = require "skynet"
local logger = require "logger"
local config = require "config"

local logind = tonumber (...)

local gamed = {}

local pool = {}

function gamed.open (name)
	logger.log ("gamed opened")

	local n = config.gamed.pool
	for i = 1, n do
		table.insert (pool, skynet.newservice "agent")
	end

	skynet.call (logind, "lua", "register", name, skynet.self ())	
	skynet.call (logind, "lua", "open", config.logind)	
end

function gamed.login_handler (fd, account)
	local agent
	if #pool == 0 then
		agent = skynet.newservice "agent"
	else
		agent = table.remove (pool, 1)
	end

	skynet.call (agent, "lua", "open", account)
	gameserver.forward (fd, agent)
end

gameserver.start (gamed)
