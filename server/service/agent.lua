local skynet = require "skynet"
local logger = require "logger"
local sprotoloader = require "sprotoloader"
local socket = require "socket"

local gamed = ...
local database

local host = sprotoloader.load (3):host "package"
local send_request = host:attach (sprotoloader.load (4))

local client_fd
local account

local REQUEST = {}

local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end

local function handle_request (name, args, response)
	local f = REQUEST[name]
	if f then
		ret = f (args)
		if response then
			send_msg (client_fd, response (ret))
		end
	end

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

function CMD.open (fd, id)
	client_fd = fd
	account = id
	local name = string.format ("agnet-%d", id)
	logger.register (name)
	logger.debug (string.format ("agent %d opened", skynet.self ()))
end

function CMD.close ()
	local self = skynet.self ()
	logger.debug (string.format ("agent %d closed", self))
	skynet.call (gamed, "lua", "close", self)
end

skynet.start (function ()
	database = skynet.uniqueservice ("database")
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)

function REQUEST:character_list ()
	local list = skynet.call (database, "lua", "character", "list", account)
	return { character = list }
end
