local skynet = require "skynet"
local socket = require "socket"
local logger = require "logger"
local sprotoloader = require "sprotoloader"
local srp = require "srp"
local aes = require "aes"
local config = require "config.system"
local constant = require "constant"

local loginserver = {}
local slave = {}
local nslave
local connection = {}
local active_account = {}

local master
local command_handler
local connection_handler
	
local function close (fd)
	socket.close (fd)
	connection[fd] = nil
end


local function launch_slave ()
	local host = sprotoloader.load (1):host "package"
	local send_request = host:attach (sprotoloader.load (2))
	local database = skynet.uniqueservice ("database")

	local function read (fd, size)
		return socket.read (fd, size) or error ()
	end

	local function read_msg (fd)
		local s = read (fd, 2)
		local size = s:byte(1) * 256 + s:byte(2)
		local msg = read (fd, size)
		return host:dispatch (msg, size)
	end

	local function send_msg (fd, msg)
		local package = string.pack (">s2", msg)
		socket.write (fd, package)
	end

	local CMD = {}

	local function do_auth (fd, addr)
		fd = assert (tonumber (fd))
		connection[fd] = addr
		connection_handler (fd, addr)
		logger.log (string.format ("connect from %s (fd = %d)", addr, fd))

		socket.start (fd)
		socket.limit (fd, 8192)

		local type, name, args, response = read_msg (fd)
		assert (type == "REQUEST")
		assert (name == "handshake")
		assert (args)
		assert (args.name)
		assert (args.client_pub)
		assert (response)

		local ok, account = skynet.call (database, "lua", "account", "load", args.name)
		assert (ok and account)
		local session_key, _, pub = srp.create_server_session_key (account.verifier, args.client_pub)
		local ret = { user_exists = (account.id ~= nil),salt = account.salt, server_pub = pub }
		send_msg (fd, response (ret))

		type, name, args, response = read_msg (fd)
		assert (type == "REQUEST")
		assert (name == "auth")
		assert (args)
		assert (args.name)
		assert (response)

		local realname = aes.decrypt (args.name, session_key)
		assert (realname == account.name)
		
		local id = tonumber (account.id)
		if not id then
			assert (args.password)
			local password = aes.decrypt (args.password, session_key)
			_, id = skynet.call (database, "lua", "account", "create", realname, password)
		end
		assert (id)

		local token = skynet.call (master, "lua", "login", id)
		send_msg (fd, response ({ account = id, token = token }))
	end

	function CMD.auth (fd, addr)
		local ok, err =  pcall (do_auth, fd, addr)
		if not ok then
			logger.log (string.format ("connection %s (fd = %d) auth failed! err : %s", addr, fd, err))
		end
		close (fd)
	end

	function CMD.save (account, token)
		active_account[account] = token
		skynet.timeout (100 * 60 * 30, function ()
			if active_account[account] == token then
				active_account[account] = nil
				skynet.log (string.format ("account %d token timeout.", account))
			end
		end)
	end

	function CMD.verify (account, token)
		if active_account[account] == token then
			return true
		end
	end

	skynet.dispatch ("lua", function (_, _, cmd, ...)
		local f = assert (CMD[cmd])
		skynet.retpack (f (...))
	end)
end

local function launch_master (ninstance)
	for i = 1, ninstance do
		table.insert (slave, skynet.newservice (SERVICE_NAME))
	end
	nslave = #slave

	local function verify (account, token)
		local s = slave[(account % nslave) + 1]
		local ok = skynet.call (s, "lua", "verify", account, token)
		return ok
	end

	skynet.dispatch ("lua", function (_, _, cmd, ...)
		if cmd == "verify" then
			skynet.retpack (verify (...))
		else
			skynet.retpack (command_handler (cmd, ...))
		end
	end)
end

function loginserver.open (conf)
	local balance = 1
	local host = conf.host or "0.0.0.0"
	local port = tonumber (conf.port)
	local sock = socket.listen (host, port)
	logger.log (string.format ("listen on %s:%d", host, port))
	socket.start (sock, function (fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > nslave then
			balance = 1
		end
		skynet.call (s, "lua", "auth", fd, addr)
	end)
end

function loginserver.kick (fd)
	if connection[fd] then
		logger.warning (string.format ("connection %s (fd = %d) auth timeout!", connection[fd], fd))
		close (fd)
	end
end

function loginserver.save (account, token)
	local s = slave[(account % nslave) + 1]
	skynet.call (s, "lua", "save", account, token)
end


function loginserver.start (logind, conf)
	local name = "." .. conf.name

	skynet.start (function ()
		master = skynet.localname (name)
		if master then
			logger.register ("loginserver.slave")
			connection_handler = logind.connection_handler
			return launch_slave ()
		else
			skynet.register (name)
			logger.register ("loginserver.master")
			command_handler = logind.command_handler
			return launch_master (conf.ninstance)
		end
	end)
end

return loginserver
