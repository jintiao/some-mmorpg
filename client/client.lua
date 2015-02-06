package.cpath = "../3rd/skynet/luaclib/?.so;../server/skynet-ex/luaclib/?.so"
package.path = "../3rd/skynet/lualib/?.lua;../common/?.lua"

local socket = require "clientsocket"
local sproto = require "sproto"
local srp = require "srp"
local aes = require "aes"
local login_proto = require "login_proto"

local host = sproto.new (login_proto.s2c):host "package"
local request = host:attach (sproto.new (login_proto.c2s))

local fd = assert (socket.connect ("127.0.0.1", 9777))

local function send_message (fd, msg)
	local package = string.pack (">s2", msg)
	socket.send (fd, package)
end

local session = 0
local function send_request (name, args)
	session = session + 1
	local str = request (name, args, session)
	send_message (fd, str)
end

local function unpack (text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte (1) * 256 + text:byte (2)
	if size < s + 2 then
		return nil, text
	end

	return text:sub (3, 2 + s), text:sub (3 + s)
end

local function recv (last)
	local result
	result, last = unpack (last)
	if result then
		return result, last
	end
	local r = socket.recv (fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error ("socket closed")
	end

	return unpack (last .. r)
end

local function handle_request (name, args)
	print ("request", name)

	if args then
		for k, v in pairs (args) do
			print (k, v)
		end
	end
end

local function handle_response (session, args)
	print ("response", session)

	if args then
		for k, v in pairs (args) do
			print (k, v)
		end
	end
end

local function handle_message (t, ...)
	if t == "REQUEST" then
		handle_request (...)
	else
		handle_response (...)
	end
end

local last = ""
local function dispatch_message ()
	while true do
		local v
		v, last = recv (last)
		if not v then
			break
		end

		handle_message (host:dispatch (v))
	end
end

local private_key, public_key = srp.create_client_key ()
send_request ("handshake", { name = "jintiao", client_pub = public_key })

while true do
	dispatch_message ()
	socket.usleep (100)
end
