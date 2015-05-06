local skynet = require "skynet"
local socket = require "socket"

local logger = require "logger"
local protoloader = require "protoloader"
local srp = require "srp"
local aes = require "aes"


local master
local database
local host
local auth_timeout
local token_expire_time
local connection = {}
local cache_token = {}

local slaved = {}

local CMD = {}

function CMD.init (m, id, conf)
	master = m
	database = skynet.uniqueservice ("database")
	host = protoloader.load (protoloader.LOGIN)
	auth_timeout = conf.auth_timeout * 100
	token_expire_time = conf.token_expire_time * 100
end

local function close (fd)
	if connection[fd] then
		socket.close (fd)
		connection[fd] = nil
	end
end

local function read (fd, size)
	return socket.read (fd, size) or error ()
end

local function read_msg (fd)
	local s = read (fd, 2)
	local size = s:byte(1) * 256 + s:byte(2)
	local msg = read (fd, size)
	return host:dispatch (msg, size)
end

local function send_msg (fd, msg)
	local package = string.pack (">s2", msg)
	socket.write (fd, package)
end

local function do_auth (fd, addr)
	connection[fd] = addr
	skynet.timeout (auth_timeout, function ()
		if connection[fd] then
			logger.warningf ("connection %d from %s auth timeout!", fd, addr)
			close (fd)
		end
	end)

	socket.start (fd)
	socket.limit (fd, 8192)

	local type, name, args, response = read_msg (fd)
	assert (type == "REQUEST")
	assert (name == "handshake")
	assert (args and args.name and args.client_pub)

	local account = skynet.call (database, "lua", "account", "load", args.name)
	assert (account)

	local session_key, _, pkey = srp.create_server_session_key (account.verifier, args.client_pub)
	local msg = response {
					user_exists = (account.id ~= nil),
					salt = account.salt,
					server_pub = pkey,
				}
	send_msg (fd, msg)

	type, name, args, response = read_msg (fd)
	assert (type == "REQUEST")
	assert (name == "auth")
	assert (args and args.name)

	local realname = aes.decrypt (args.name, session_key)
	assert (realname == account.name)

	local id = tonumber (account.id)
	if not id then
		assert (args.password)
		local password = aes.decrypt (args.password, session_key)
		id = skynet.call (database, "lua", "account", "create", realname, password)
		assert (id)
	end
		
	local token = srp.random ()

	msg = response {
			account = id,
			token = token,
		}
	send_msg (fd, msg)

	return id, session_key, token
end

local traceback = debug.traceback
function CMD.auth (fd, addr)
	local ok, id, key, token = xpcall (do_auth, traceback, fd, addr)
	if not ok then
		logger.logf ("connection %s (fd = %d) auth failed! %s", addr, fd, id)
		return
	end
	close (fd)

	return id, key, token
end

function CMD.cache (account, key, token)
	cache_token[account] = { key = key, token = token }
	skynet.timeout (token_expire_time, function ()
		local t = cache_token[account]
		if t and t.token == token then
			cache_token[account] = nil
		end
	end)
end

local function do_verify (account, secret, name)
	local t = cache_token[account]
	assert (t)

	local text = aes.decrypt (secret, t.key)
	assert (text)

	local s = t.token .. name
	assert (text == s)

	cache_token[account] = nil
	return true
end

function CMD.verify (account, secret, name)
	local ok, ret = xpcall (do_verify, traceback, account, secret, name)
	if not ok then
		logger.logf ("account %d from %s verify failed! %s", account, name, ret)
		return
	end
	return ret
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local f = assert (CMD[command])
		skynet.retpack (f (...))
	end)
end)

