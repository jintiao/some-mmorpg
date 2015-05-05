
local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"

local REQUEST = {}

function REQUEST:map_ready ()
	local ok = skynet.call (self.map, "lua", "character_ready", self.character.movement.pos)
	if ok == false then
		error () 
	end
end

local handler = {}

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

