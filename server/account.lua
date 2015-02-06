local constant = require "constant"
local srp = require "srp"

local account = {}

account.connection_handler = nil

local function make_user_key (name)
	assert (name)
	return "user:" .. name
end

local function exist_user (name)
	assert (name)

	local connection = account.connection_handler (name)
	local key = make_user_key (name)
	return connection.exists (key)
end

function account.load (name)
	if not name then
		return
	end

	local acc = { name = name }

	local connection = account.connection_handler (name)
	local key = make_user_key (name)

	if connection:exists (key) then
		acc.id = connection:hget (key, "id")
		acc.salt = connection:hget (key, "salt")
		acc.verifier = connection:hget (key, "verifier")
	else
		acc.salt, acc.verifier = srp.create_verifier (name, constant.default_password)
	end

	return acc
end

return account
