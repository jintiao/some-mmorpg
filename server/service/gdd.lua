local skynet = require "skynet"
local sharedata = require "sharedata"
local gdd = require "gddata.gdd"

skynet.start (function ()
	sharedata.new ("gdd", gdd)
end)
