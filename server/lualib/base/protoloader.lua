local sprotoloader = require "sprotoloader"

local loginp = require "proto.login_proto"
local gamep = require "proto.game_proto"

local loader = {
	GAME_TYPES = 0,

	LOGIN = 1,
	LOGIN_C2S = 1,
	LOGIN_S2C = 2,

	GAME = 3,
	GAME_C2S = 3,
	GAME_S2C = 4,
}

function loader.init ()
	sprotoloader.save (gamep.types, loader.GAME_TYPES)

	sprotoloader.save (loginp.c2s, loader.LOGIN_C2S)
	sprotoloader.save (loginp.s2c, loader.LOGIN_S2C)

	sprotoloader.save (gamep.c2s, loader.GAME_C2S)
	sprotoloader.save (gamep.s2c, loader.GAME_S2C)
end

function loader.load (index)
	local host = sprotoloader.load (index):host "package"
	local request = host:attach (sprotoloader.load (index + 1))
	return host, request
end

return loader
