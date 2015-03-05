local constant = require "constant"
local srp = require "srp"

local account = {}
local connection_handler
local id_handler

function account.init (ch, ih)
	connection_handler = ch
	id_handler = ih
end

local function make_user_key (name)
	assert (name)
	return "user:" .. name
end

function account.load (name)
	if not name then
		return
	end

	local acc = { name = name }

	local connection = connection_handler (name)
	local key = make_user_key (name)
	if connection:exists (key) then
		acc.id = connection:hget (key, "account")
		acc.salt = connection:hget (key, "salt")
		acc.verifier = connection:hget (key, "verifier")
	else
		acc.salt, acc.verifier = srp.create_verifier (name, constant.default_password)
	end

	return acc
end

function account.create (name, password)
	local id = id_handler ()
	local connection = connection_handler (name)
	local key = make_user_key (name)
	assert (connection:hsetnx (key, "account", id) ~= 0) 

	local salt, verifier = srp.create_verifier (name, password)
	assert (connection:hmset (key, "salt", salt, "verifier", verifier) ~= 0)

	connection = connection_handler (id)
	assert (connection:sadd ("account:" .. id, name) ~= 0)

	return id
end

return account
