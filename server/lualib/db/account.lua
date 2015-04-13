local constant = require "constant"
local errno = require "errno"
local srp = require "srp"

--[[
user:helloworld
	account = 1
	salt = xxxx
	verifier = yyyy
]]--

local account = {}
local connection_handler
local id_handler

function account.init (ch, ih)
	connection_handler = ch
	id_handler = ih
end

local function make_key (name)
	return connection_handler (name), string.format ("user:%s", name)
end

function account.load (name)
	assert (name, errno.INVALID_ARGUMENT)

	local acc = { name = name }

	local connection, key = make_key (name)
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
	assert (name and #name < 24 and password and #password < 24, errno.INVALID_ARGUMENT)
	
	local id = id_handler ()
	local connection, key = make_key (name)
	if connection:hsetnx (key, "account", id) == 0 then
		error (errno.ACCOUNT_EXISTS)
	end

	local salt, verifier = srp.create_verifier (name, password)
	if connection:hmset (key, "salt", salt, "verifier", verifier) == 0 then
		error (errno.INTERNAL_ERROR)
	end

	return id
end

return account
