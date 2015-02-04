local loginserver = require "loginserver"
local skynet = require "skynet"
local logger = require "logger"
local config = require "config"

local logind = {}
local gamed = {}

function logind.auth_handler ()
end

local CMD = {}

function CMD.register (name, source)
	logger.log ("register gamed", source, name)
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

loginserver.start (logind, config.logind)
