local skynet = require "skynet"
local config = require "config"

skynet.start(function()
	skynet.uniqueservice ("protoloader")
	skynet.uniqueservice ("database")

	local logind = skynet.newservice ("logind")
	local gamed = skynet.newservice ("gamed", logind)
	skynet.call (gamed, "lua", "open", config.gamed)
end)
