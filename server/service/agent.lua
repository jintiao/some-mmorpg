local skynet = require "skynet"
local queue = require "skynet.queue"
local logger = require "logger"
local sprotoloader = require "sprotoloader"
local socket = require "socket"
local character_handler = require "handler.character_handler"
local world_handler = require "handler.world_handler"
local map_handler = require "handler.map_handler"

local gamed = ...
local database

local host = sprotoloader.load (3):host "package"
local pack_request = host:attach (sprotoloader.load (4))

local user
local client_fd
local REQUEST

local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end

local session = {}
local session_id = 0
local function send_request (name, args)
	session_id = session_id + 1
	local str = pack_request (name, args, session_id)
	send_msg (client_fd, str)
	session[session_id] = { name = name, args = args }
end

local function handle_request (name, args, response)
	local f = REQUEST[name]
	if f then
		local ok, ret = pcall (f, args)
		if not ok then
			logger.warning (string.format ("handle message failed : %s", name), ret) 
		else
			if response and ret then
				send_msg (client_fd, response (ret))
			end
		end
	else
		logger.warning (string.format ("unhandled message : %s", name)) 
	end
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
		else
			print ("invalid message type", type)
		end
	end,
}

local CMD = {}

function CMD.open (fd, account)
	user = { 
		fd = fd, 
		account = account,
		REQUEST = {}
	}
	client_fd = user.fd
	REQUEST = user.REQUEST
	character_handler.register (user)

	local name = string.format ("agnet-%d", account)
	logger.register (name)
	logger.debug (string.format ("agent %d opened", skynet.self ()))
end

function CMD.close ()
	local self = skynet.self ()
	logger.debug (string.format ("agent %d closed", self))
	user = nil
	skynet.call (gamed, "lua", "close", self)
end

function CMD.kick ()
	logger.debug (string.format ("agent %d kicked", self))
end

function CMD.world_enter ()
	world_handler.register (user)
end

function CMD.map_enter (map, pos)
	map_handler.register (user)
	send_request ("map_enter", { map = map, pos = pos })
end

function CMD.map (name, ...)
	local f = assert (REQUEST[name])
	local ok, ret = pcall (f, ...)
	if not ok then
		logger.warning (string.format ("handle message failed : %s", name), ret) 
	end
	return ret
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)

