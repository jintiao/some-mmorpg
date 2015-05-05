local skynet = require "skynet"

local config = require "config.system"
local login_config = require "config.loginserver"
local game_config = require "config.gameserver"

skynet.start(function()
	skynet.newservice ("debug_console", config.debug_port)
	skynet.newservice ("protod")
	skynet.uniqueservice ("database")

	local loginserver = skynet.newservice ("loginserver")
	skynet.call (loginserver, "lua", "open", login_config)	

	local gamed = skynet.newservice ("gamed", loginserver)
	skynet.call (gamed, "lua", "open", game_config)
end)
