local skynet = require "skynet"

local function launch_slave (handler)
end

local function launch_master (logind, conf)
	local handler = logind.command_handler
	skynet.dispatch ("lua", function (_, source, cmd, ...)
		skynet.retpack (handler (cmd, ...))
	end)

	local instance = conf.instance
	local slaves = {}
	for i = 1, instance do
		table.insert (slaves, skynet.newservice (SERVICE_NAME))
	end
end

local function login (logind, conf)
	local name = "." .. conf.name
	skynet.start (function ()
		local master = skynet.localname (name)
		if master then
			launch_slave (logind.auth_handler)
		else
			skynet.register (name)
			launch_master (logind, conf)
		end
	end)
end

return login
