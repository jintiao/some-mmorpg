local skynet = require "skynet"
local gateserver = {}

function gateserver.start (handler)
	local CMD = {}

	function CMD.open (source, conf)
		if handler.open then
			return handler.open (source, conf)
		end
	end

	skynet.start (function ()
		skynet.dispatch ("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			if f then
				skynet.retpack (f(address, ...))
			else
				skynet.retpack (handler.command (cmd, address, ...))
			end
		end)
	end)
end

return gateserver
