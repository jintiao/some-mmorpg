local skynet = require "skynet"
local socket = require "socket"
local logger = require "logger"
local sproto = require "sproto"
local login_proto = require "login_proto"

local loginserver = {}
local slave = {}
local connection = {}

local command_handler
local connection_handler
local auth_handler
	
local function close (fd)
	socket.close (fd)
	connection[fd] = nil
end


local function launch_slave ()
	local host = sproto.new (login_proto.c2s):host "package"
	local send_request = host:attach (sproto.new (login_proto.s2c))

	local function read (fd, size)
		return socket.read (fd, size) or error ()
	end

	local function read_msg (fd)
		local s = read (fd, 2)
		local size = s:byte(1) * 256 + s:byte(2)
		logger.debug (string.format ("read_msg size : %d", size))
		local msg = read (fd, size)
		return host:dispatch (msg, size)
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
		assert (args.name)
--		assert (args.client_pub)

		type, name, args, response = read_msg (fd)

		auth_handler ()
	end

	skynet.dispatch ("lua", function (_, _, fd, addr)
		if not pcall (auth, fd, addr) then
			logger.log (string.format ("connection %s (fd = %d) auth failed!", addr, fd))
		end
		close (fd)
		skynet.ret ()
	end)
end

local function launch_master (ninstance)
	for i = 1, ninstance do
		table.insert (slave, skynet.newservice (SERVICE_NAME))
	end

	skynet.dispatch ("lua", function (_, source, cmd, ...)
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
		local master = skynet.localname (name)
		if master then
			logger.register ("loginserver.slave")
			connection_handler = logind.connection_handler
			auth_handler = logind.auth_handler
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
