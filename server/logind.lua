local login = require "loginserver"
local skynet = require "skynet"
local config = require "config"

local logind = {}

function logind.auth_handler ()
end

function logind.command_handler ()
end

login (logind, config.logind)
