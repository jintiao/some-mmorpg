local skynet = require "skynet"
local errno = require "errno"
local gd_data = require "gd_data"

local handler = {}

local database
local account

local function character_list ()
	local list = skynet.call (database, "lua", "character", "list", account)
	return { character = list }
end

local function character_create (args)
	if args and args.name and args.race and args.class then
		local race = args.race
		if race < 1 or race > #gd_data.race then
			return { errno = errno.INVALID_ARGUMENT }
		end
		local class = args.class
		if class < 1 or class > #gd_data.class then
			return { errno = errno.INVALID_ARGUMENT }
		end

		local ch, err = skynet.call (database, "lua", "character", "create", account, args.name, race, class)
		if ch then
			return { character = ch }
		else
			return { errno = err }
		end
	else
		return { errno = errno.INVALID_ARGUMENT }
	end
end

function handler.register (user)
	database = skynet.uniqueservice ("database")
	account = user.account
	user.REQUEST.character_list = character_list
	user.REQUEST.character_create = character_create
end

return handler
