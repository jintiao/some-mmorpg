local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"

local handler = {}
local REQUEST = {}

function REQUEST:move_blink (args)
	assert (args and args.destination)

	local npos = args.destination
	local opos = self.character.movement.pos
	self.character.movement.pos = npos
	
	local writer = self.character_writer
	if writer then
		writer:commit ()
	end
	
	local ok = skynet.call (self.map, "lua", "move_blink", npos) 
	if not ok then
		self.character.movement.pos = opos
		if writer then
			writer:commit ()
		end
		error ()
	end

	return { pos = npos }
end

function handler:register ()
	local t = self.REQUEST
	for k, v in pairs (REQUEST) do
		t[k] = v
	end
end

function handler:unregister ()
	local t = self.REQUEST
	for k, _ in pairs (REQUEST) do
		t[k] = nil
	end
end

return handler

