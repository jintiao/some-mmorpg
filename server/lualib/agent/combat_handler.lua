local skynet = require "skynet"

local logger = require "logger"
local handler = require "agent.handler"
local aoi_handler = require "agent.aoi_handler"


local REQUEST = {}
local user
handler = handler.new (REQUEST)

handler:init (function (u)
	user = u
end)


function REQUEST.combat (args)
	local tid = args.target
	assert (tid)

	local t = user.subscribing[tid]
	assert (t and t.agent)

	local damage = user.character.attribute.attack_power
	damage = skynet.call (t.agent, "lua", "combat_melee_damage", user.character.id, damage) 

	return { target = tid, damage = damage }
end

function REQUEST.combat_melee_damage (attacker, damage)
	damage = math.floor (damage * 0.75)

	hp = user.character.attribute.health - damage
	if hp <= 0 then
		damage = damage + hp
		hp = user.character.attribute.health_max
	end
	user.character.attribute.health = hp

	aoi_handler.boardcast_attribute (user)
	return damage
end

return handler
