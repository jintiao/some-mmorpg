local skynet = require "skynet"

local syslog = require "syslog"
local aoi = require "map.aoi"


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
	syslog.noticef ("character(%d) loading map", character)

	pending_character[agent] = character
	skynet.call (agent, "lua", "map_enter", skynet.self ())
end

function CMD.character_leave (agent)
	local character = online_character[agent] or pending_character[agent]
	if character ~= nil then
		syslog.noticef ("character(%d) leave map", character)
		local ok, list = aoi.remove (agent)
		if ok then
			skynet.call (agent, "lua", "aoi_manage", nil, list)
		end
	end
	online_character[agent] = nil
	pending_character[agent] = nil
end

function CMD.character_ready (agent, pos)
	if pending_character[agent] == nil then return false end
	online_character[agent] = pending_character[agent]
	pending_character[agent] = nil

	syslog.noticef ("character(%d) enter map", online_character[agent])

	local ok, list = aoi.insert (agent, pos)
	if not ok then return false end

	skynet.call (agent, "lua", "aoi_manage", list)
	return true
end

function CMD.move_blink (agent, pos)
	local ok, add, update, remove = aoi.update (agent, pos)
	if not ok then return end
	skynet.call (agent, "lua", "aoi_manage", add, remove, update, "move")
	return true
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (source, ...))
	end)
end)
