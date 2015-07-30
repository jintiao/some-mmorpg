local skynet = require "skynet"

local syslog = require "syslog"
local handler = require "agent.handler"


local REQUEST = {}
local user
handler = handler.new (REQUEST)

handler:init (function (u)
	user = u
end)

function REQUEST.map_ready ()
	local ok = skynet.call (user.map, "lua", "character_ready", user.character.movement.pos) or error ()
end

return handler
