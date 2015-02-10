local skynet = require "skynet"
local socket = require "socket"
local logger = require "logger"
local sproto = require "sproto"
local srp = require "srp"
local aes = require "aes"
local login_proto = require "login_proto"
local config = require "config"
local constant = require "constant"

local loginserver = {}
local slave = {}
local connection = {}

local master
local command_handler
local connection_handler
	
local function close (fd)
	socket.close (fd)
	connection[fd] = nil
end


local function launch_slave ()
	local host = sproto.new (login_proto.c2s):host "package"
	local send_request = host:attach (sproto.new (login_proto.s2c))
	local database = config.database

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

	local function auth (fd, addr)
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

		local account = skynet.call (database, "lua", "load", args.name)
		assert (account)
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
		
		local id = account.id
		if not id then
			assert (args.password)
			local password = aes.decrypt (args.password, session_key)
			id = skynet.call (database, "lua", "create", realname, password)
		end
		assert (id)

		local token = skynet.call (master, "lua", "login", id, session_key)
		send_msg (fd, response ({ account = id, token = token }))
	end

	skynet.dispatch ("lua", function (_, _, fd, addr)
		local ok, err =  pcall (auth, fd, addr)
		if not ok then
			logger.log (string.format ("connection %s (fd = %d) auth failed! err : %s", addr, fd, err))
		end
		close (fd)
		skynet.ret ()
	end)
end

local function launch_master (ninstance)
	for i = 1, ninstance do
		table.insert (slave, skynet.newservice (SERVICE_NAME))
	end

	skynet.dispatch ("lua", function (_, _, cmd, ...)
		skynet.retpack (command_handler (cmd, ...))
	end)
end

function loginserver.open (conf)
	local balance = 1
	local nslave = #slave
	local host = conf.host or "0.0.0.0"
	local port = tonumber (conf.port)
	local sock = socket.listen (host, port)
	logger.log (string.format ("listen at %s:%d", host, port))
	socket.start (sock, function (fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > nslave then
			balance = 1
		end
		skynet.call (s, "lua", fd, addr)
	end)
end

function loginserver.kick (fd)
	if connection[fd] then
		logger.warning (string.format ("connection %s (fd = %d) auth timeout!", connection[fd], fd))
		close (fd)
	end
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
