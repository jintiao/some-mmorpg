local gateserver = require "gateserver"
local gameserver = {}

function gameserver.start (gated)
	local handler = {}
	return gateserver.start (handler)
end

return gameserver
