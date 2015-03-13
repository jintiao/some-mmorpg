local skynet = require "skynet"
local sharedata = require "sharedata"
local logger = require "logger"

local CMD = {}
local map = {}

function CMD.enter (agent, character, m)
	logger.log (string.format ("character (%d) try to enter, agent (%d)", character, agent))
end

skynet.start (function ()
	local self = skynet.self ()
	local gdd = sharedata.query "gdd"
	local m = gdd.map
	for _, conf in pairs (m) do
		local name = conf.name
		map[name] = skynet.newservice ("map", self, name) 
	end
	
	skynet.dispatch ("lua", function (_, source, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (source, ...))
	end)
end)
