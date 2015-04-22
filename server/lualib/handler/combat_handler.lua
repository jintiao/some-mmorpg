local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"

local handler = {}
local REQUEST = {}

function REQUEST:combat_melee_attack (args)
	local tid = args.target
	assert (tid)

	local t = self.subscribing[tid]
	assert (t and t.agent)

	local damage = self.character.attribute.attack_power
	damage = skynet.call (t.agent, "lua", "combat_melee_damage", self.character.id, damage) 

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

