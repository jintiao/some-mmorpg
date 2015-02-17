local gateserver = require "gateserver"
local skynet = require "skynet"
local logger = require "logger"
local sproto = require "sproto"
local login_proto = require "login_proto"

local gameserver = {}

local login_token = {}
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

	local function do_login (msg, sz)
		local type, name, args, response = host:dispatch (msg, sz)
		assert (type == "REQUEST")
		assert (name == "login")
		local account = assert (tonumber (args.account))
		print ("do_login account", account, args.token)
		local secret = assert (login_token[account])
		assert (secret == args.token)
		return account
	end

	function handler.message (fd, msg, sz)
		if handshake[fd] then
			local ok, account = pcall (do_login, msg, sz)
			if not ok then
				gateserver.close_client (fd)
			else
				logger.log (string.format ("account %d login success", account))
			end
		end
	end

	local CMD = {}

	function CMD.token (id, secret)
		logger.log (string.format ("account %d auth finished, token = [%s]", id, secret)) 
		login_token[tonumber (id)] = secret
		skynet.timeout (10 * 100, function ()
			if login_token[id] == secret then
				logger.debug (string.format ("account %d token timeout", id))
				login_token[id] = nil
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
