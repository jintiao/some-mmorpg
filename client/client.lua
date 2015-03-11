package.cpath = "../3rd/skynet/luaclib/?.so;../server/skynet-ex/luaclib/?.so"
package.path = "../3rd/skynet/lualib/?.lua;../common/?.lua"

local socket = require "clientsocket"
local sproto = require "sproto"
local srp = require "srp"
local aes = require "aes"
local login_proto = require "login_proto"
local game_proto = require "game_proto"
local constant = require "constant"

local user = { name = "helloworld", password = "123456" }
local server = "127.0.0.1"
local login_port = 9777
local game_port = 9555

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

local function handle_request (name, args)
	print ("request", name)

	if args then
		for k, v in pairs (args) do
			print (k, v)
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
		local ret = { name = aes.encrypt (name, key) }
		send_request ("auth", ret)
	else
		print (name, constant.default_password)
		local key = srp.create_client_session_key (name, constant.default_password, args.salt, user.private_key, user.public_key, args.server_pub)
		user.session_key = key
		local ret = { name = aes.encrypt (name, key), password = aes.encrypt (user.password, key) }
		send_request ("auth", ret)
	end
end

function RESPONSE:auth (args)
	print ("RESPONSE.auth")
	user.account = args.account
	local token = aes.encrypt (args.token, user.session_key)

	fd = assert (socket.connect (server, game_port))
	print (string.format ("game server connected, fd = %d", fd))
	send_request ("login", { account = args.account, token = token })

	host = sproto.new (game_proto.s2c):host "package"
	request = host:attach (sproto.new (game_proto.c2s))
	send_request ("character_list")
end

function RESPONSE:character_list (args)
	print ("RESPONSE:character_list")

	if not args or not args.character then
		print "empty list"
	else
		for i = 1, #args.character do
			local c = args.character[i]
			print (string.format ("character index : %d", i))
			for a, b in pairs (c) do
				print ("", a, b)
			end
		end
	end
end

function RESPONSE:character_create (args)
	print ("RESPONSE:character_create")

	if args.character then
		for k, v in pairs (args.character) do
			print (k, v)
		end
	elseif args.errno then
		print ("error : ", args.errno)
	end
end


local function handle_response (id, args)
	local s = assert (session[id])
	session[id] = nil
	local f = assert (RESPONSE[s.name])
	f (s.args, args)
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

	if string.lower (cmd) == "help" then
		for k, v in pairs (HELP) do
			print (string.format ("command:\n\t%s\nparameter:\n%s", k, v()))
		end
		return
	end

	local t = {}
	string.gsub (p, "(%w+)%s*=%s*([%w]+)", function (k, v)
		t[k] = v
	end)

	if cmd then
		local ok = pcall (send_request, cmd, t)
		if not ok then
			print (string.format ("invalid message %s", cmd))
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

