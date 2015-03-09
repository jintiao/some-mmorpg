local skynet = require "skynet"

local handler = {}

local database
local account

local function character_list ()
	local list = skynet.call (database, "lua", "character", "list", account)
	return { character = list }
end

local function character_create (args)
end

function handler.register (user)
	database = skynet.uniqueservice ("database")
	account = user.account
	user.REQUEST.character_list = character_list
	user.REQUEST.character_create = character_create
end

return handler
