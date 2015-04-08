local skynet = require "skynet"
local errno = require "errno"
local sharedata = require "sharedata"

local database
local gdd

local REQUEST = {}

function REQUEST:character_list ()
	local ok, list = skynet.call (database, "lua", "character", "list", self.account)
	assert (ok, list)
	return { character = list }
end

function REQUEST:character_create (args)
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

	local character = { 
		overview = {
			appearance = { name = name, race = race, class = class },
			level = 1,
			map = r.home,
		}, 
		detail = {
			exp = 0,
			pos = pos,
		},
	}
	local ok
	ok, character = skynet.call (database, "lua", "character", "create", self.account, character)
	assert (ok == true, character)

	return { character = character.overview }
end

function REQUEST:character_pick (args)
	assert (args, errno.INVALID_ARGUMENT)
	local id = assert (args.id, errno.INVALID_ARGUMENT)

	local ok, success = skynet.call (database, "lua", "character", "check", self.account, id)
	assert (ok and success, errno.CHARACTER_NOT_EXISTS)

	local character
	ok, character = skynet.call (database, "lua", "character", "load", id)
	assert (ok and success, errno.CHARACTER_NOT_EXISTS)

	self.character = character

	local world = skynet.uniqueservice ("world")
	skynet.call (world, "lua", "character_enter", character.overview.id, character.overview.map, character.detail.pos)

	return { character = character }
end

local handler = {}

function handler:register ()
	database = skynet.uniqueservice ("database")
	gdd = sharedata.query "gdd"

	local t = self.REQUEST
	for k, v in pairs (REQUEST) do
		t[k] = v
	end
end

function handler:unregister ()
	local t = self.REQUEST
	for k, _ in pairs (REQUEST) do
		t[k] = nil
	end
end

return handler

