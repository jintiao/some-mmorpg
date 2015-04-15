local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"
local sharemap = require "sharemap"

local REQUEST = {}

function REQUEST:aoi_add (list)
	local s = skynet.self ()
	for _, a in pairs (list) do
		skynet.fork (function ()
			local r = skynet.call (a, "lua", "aoi_subscribe", s)
			local reader = sharemap.reader ("character", r)
			self.send_request ("aoi_add", { character = reader })
		end)
	end
end

function REQUEST:aoi_subscribe (from)
	if not self.character_writer then
		self.character_writer = sharemap.writer ("character", self.character)
	end
	return self.character_writer:copy ()
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

