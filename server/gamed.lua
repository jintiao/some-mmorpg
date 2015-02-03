local gameserver = require "gameserver"
local skynet = require "skynet"

local logind = tonumber (...)

local gamed = {}

function gamed.open (name)
	skynet.call (logind, "lua", "register", name, skynet.self ())	
end

gameserver.start (gamed)
