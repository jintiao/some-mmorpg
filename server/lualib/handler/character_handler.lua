local skynet = require "skynet"
local errno = require "errno"
local sharedata = require "sharedata"
local dbpacker = require "db.packer"

local database
local gdd

local handler = {}
local REQUEST = {}

local function load_list (account)
	local list
	ok, list = skynet.call (database, "lua", "character", "list", account)
	if not ok then
		list = {}
	else
		list = dbpacker.unpack (list)
	end
	return list
end

function REQUEST:character_list ()
	local list = load_list (self.account)
	local character = {}
	for _, id in pairs (list) do
		local ok, c = skynet.call (database, "lua", "character", "load", id)
		if ok then
			character[id] = dbpacker.unpack (c)
		end
	end
	return { character = character }
end

local function create (id, name, race, class)
	if not id or not name or not race or not class then return end

	local r = gdd.race[race]
	if not r then return end

	local c = gdd.class[class]
	if not c then return end

	local character = { 
		id = id,
		general = {
			name = name,
			race = race,
			class = class,
			map = r.home,
		}, 
		attribute = {
			level = 1,
			exp = 0,
		},
		movement = {
			mode = 0,
			pos = { x = r.pos_x, y = r.pos_y, z = r.pos_z, o = r.pos_o },
		},
	}
	return character
end

function REQUEST:character_create (args)
	assert (args, errno.INVALID_ARGUMENT)
	local c = args.character
	assert (c, errno.INVALID_ARGUMENT)
	local name = c.name
	assert (name and #name < 24, errno.INVALID_ARGUMENT)

	local ok
	ok, id = skynet.call (database, "lua", "character", "reserve", name)
	assert (ok, errno.NAME_ALREADY_USED)

	local character = create (id, name, c.race, c.class)
	assert (character, errno.INVALID_ARGUMENT)

	local json = dbpacker.pack (character)
	skynet.call (database, "lua", "character", "save", id, json)

	local list = load_list (self.account)
	list[id] = id
	json = dbpacker.pack (list)
	skynet.call (database, "lua", "character", "savelist", self.account, json)

	return { character = character }
end

function REQUEST:character_pick (args)
	assert (args, errno.INVALID_ARGUMENT)
	local id = assert (args.id, errno.INVALID_ARGUMENT)

	local list = load_list (self.account)
	assert (list[tostring (id)] ~= nil, errno.CHARACTER_NOT_EXISTS)

	local ok, c = skynet.call (database, "lua", "character", "load", id)
	assert (ok, errno.CHARACTER_NOT_EXISTS)

	local character = dbpacker.unpack (c)
	self.character = character

	local world = skynet.uniqueservice ("world")
	skynet.call (world, "lua", "character_enter", id)

	return { character = character }
end

function handler.save (character)
	if not character then return end

	local data = dbpacker.pack (character)
	skynet.call (database, "lua", "character", "save", character.id, data)
end

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

