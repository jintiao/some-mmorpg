local skynet = require "skynet"

skynet.start(function()
	local gamed = skynet.newservice ("gamed")
	skynet.call (gamed, "lua", "open")
	skynet.exit ()
end)
