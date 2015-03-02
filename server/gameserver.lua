local gateserver = require "gateserver"
local skynet = require "skynet"
local logger = require "logger"
local sproto = require "sproto"
local login_proto = require "login_proto"

local gameserver = {}

local login_token = {}
local handshake = {}

function gameserver.forward (fd, agent)
	gateserver.forward (fd, agent)
end

function gameserver.start (gamed)
	local handler = {}

	local host = sproto.new (login_proto.c2s):host "package"
	local send_request = host:attach (sproto.new (login_proto.s2c))

	function handler.open (source, conf)
		return gamed.open (conf.name)
	end

	function handler.connect (fd, addr)
		handshake[fd] = addr
		gateserver.open_client (fd)
	end

	function handler.disconnect (fd)
		print (string.format ("fd (%d) disconnected"))
	end

	local function do_login (msg, sz, addr)
		assert (addr)
		local type, name, args, response = host:dispatch (msg, sz)
		assert (type == "REQUEST")
		assert (name == "login")
		local account = assert (tonumber (args.account))
		local secret = assert (login_token[account])
		assert (secret == args.token)
		return account
	end

	function handler.message (fd, msg, sz)
		local addr = handshake[fd]
		handshake[fd] = nil

		local ok, account = pcall (do_login, msg, sz, addr)
		if not ok then
			logger.log (string.format ("%s login failed", addr))
			gateserver.close_client (fd)
		else
			logger.log (string.format ("account %d login success", account))
			gamed.login_handler (fd, account)
		end
	end

	local CMD = {}

	function CMD.token (id, secret)
		logger.log (string.format ("account %d auth finished", id)) 
		local id = tonumber (id)
		login_token[id] = secret
		skynet.timeout (10 * 100, function ()
			if login_token[id] == secret then
				logger.debug (string.format ("account %d token timeout", id))
				login_token[id] = nil
			end
		end)
	end

	function handler.command (cmd, ...)
		local f = CMD[cmd]
		if f then
			return f (...)
		else
			return gamed.command_handler (cmd, ...)
		end
	end

	return gateserver.start (handler)
end

return gameserver
