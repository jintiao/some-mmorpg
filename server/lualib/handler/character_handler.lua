local skynet = require "skynet"
local errno = require "errno"
local sharedata = require "sharedata"

local handler = {}
local REQUEST = {}

local database
local gdd
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
	assert (race and gdd.race[race], errno.INVALID_ARGUMENT)
	assert (class and gdd.class[class], errno.INVALID_ARGUMENT)

	local r = gdd.race[race]
	local pos = {}
	for k, v in pairs (r.pos) do
		pos[k] = v
	end
	local appearance = { name = name, race = race, class = class, map = r.home, pos = pos }
	local ok, ch = skynet.call (database, "lua", "character", "create", user.account, appearance)
	assert (ok == true, ch)
		
	return { character = ch }
end

function REQUEST.character_pick (args)
	assert (args, errno.INVALID_ARGUMENT)
	local id = assert (args.id, errno.INVALID_ARGUMENT)

	local ok, success = skynet.call (database, "lua", "character", "check", user.account, id)
	assert (ok and success, errno.CHARACTER_NOT_EXISTS)

	local world = skynet.uniqueservice ("world")	
	ok = skynet.call (world, "lua", "enter", id)
	if ok then
		handler.unregister (user)
	end
end

function handler.register (u)
	database = skynet.uniqueservice ("database")
	gdd = sharedata.query "gdd"
	user = u

	local t = user.REQUEST
	for k, v in pairs (REQUEST) do
		t[k] = v
	end
end

function handler.unregister (u)
	print ("unregister")
	assert (user == u)
	user = nil
	local t = u.REQUEST
	for k, _ in pairs (REQUEST) do
		t[k] = nil
	end
end

return handler

