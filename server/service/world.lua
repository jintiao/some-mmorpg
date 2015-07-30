local skynet = require "skynet"
local sharedata = require "sharedata"
local syslog = require "syslog"
local mapdata = require "gddata.map"

local CMD = {}
local map_instance = {}
local online_character = {}

function CMD.kick (character)
	local a = online_character[character]
	if a then
		skynet.call (a, "lua", "kick")
		online_character[character] = nil
	end
end

function CMD.character_enter (agent, character)
	if online_character[character] ~= nil then
		syslog.notice (string.format ("multiple login detected, character %d", character))
		CMD.kick (character)
	end

	online_character[character] = agent
	syslog.notice (string.format ("character(%d) enter world", character))
	local map, pos = skynet.call (agent, "lua", "world_enter", skynet.self ())
		
	local m = map_instance[map]
	if not m then
		CMD.kick (character)
		return
	end

	skynet.call (m, "lua", "character_enter", agent, character, pos)
end

function CMD.character_leave (agent, character)
	syslog.notice (string.format ("character(%d) leave world", character))
	online_character[character] = nil
end

skynet.start (function ()
	local self = skynet.self ()
	for _, conf in pairs (mapdata) do
		local name = conf.name
		local s = skynet.newservice ("map", self)
		skynet.call (s, "lua", "init", conf)
		map_instance[name] = s
	end
	
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (source, ...))
	end)
end)
