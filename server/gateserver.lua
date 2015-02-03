local skynet = require "skynet"
local gateserver = {}

function gateserver.start (handler)
	local CMD = {}

	function CMD.open (source, conf)
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
