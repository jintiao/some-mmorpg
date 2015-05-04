local skynet = require "skynet"
local socket = require "socket"

local logger = require "logger"
local config = require "config.system"


local slave = {}
local nslave
local gameserver = {}

local CMD = {}

function CMD.open (_, conf)
	for i = 1, conf.slave do
		local s = skynet.newservice ("loginslave")
		skynet.call (s, "lua", "init", skynet.self (), i, conf)
		table.insert (slave, s)
	end
	nslave = #slave

	local host = conf.host or "0.0.0.0"
	local port = assert (tonumber (conf.port))
	local sock = socket.listen (host, port)

	logger.logf ("listen on %s:%d", host, port)

	local balance = 1
	socket.start (sock, function (fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > nslave then balance = 1 end

		account, key, token = skynet.call (s, "lua", "auth", fd, addr)
		if account and key and token then
			s = slave[(account % nslave) + 1]
			skynet.call (s, "lua", "cache", account, key, token)
		end
	end)
end

function CMD.register (id, name)
	gameserver[id] = name
end

function CMD.verify (from, account, token)
	local name = gameserver[from]
	local s = slave[(account % nslave) + 1]
	return skynet.call (s, "lua", "verify", account, token, name)
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, from, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (from, ...))
	end)
end)
