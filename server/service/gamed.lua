local gameserver = require "gameserver"
local skynet = require "skynet"
local logger = require "logger"
local config = require "config.system"

local logind = tonumber (...)

local gamed = {}

local pool = {}

function gamed.open (name)
	logger.log ("gamed opened")

	local self = skynet.self ()

	local n = config.gamed.pool
	for i = 1, n do
		table.insert (pool, skynet.newservice ("agent", self))
	end

	skynet.call (logind, "lua", "register", name, self)	
	skynet.call (logind, "lua", "open", config.logind)	
end

function gamed.command_handler (cmd, ...)
	local CMD = {}

	function CMD.close (agent)	
		logger.debug (string.format ("agent %d closed", agent))
		table.insert (pool, agent)
	end

	local f = assert (CMD[cmd])
	return f (...)
end

function gamed.login_handler (fd, account)
	local agent
	if #pool == 0 then
		agent = skynet.newservice ("agent", skynet.self ())
	else
		agent = table.remove (pool, 1)
	end

	skynet.call (agent, "lua", "open", fd, account)
	gameserver.forward (fd, agent)
end

gameserver.start (gamed)
