local skynet = require "skynet"
local redis = require "redis"
local config = require "config.system"
local database_config = require "config.database_config"
local account = require "db.account"
local character = require "db.character"

local center
local group = {}
local ngroup

local function hash_str (str)
	local hash = 0
	string.gsub (str, "(%w)", function (c)
		hash = hash + string.byte (c)
	end)
	return hash
end

local function hash_num (num)
	local hash = num << 8
	return hash
end

function connection_handler (key)
	local hash
	local t = type (key)
	if t == "string" then
		hash = hash_str (key)
	else
		hash = hash_num (assert (tonumber (key)))
	end

	return group[hash % ngroup + 1]
end

function id_handler ()
	return center:incr ("naccount")
end

local MODULE = {}
local function module_init (name, mod)
	MODULE[name] = mod
	mod.init (connection_handler, id_handler)
end

skynet.start (function ()
	module_init ("account", account)
	module_init ("character", character)

	center = redis.connect (database_config.center)
	ngroup = #database_config.group
	for _, c in ipairs (database_config.group) do
		table.insert (group, redis.connect (c))
	end

	skynet.dispatch ("lua", function (_, _, mod, cmd, ...)
		local m = assert (MODULE[mod])
		local f = assert (m[cmd])
		skynet.retpack (f (...))
	end)
end)
