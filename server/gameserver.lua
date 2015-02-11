local gateserver = require "gateserver"
local skynet = require "skynet"
local logger = require "logger"

local gameserver = {}

local auth = {}
local handshake = {}

function gameserver.start (gamed)
	local handler = {}

	function handler.open (source, conf)
		return gamed.open (conf.name)
	end

	function handler.connect (fd, addr)
		handshake[fd] = addr
		gateserver.open_client (fd)
	end

	function handler.message (fd, msg, sz)
		print ("handler.message", fd, sz)
	end

	local CMD = {}

	function CMD.login (id, secret)
		logger.log (string.format ("account %d auth finished", id)) 
		auth[id] = secret
	end

	function handler.command (cmd, ...)
		local f = assert (CMD[cmd])
		return f (...)
	end

	return gateserver.start (handler)
end

return gameserver
