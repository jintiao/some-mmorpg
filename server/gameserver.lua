local gateserver = require "gateserver"
local gameserver = {}

function gameserver.start (gamed)
	local handler = {}

	function handler.open (source, conf)
		return gamed.open (conf.name)
	end

	return gateserver.start (handler)
end

return gameserver
