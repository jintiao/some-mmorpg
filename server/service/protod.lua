local skynet = require "skynet"

local protoloader = require "protoloader"

skynet.start (function ()
	protoloader.init ()
end)
