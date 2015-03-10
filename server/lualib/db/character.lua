local logger = require "logger"
local packer = require "db.packer"
local errno = require "errno"

--[[
account:0
	1 : { 222, 333 }

character:2
	22 : { id = 222, name = "hello", race = 1, class = 1 }

character:3
	33 : { id = 333, name = "world", race = 1, class = 2 }

name:hello
	222

name:world
	333
]]--

local character = {}
local connection_handler
local id_handler

function character.init (ch, ih)
	connection_handler = ch
	id_handler = ih
end

local function make_account_key (account)
	local major = math.floor (account / 100)
	local minor = account - major * 100
	return connection_handler (account), string.format ("account:%d", major), minor
end

local function make_character_key (c)
	local major = math.floor (c / 100)
	local minor = c - major * 100
	return connection_handler (c), string.format ("character:%d", major), minor
end

local function make_name_key (name)
	return connection_handler (name), string.format ("name:%s", name)
end

function character.list (account)
	local connection, key, field = make_account_key (account)
	local v = connection:hget (key, field)
	if not v then
		return
	end
	return packer.unpack (v)
end

function character.create (account, name, race, class)
	local id = id_handler ()
	local connection, key = make_name_key (name)
	if connection:setnx (key, id) == 0 then
		return errno.NAME_ALREADY_USED
	end

	local field
	connection, key, field = make_character_key (id)
	local t = { id = id, name = name, race = race, class = clss }
	local v = packer.pack (t)
	connection:hset (key, field, v)

	local list = character.list (account)
	if not list then
		list = {}
	end
	table.insert (list, id)
	connection:hset (key, field, packer.pack (list))
	
	return t
end

return character

