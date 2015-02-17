local loginserver = require "loginserver"
local skynet = require "skynet"
local logger = require "logger"
local config = require "config"
local srp = require "srp"
local aes = require "aes"

local logind = {}
local gamed 

local CMD = {}

function CMD.register (name, source)
	logger.log (string.format ("register %s at %d", name, source))
	gamed = source
end

function CMD.open (conf)
	loginserver.open (conf)
end

function CMD.login (id, key)
	local token = srp.random ()
	local secret = aes.encrypt (token, key)
	skynet.call (gamed, "lua", "token", id, secret)
	return token
end

function logind.command_handler (cmd, ...)
	local f = assert (CMD[cmd])
	return f (...)
end

function logind.connection_handler (fd, addr)
	skynet.timeout (300, function ()
		loginserver.kick (fd)
	end)
end

loginserver.start (logind, config.logind)
