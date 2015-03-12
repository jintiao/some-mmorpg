local skynet = require "skynet"
local errno = require "errno"
local gd_data = require "gd_data"

local handler = {}
local REQUEST = {}

local database
local user

function REQUEST.character_list ()
	local ok, list = skynet.call (database, "lua", "character", "list", user.account)
	assert (ok, list)
	return { character = list }
end

function REQUEST.character_create (args)
	assert (args, errno.INVALID_ARGUMENT)
	local c = args.character
	assert (c, errno.INVALID_ARGUMENT)
	local name, race, class = c.name, c.race, c.class
	assert (name and #name < 24, errno.INVALID_ARGUMENT)
	assert (race and race > 0 and race <= #gd_data.race, errno.INVALID_ARGUMENT)
	assert (class and class > 0 and class <= #gd_data.class, errno.INVALID_ARGUMENT)

	local ok, ch = skynet.call (database, "lua", "character", "create", user.account, name, race, class)
	assert (ok == true, ok)
		
	return { character = ch }
end

function REQUEST.character_pick (args)
	print "character_pick"
end

function handler.register (u)
	database = skynet.uniqueservice ("database")
	user = u

	local t = user.REQUEST
	for k, v in pairs (REQUEST) do
		t[k] = v
	end
end

function handler.unregister (u)
	assert (user == u)
	user = nil
	local t = u.REQUEST
	for k, _ in pairs (REQUEST) do
		t[k] = nil
	end
end

return handler

