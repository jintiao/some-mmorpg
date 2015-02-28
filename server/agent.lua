local skynet = require "skynet"

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
}

local CMD = {}

function CMD.open (account)
	print (string.format ("loading account %d...", account))
end

function CMD.close ()
	print ("agent close")
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)
