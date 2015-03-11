local skynet = require "skynet"
local errno = require "errno"
local gd_data = require "gd_data"

local handler = {}

local database
local CMD = {}

function CMD:character_list ()
	local ok, list = skynet.call (database, "lua", "character", "list", self.account)
	assert (ok, list)
	return { character = list }
end

function CMD:character_create (args)
	assert (args, errno.INVALID_ARGUMENT)
	local name, race, class = args.name, args.race, args.class
	assert (name and #name < 24, errno.INVALID_ARGUMENT)
	assert (race and race > 0 and race <= #gd_data.race, errno.INVALID_ARGUMENT)
	assert (class and class > 0 and class <= #gd_data.class, errno.INVALID_ARGUMENT)

	local ok, ch = skynet.call (database, "lua", "character", "create", self.account, name, race, class)
	assert (ok == true, ok)
		
	return { character = ch }
end

function CMD:character_pick (args)
	print "character_pick"
end

function handler.register (user)
	database = skynet.uniqueservice ("database")

	local request = user.REQUEST
	for k, f in pairs (CMD) do
		request[k] = f
	end
end

function handler.unregister (user)
	local request = user.REQUEST
	for k, _ in pairs (CMD) do
		request[k] = nil
	end
end

return handler

