local skynet = require "skynet"
local config = require "config.system"

skynet.start(function()
	skynet.newservice ("debug_console", 8000)

	skynet.uniqueservice ("gdd")
	skynet.uniqueservice ("database")
	skynet.uniqueservice ("protoloader")
	skynet.uniqueservice ("world")

	local logind = skynet.newservice ("logind")
	local gamed = skynet.newservice ("gamed", logind)
	skynet.call (gamed, "lua", "open", config.gamed)
end)
