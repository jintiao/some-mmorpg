local skynet = require "skynet"
local socket = require "socket"

local syslog = require "syslog"
local protoloader = require "protoloader"
local srp = require "srp"
local aes = require "aes"
local uuid = require "uuid"

local traceback = debug.traceback


local master
local database
local host
local auth_timeout
local session_expire_time
local session_expire_time_in_second
local connection = {}
local saved_session = {}

local slaved = {}

local CMD = {}

function CMD.init (m, id, conf)
	master = m
	database = skynet.uniqueservice ("database")
	host = protoloader.load (protoloader.LOGIN)
	auth_timeout = conf.auth_timeout * 100
	session_expire_time = conf.session_expire_time * 100
	session_expire_time_in_second = conf.session_expire_time
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

function CMD.auth (fd, addr)
	connection[fd] = addr
	skynet.timeout (auth_timeout, function ()
		if connection[fd] == addr then
			syslog.warningf ("connection %d from %s auth timeout!", fd, addr)
			close (fd)
		end
	end)

	socket.start (fd)
	socket.limit (fd, 8192)

	local type, name, args, response = read_msg (fd)
	assert (type == "REQUEST")

	if name == "handshake" then
		assert (args and args.name and args.client_pub, "invalid handshake request")

		local account = skynet.call (database, "lua", "account", "load", args.name) or error ("load account " .. args.name .. " failed")

		local session_key, _, pkey = srp.create_server_session_key (account.verifier, args.client_pub)
		local challenge = srp.random ()
		local msg = response {
					user_exists = (account.id ~= nil),
					salt = account.salt,
					server_pub = pkey,
					challenge = challenge,
				}
		send_msg (fd, msg)

		type, name, args, response = read_msg (fd)
		assert (type == "REQUEST" and name == "auth" and args and args.challenge, "invalid auth request")

		local text = aes.decrypt (args.challenge, session_key)
		assert (challenge == text, "auth challenge failed")

		local id = tonumber (account.id)
		if not id then
			assert (args.password)
			id = uuid.gen ()
			local password = aes.decrypt (args.password, session_key)
			account.id = skynet.call (database, "lua", "account", "create", id, account.name, password) or error (string.format ("create account %s/%d failed", args.name, id))
		end
		
		challenge = srp.random ()
		local session = skynet.call (master, "lua", "save_session", id, session_key, challenge)

		msg = response {
				session = session,
				expire = session_expire_time_in_second,
				challenge = challenge,
			}
		send_msg (fd, msg)
		
		type, name, args, response = read_msg (fd)
		assert (type == "REQUEST")
	end

	assert (name == "challenge")
	assert (args and args.session and args.challenge)

	local token, challenge = skynet.call (master, "lua", "challenge", args.session, args.challenge)
	assert (token and challenge)

	local msg = response {
			token = token,
			challenge = challenge,
	}
	send_msg (fd, msg)

	close (fd)
end

function CMD.save_session (session, account, key, challenge)
	saved_session[session] = { account = account, key = key, challenge = challenge }
	skynet.timeout (session_expire_time, function ()
		local t = saved_session[session]
		if t and t.key == key then
			saved_session[session] = nil
		end
	end)
end

function CMD.challenge (session, secret)
	local t = saved_session[session] or error ()

	local text = aes.decrypt (secret, t.key) or error ()
	assert (text == t.challenge)

	t.token = srp.random ()
	t.challenge = srp.random ()

	return t.token, t.challenge
end

function CMD.verify (session, secret)
	local t = saved_session[session] or error ()

	local text = aes.decrypt (secret, t.key) or error ()
	assert (text == t.token)
	t.token = nil

	return t.account
end

skynet.start (function ()
	skynet.dispatch ("lua", function (_, _, command, ...)
		local function pret (ok, ...)
			if not ok then 
				syslog.warningf (...)
				skynet.ret ()
			else
				skynet.retpack (...)
			end
		end

		local f = assert (CMD[command])
		pret (xpcall (f, traceback, ...))
	end)
end)

