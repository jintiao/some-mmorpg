local skynet = require "skynet"
local sharedata = require "sharedata"
local logger = require "logger"

local CMD = {}
local map_instance = {}

function CMD.enter (agent, character, map)
	logger.log (string.format ("character (%d) try to enter (%s), from agent (%d)", character, map, agent))
	
	local m = map_instance[map]
	if not m then
		logger.warning (string.format ("character (%d) trying to enter a none exist map (%s)", character, map))
	else
		skynet.call (m, "lua", "enter", character, agent)
	end
end

skynet.start (function ()
	local self = skynet.self ()
	local gdd = sharedata.query "gdd"
	local map = gdd.map
	for _, t in pairs (map) do
		local conf = {}
		for k, v in pairs (t) do
			conf[k] = v
		end
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
