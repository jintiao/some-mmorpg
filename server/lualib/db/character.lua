local logger = require "logger"
local packer = require "db.packer"
local errno = require "errno"

local character = {}
local connection_handler
local id_handler

function character.init (ch, ih)
	connection_handler = ch
	id_handler = ih
end

local function make_list_key (account)
	local major = math.floor (account / 100)
	local minor = account - major * 100
	return connection_handler (account), string.format ("char-list:%d", major), minor
end

local function make_overview_key (c)
	local major = math.floor (c / 100)
	local minor = c - major * 100
	return connection_handler (c), string.format ("char-overview:%d", major), minor
end

local function make_detail_key (c)
	local major = math.floor (c / 100)
	local minor = c - major * 100
	return connection_handler (c), string.format ("char-detail:%d", major), minor
end

local function make_name_key (name)
	return connection_handler (name), "char-name", name
end

local function load_overview (id)
	local connection, key, field = make_overview_key (id)
	local t = connection:hget (key, field)
	if not t then return end
	return packer.unpack (t)
end

local function load_detail (id)
	local connection, key, field = make_detail_key (id)
	local t = connection:hget (key, field)
	if not t then return end
	return packer.unpack (t)
end

function character.load (id)
	local t = {
		overview = load_overview (id),
		detail = load_detail (id),
	}
	return t
end

local function load_list (account)
	local connection, key, field = make_list_key (account)
	local v = connection:hget (key, field)
	if not v then return {} end
	return packer.unpack (v)
end

function character.check (account, id)
	local list = load_list (account)
	return (list[tostring (id)] ~= nil)
end

function character.list (account)
	local list = load_list (account)
	local t = {}
	for _, id in pairs (list) do
		local c = load_overview (id)
		if c then
			table.insert (t, c)
		end
	end
	return t
end

function character.create (account, char)
	local id = id_handler ()
	local connection, key, field = make_name_key (char.overview.appearance.name)
	if connection:hsetnx (key, field, id) == 0 then
		return errno.NAME_ALREADY_USED
	end

	char.overview.id = id

	connection, key, field = make_overview_key (id)
	local v = packer.pack (char.overview)
	connection:hset (key, field, v)

	connection, key, field = make_detail_key (id)
	local v = packer.pack (char.detail)
	connection:hset (key, field, v)

	local list = load_list (account)
	list[id] = id

	connection, key, field = make_list_key (account)
	v = packer.pack (list)
	connection:hset (key, field, v)
	
	return char
end

return character

