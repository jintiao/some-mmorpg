local skynet = require "skynet"
local logger = require "logger"
local aoi = require "misc.aoi"

local world = ...
local conf

local online_character = {}
local CMD = {}

function CMD.init (c)
	conf = c
	aoi.init (conf.bbox, conf.radius)
end

function CMD.character_enter (agent, character, pos)
	logger.log (string.format ("character (%d) entering map (%s)", character, conf.name))
	online_character[character] = agent
	skynet.call (agent, "lua", "map_enter", conf.name, character, pos)

	local ok, interest_list, notify_list = aoi.insert (character, pos)
	if ok == false then
		skynet.call (world, "lua", "kick", character)
		return
	end

	local t = {}
	for i = 1, #interest_list do
		local c = interest_list[i]
		t[c] = online_character[c]
	end
	skynet.call (agent, "lua", "aoi_add", t)

	local ct = { [character] = agent }
	for i = 1, #notify_list do
		local a = online_character[notify_list[i]]
		if a then
			skynet.call (a, "lua", "aoi_add", ct)
		end
	end
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)
