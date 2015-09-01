package.cpath = package.cpath .. ";../3rd/skynet/luaclib/?.so;../server/luaclib/?.so"
package.path = package.path .. ";../3rd/skynet/lualib/?.lua;../common/?.lua"

local print_r = require "print_r"
local socket = require "clientsocket"
local sproto = require "sproto"
local srp = require "srp"
local aes = require "aes"
local login_proto = require "proto.login_proto"
local game_proto = require "proto.game_proto"
local constant = require "constant"

local username = arg[1]
local password = arg[2]

local user = { name = arg[1], password = arg[2] }

if not user.name then
	local f = io.open ("anonymous", "r")
	if not f then
		f = io.open ("anonymous", "w")
		local name = ""
		math.randomseed (os.time ())
		for i = 1, 16 do
			name = name .. string.char (math.random (127))
		end

		user.name = name
		f:write (name)
		f:flush ()
		f:close ()
	else
		user.name = f:read ("a")
		f:close ()
	end
end

if not user.password then
	user.password = constant.default_password
end

local server = "127.0.0.1"
local login_port = 9777
local game_port = 9555
local gameserver = {
	addr = "127.0.0.1",
	port = 9555,
	name = "gameserver",
}

local host = sproto.new (login_proto.s2c):host "package"
local request = host:attach (sproto.new (login_proto.c2s))
local fd 
local game_fd

local function send_message (fd, msg)
	local package = string.pack (">s2", msg)
	socket.send (fd, package)
end

local session = {}
local session_id = 0
local function send_request (name, args)
	print ("send_request", name)
	session_id = session_id + 1
	local str = request (name, args, session_id)
	send_message (fd, str)
	session[session_id] = { name = name, args = args }
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
		error (string.format ("socket %d closed", fd))
	end

	return unpack (last .. r)
end

local rr = { wantmore = true }
local function handle_request (name, args, response)
	print ("request", name)
	if args then
		print_r (args)
	else
		print "empty argument"
	end

	if name:sub (1, 3) == "aoi" and  name ~= "aoi_remove" then
		if response then
			send_message (fd, response (rr))
		end
	end
end

local RESPONSE = {}

function RESPONSE:handshake (args)
	print ("RESPONSE.handshake")
	local name = self.name
	assert (name == user.name)

	if args.user_exists then
		local key = srp.create_client_session_key (name, user.password, args.salt, user.private_key, user.public_key, args.server_pub)
		user.session_key = key
		local ret = { challenge = aes.encrypt (args.challenge, key) }
		send_request ("auth", ret)
	else
		print (name, constant.default_password)
		local key = srp.create_client_session_key (name, constant.default_password, args.salt, user.private_key, user.public_key, args.server_pub)
		user.session_key = key
		local ret = { challenge = aes.encrypt (args.challenge, key), password = aes.encrypt (user.password, key) }
		send_request ("auth", ret)
	end
end

function RESPONSE:auth (args)
	print ("RESPONSE.auth")

	user.session = args.session
	local challenge = aes.encrypt (args.challenge, user.session_key)
	send_request ("challenge", { session = args.session, challenge = challenge })
end

function RESPONSE:challenge (args)
	print ("RESPONSE.challenge")

	local token = aes.encrypt (args.token, user.session_key)

	fd = assert (socket.connect (gameserver.addr, gameserver.port))
	print (string.format ("game server connected, fd = %d", fd))
	send_request ("login", { session = user.session, token = token })

	host = sproto.new (game_proto.s2c):host "package"
	request = host:attach (sproto.new (game_proto.c2s))

	send_request ("character_list")
end

local function handle_response (id, args)
	local s = assert (session[id])
	session[id] = nil
	local f = RESPONSE[s.name]
	print ("response type : " .. type (args))
	if f then
		f (s.args, args)
	else
		print "response"
		print_r (args)
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
user.private_key = private_key
user.public_key = public_key 
fd = assert (socket.connect (server, login_port))
print (string.format ("login server connected, fd = %d", fd))
send_request ("handshake", { name = user.name, client_pub = public_key })

local HELP = {}

local function handle_cmd (line)
	local cmd
	local p = string.gsub (line, "([%w-_]+)", function (s) 
		cmd = s
		return ""
	end, 1)
	print (cmd, "====", p)

	if string.lower (cmd) == "help" then
		for k, v in pairs (HELP) do
			print (string.format ("command:\n\t%s\nparameter:\n%s", k, v()))
		end
		return
	end

	local t = {}
	local f, err = load (p, "=(load)" , "t", t)

	if not f then error (err) end
	f ()

	print ("cmd", cmd)
	if t then
		print_r (t)
	else
		print ("null argument")
	end

	if not next (t) then t = nil end

	if cmd then
		local ok, err = pcall (send_request, cmd, t)
		if not ok then
			print (string.format ("invalid command (%s), error (%s)", cmd, err))
		end
	end
end

function HELP.character_create ()
	return [[
	name: your nickname in game
	race: 1(human)/2(orc)
	class: 1(warrior)/2(mage)
]]
end

print ('type "help" to see all available command.')
while true do
	dispatch_message ()
	local cmd = socket.readstdin ()
	if cmd then
		handle_cmd (cmd)
	else
		socket.usleep (100)
	end
end

