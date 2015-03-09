local cjson = require "cjson"
local logger = require "logger"

local character = {}
local connection_handler

function character.init (ch)
	connection_handler = ch
end

local function make_key (account)
	local major = math.floor (account / 100)
	local minor = account - major * 100
	return connection_handler (account), string.format ("account:%d", major), minor
end

function character.list (account)
	local connection, key, field = make_key (account)
	logger.debug (string.format ("character.list account (%d), key (%s), field (%d)", account, key, field))

	local v = connection:hget (key, field)
	if not v then
		return
	end
	return cjson.decode (v)
end

function character.create (account, name, race, class)
	local connection, key, field = make_key (account)
end

return character

