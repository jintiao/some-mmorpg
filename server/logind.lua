local loginserver = require "loginserver"
local skynet = require "skynet"
local logger = require "logger"
local config = require "config"

local logind = {}
local gamed = {}

local CMD = {}

function CMD.register (name, source)
	logger.log (string.format ("register %s at %d", name, source))
	gamed[source] = name
end

function CMD.open (conf)
	loginserver.open (conf)
end

function logind.command_handler (cmd, addr, ...)
	local f = CMD[cmd]
	if f then
		f (addr, ...)
	end
end

function logind.connection_handler (fd, addr)
	skynet.timeout (300, function ()
		loginserver.kick (fd)
	end)
end

function logind.auth_handler ()
end

loginserver.start (logind, config.logind)
