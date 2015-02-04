local skynet = require "skynet"
local socket = require "socket"
local logger = require "logger"

local loginserver = {}

local function launch_slave (handler)
	logger.log ("loginserver slave opened")
end

local function accept (logind, conf, s, fd, addr)
	local ok = skynet.call (s, "lua", fd, addr)
end

local function launch_master (logind, ninstance)
	local slave = {}
	for i = 1, ninstance do
		table.insert (slave, skynet.newservice (SERVICE_NAME))
	end

	skynet.dispatch ("lua", function (_, source, cmd, ...)
		skynet.retpack (logind.command_handler (cmd, ...))
	end)
end

function loginserver.open (conf)
	local balance = 1
	local host = conf.host or "0.0.0.0"
	local port = tonumber (conf.port)
	local sock = socket.listen (host, port)
	logger.log (string.format ("listen at %s:%d", host, port))
	socket.start (sock, function (fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > #slave then
			balance = 1
		end

		local ok, err = pcall (accept, logind, conf, s, fd, addr)
		if not ok then
		end
		socket.close (fd)
	end)
end

function loginserver.start (logind, conf)
	local name = "." .. conf.name

	skynet.start (function ()
		local master = skynet.localname (name)
		if master then
			logger.register ("loginserver.slave")
			return launch_slave (logind.auth_handler)
		else
			skynet.register (name)
			logger.register ("loginserver.master")
			return launch_master (logind, conf.ninstance)
		end
	end)
end

return loginserver
