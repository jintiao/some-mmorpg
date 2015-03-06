local cjson = require "cjson"

local character = {}
local connection_handler

function character.init (ch)
	connection_handler = ch
end

local function make_account_key (account)
	assert (account)
	return "account:" .. name
end

function character.list (account)
	local t = {}
	table.insert (t, 123)
	table.insert (t, 234)
	local a = cjson.encode (t)
	local v = cjson.decode (a)
	return v
end

return character

