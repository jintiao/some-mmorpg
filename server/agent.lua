local skynet = require "skynet"
local logger = require "logger"
local sproto = require "sproto"
local game_proto = require "game_proto"

local gamed = ...

local host = sproto.new (game_proto.c2s):host "package"
local send_request = host:attach (sproto.new (game_proto.s2c))

local function handle_request (name, args)
	print ("handle_request", name)
	if args then
		for k, v in pairs (args) do
			print (k, v)
		end
	end
end

local function handle_response (id, args)
	print ("handle_response", id)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch (msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			handle_request (...)
		elseif type == "RESPONSE" then
			handle_response (...)
		else
			print ("invalid message type", type)
		end
	end,
}

local CMD = {}

function CMD.open (account)
	local name = string.format ("agnet-%d", account)
	logger.register (name)
	logger.log (string.format ("agent %d opened", skynet.self ()))
end

function CMD.close ()
	skynet.call (gamed, "lua", "close", skynet.self ())
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)
