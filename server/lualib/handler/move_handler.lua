local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"

local handler = {}
local REQUEST = {}

function REQUEST:move_blink (args)
	assert (args and args.destination)

	local pos = skynet.call (self.map, "lua", "move_blink", self.character.id, args.destination) 


	return { target = tid, damage = damage }
end

function REQUEST:combat_melee_damage (attacker, damage)
	damage = math.floor (damage * 0.75)

	hp = self.character.attribute.health - damage
	if hp <= 0 then
		damage = damage + hp
		hp = self.character.attribute.health_max
	end
	self.character.attribute.health = hp

	return damage
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

