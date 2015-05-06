local skynet = require "skynet"
local socketdriver = require "socketdriver"

local gateserver = require "gameserver.gateserver"
local logger = require "logger"
local protoloader = require "protoloader"


local gameserver = {}
local handshake = {}

function gameserver.forward (fd, agent)
	gateserver.forward (fd, agent)
end

function gameserver.kick (fd)
	gateserver.close_client (fd)
end

function gameserver.start (gamed)
	local handler = {}

	local host, send_request = protoloader.load (protoloader.LOGIN)

	function handler.open (source, conf)
		return gamed.open (conf)
	end

	function handler.connect (fd, addr)
		logger.logf ("connect from %s (fd = %d)", addr, fd)
		handshake[fd] = addr
		gateserver.open_client (fd)
	end

	function handler.disconnect (fd)
		logger.logf ("fd (%d) disconnected", fd)
	end

	local function do_login (fd, msg, sz)
		local type, name, args, response = host:dispatch (msg, sz)
		assert (type == "REQUEST")
		assert (name == "login")
		local session = assert (tonumber (args.session))
		local token = assert (args.token)
		local account = gamed.auth_handler (session, token)
		assert (account)

		local package = string.pack (">s2", response { account = account })
		socketdriver.send (fd, package)

		return account
	end

	local traceback = debug.traceback
	function handler.message (fd, msg, sz)
		local addr = handshake[fd]

		if addr then
			handshake[fd] = nil
			local ok, account = xpcall (do_login, traceback, fd, msg, sz)
			if not ok then
				logger.warningf ("%s login failed : %s", addr, account)
				gateserver.close_client (fd)
			else
				logger.logf ("account %d login success", account)
				gamed.login_handler (fd, account)
			end
		else
			gamed.message_handler (fd, msg, sz)
		end
	end

	local CMD = {}

	function CMD.token (id, secret)
		local id = tonumber (id)
		login_token[id] = secret
		skynet.timeout (10 * 100, function ()
			if login_token[id] == secret then
				logger.logf ("account %d token timeout", id)
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
