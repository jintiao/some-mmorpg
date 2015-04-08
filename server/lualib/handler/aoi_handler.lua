local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"
local sharemap = require "sharemap"

local REQUEST = {}

function REQUEST:aoi_add (list)
	logger.log ("aoi_add")
	print_r (list)

	local s = skynet.self ()
	for _, a in pairs (list) do
		skynet.fork (function ()
			local r = skynet.call (a, "lua", "aoi_subscribe", s)
			local reader = sharemap.reader ("character", r)
			reader:update ()
			print "aoi reader"
			print_r (reader)
		end)
	end
end

local subscriber = {}
function REQUEST:aoi_subscribe (from)
	logger.log ("aoi_subscribe from", from)
	table.insert (subscriber, from)
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

