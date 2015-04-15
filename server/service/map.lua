local skynet = require "skynet"
local logger = require "logger"
local aoi = require "misc.aoi"

local world
local conf

local pending_character = {}
local online_character = {}
local CMD = {}

function CMD.init (w, c)
	world = w
	conf = c
	aoi.init (conf.bbox, conf.radius)
end

function CMD.character_enter (_, agent, character)
	logger.log (string.format ("character (%d) entering map (%s)", character, conf.name))
	pending_character[agent] = character
	skynet.call (agent, "lua", "map_enter")
end

function CMD.character_ready (agent, pos)
	if pending_character[agent] == nil then return false end
	online_character[agent] = pending_character[agent]
	pending_character[agent] = nil

	local ok, interest_list, notify_list = aoi.insert (agent, pos)
	if ok == false then return false end

	skynet.call (agent, "lua", "aoi_add", interest_list)

	local t = { agent }
	for _, a in pairs (notify_list) do
		skynet.call (a, "lua", "aoi_add", t)
	end
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (source, ...))
	end)
end)
