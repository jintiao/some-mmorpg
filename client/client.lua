package.cpath = "../3rd/skynet/luaclib/?.so"
package.path = "../3rd/skynet/lualib/?.lua;../common/?.lua"

local socket = require "clientsocket"
local sproto = require "sproto"
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

send_request ("handshake", { name = "jin" })

while true do
	socket.usleep (100)
end
