local gateserver = require "gateserver"
local skynet = require "skynet"
local logger = require "logger"
local login_proto = require "login_proto"

local gameserver = {}

local auth = {}
local handshake = {}

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

	local function do_login (fd, msg, sz)
	end

	function handler.message (fd, msg, sz)
		if handshake[fd] then
			local ok = pcall (do_login, fd, msg, sz)

		else
		end
	end

	local CMD = {}

	function CMD.login (id, secret)
		logger.log (string.format ("account %d auth finished", id)) 
		auth[id] = secret
		skynet.timeout (10 * 100, function ()
			if auth[id] == secret then
				auth[id] = nil
			end
		end)
	end

	function handler.command (cmd, ...)
		local f = assert (CMD[cmd])
		return f (...)
	end

	return gateserver.start (handler)
end

return gameserver
