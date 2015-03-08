local skynet = require "skynet"

local handler = {}

local database
local account

local function character_list ()
	if not database then
		database = skynet.uniqueservice ("database")
	end

	local list = skynet.call (database, "lua", "character", "list", account)
	return { character = list }
end

function handler.register (user)
	account = user.account
	user.REQUEST.character_list = character_list
end

return handler
