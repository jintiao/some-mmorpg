local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"
local sharemap = require "sharemap"

local REQUEST = {}

function REQUEST:aoi_add (list)
	local s = skynet.self ()
	for _, a in pairs (list) do
		skynet.fork (function ()
			local reader = skynet.call (a, "lua", "aoi_subscribe", s)
			local c = sharemap.reader ("character", reader)
			self.send_request ("aoi_add", { character = c })

			self.subscribing[c.id] = { character = c, agent = a }
			self.agent2cid[a] = c.id
		end)
	end
end

function REQUEST:aoi_subscribe (agent)
	if not self.character_writer then
		self.character_writer = sharemap.writer ("character", self.character)
	end
	self.subscriber[agent] = agent
	return self.character_writer:copy ()
end

function REQUEST:aoi_remove (agent)
	local id = self.agent2cid[agent]
	assert (id)

	self.send_request ("aoi_remove", { character = id })
	
	self.subscribing[id] = nil
	self.agent2cid[agent] = nil
end

local handler = {}

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

