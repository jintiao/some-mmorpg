local skynet = require "skynet"
local logger = require "logger"

local gamed = ...

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local CMD = {}

function CMD.open (account)
	local name = string.format ("agnet-%d", account)
	logger.register (name)
	logger.log (string.format ("agent %d opened", skynet.self ()))
end

function CMD.close ()
	skynet.call (gamed, "lua", "close", skynet.self ())
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)
