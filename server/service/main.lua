local skynet = require "skynet"
local config = require "config.system"

skynet.start(function()
	skynet.newservice ("debug_console", config.debug_port)

	skynet.uniqueservice ("database")
	skynet.uniqueservice ("protoloader")

	local logind = skynet.newservice ("logind")
	skynet.call (logind, "lua", "open", config.logind)	

	local gamed = skynet.newservice ("gamed", logind)
	skynet.call (gamed, "lua", "open", config.gamed)
end)
