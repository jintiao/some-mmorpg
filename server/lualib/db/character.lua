local cjson = require "cjson"
local logger = require "logger"

local character = {}
local connection_handler

function character.init (ch)
	connection_handler = ch
end

local function make_account_key (account)
	assert (account)
	local major = math.floor (account / 100)
	local minor = account - major * 100
	return string.format ("account:%d", major), minor
end

function character.list (account)
	local connection = connection_handler (account)
	local key, field = make_account_key (account)
	logger.debug (string.format ("character.list %d, key (%s), field (%d)", account, key, field))

	if not connection:exists (key) then
		logger.debug ("key not exists")
		return 
	end

	local v = connection:hget (key, field)
	if not v then
		logger.debug ("field not exists")
		return 
	end

	return cjson.decode (v)
end

return character

