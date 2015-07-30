local skynet = require "skynet"

local gateserver = require "gameserver.gateserver"
local syslog = require "syslog"
local protoloader = require "protoloader"


local gameserver = {}
local pending_msg = {}

function gameserver.forward (fd, agent)
	gateserver.forward (fd, agent)
end

function gameserver.kick (fd)
	gateserver.close_client (fd)
end

function gameserver.start (gamed)
	local handler = {}

	local host, send_request = protoloader.load (protoloader.LOGIN)

	function handler.open (source, conf)
		return gamed.open (conf)
	end

	function handler.connect (fd, addr)
		syslog.noticef ("connect from %s (fd = %d)", addr, fd)
		gateserver.open_client (fd)
	end

	function handler.disconnect (fd)
		syslog.noticef ("fd (%d) disconnected", fd)
	end

	local function do_login (fd, msg, sz)
		local type, name, args, response = host:dispatch (msg, sz)
		assert (type == "REQUEST")
		assert (name == "login")
		assert (args.session and args.token)
		local session = tonumber (args.session) or error ()
		local account = gamed.auth_handler (session, args.token) or error ()
		assert (account)
		return account
	end

	local traceback = debug.traceback
	function handler.message (fd, msg, sz)
		local queue = pending_msg[fd]
		if queue then
			table.insert (queue, { msg = msg, sz = sz })
		else
			pending_msg[fd] = {}

			local ok, account = xpcall (do_login, traceback, fd, msg, sz)
			if ok then
				syslog.noticef ("account %d login success", account)
				local agent = gamed.login_handler (fd, account)
				queue = pending_msg[fd]
				for _, t in pairs (queue) do
					syslog.noticef ("forward pending message to agent %d", agent)
					skynet.rawcall(agent, "client", t.msg, t.sz)
				end
			else
				syslog.warningf ("%s login failed : %s", addr, account)
				gateserver.close_client (fd)
			end

			pending_msg[fd] = nil
		end
	end

	local CMD = {}

	function CMD.token (id, secret)
		local id = tonumber (id)
		login_token[id] = secret
		skynet.timeout (10 * 100, function ()
			if login_token[id] == secret then
				syslog.noticef ("account %d token timeout", id)
				login_token[id] = nil
			end
		end)
	end

	function handler.command (cmd, ...)
		local f = CMD[cmd]
		if f then
			return f (...)
		else
			return gamed.command_handler (cmd, ...)
		end
	end

	return gateserver.start (handler)
end

return gameserver
