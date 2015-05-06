local skynet = require "skynet"

local logger = require "logger"
local handler = require "agent.handler"


local REQUEST = {}
local user
handler = handler.new (REQUEST)

handler:init (function (u)
	user = u
end)


function REQUEST.move (args)
	assert (args and args.pos)

	local npos = args.pos
	local opos = user.character.movement.pos
	for k, v in pairs (opos) do
		if not npos[k] then
			npos[k] = v
		end
	end
	user.character.movement.pos = npos
	
	local writer = user.character_writer
	if writer then
		writer:commit ()
	end
	
	local ok = skynet.call (user.map, "lua", "move_blink", npos) 
	if not ok then
		user.character.movement.pos = opos
		if writer then
			writer:commit ()
		end
		error ()
	end

	return { pos = npos }
end

return handler
