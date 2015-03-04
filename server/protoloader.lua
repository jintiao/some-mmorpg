local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"

local login_proto = require "login_proto"
local game_proto = require "game_proto"

skynet.start (function ()
	sprotoloader.save (login_proto.c2s, 1)
	sprotoloader.save (login_proto.s2c, 2)
	sprotoloader.save (game_proto.c2s, 3)
	sprotoloader.save (game_proto.s2c, 4)
end)
