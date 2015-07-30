local skynet = require "skynet"

local syslog = require "syslog"
local handler = require "agent.handler"
local aoi_handler = require "agent.aoi_handler"


local REQUEST = {}
local CMD = {}
local user
handler = handler.new (REQUEST, nil, CMD)

handler:init (function (u)
	user = u
end)


function REQUEST.combat (args)
	assert (args and args.target)

	local tid = args.target
	local agent = aoi_handler.find (tid) or error ()

	local damage = user.character.attribute.attack_power
	damage = skynet.call (agent, "lua", "combat_melee_damage", user.character.id, damage) 

	return { target = tid, damage = damage }
end

function CMD.combat_melee_damage (attacker, damage)
	damage = math.floor (damage * 0.75)

	hp = user.character.attribute.health - damage
	if hp <= 0 then
		damage = damage + hp
		hp = user.character.attribute.health_max
	end
	user.character.attribute.health = hp

	aoi_handler.boardcast ("attribute")
	return damage
end

return handler
