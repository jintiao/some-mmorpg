local skynet = require "skynet"
local socket = require "socket"

local syslog = require "syslog"
local config = require "config.system"


local session_id = 1
local slave = {}
local nslave
local gameserver = {}

local CMD = {}

function CMD.open (conf)
	for i = 1, conf.slave do
		local s = skynet.newservice ("loginslave")
		skynet.call (s, "lua", "init", skynet.self (), i, conf)
		table.insert (slave, s)
	end
	nslave = #slave

	local host = conf.host or "0.0.0.0"
	local port = assert (tonumber (conf.port))
	local sock = socket.listen (host, port)

	syslog.noticef ("listen on %s:%d", host, port)

	local balance = 1
	socket.start (sock, function (fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > nslave then balance = 1 end

		skynet.call (s, "lua", "auth", fd, addr)
	end)
end

function CMD.save_session (account, key, challenge)
	session = session_id
	session_id = session_id + 1

	s = slave[(session % nslave) + 1]
	skynet.call (s, "lua", "save_session", session, account, key, challenge)
	return session
end

function CMD.challenge (session, challenge)
	s = slave[(session % nslave) + 1]
	return skynet.call (s, "lua", "challenge", session, challenge)
end

function CMD.verify (session, token)
	local s = slave[(session % nslave) + 1]
	return skynet.call (s, "lua", "verify", session, token)
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)
