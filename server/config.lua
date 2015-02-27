local config = {}

config.log_level = 1 -- 1:debug 2:log 3:warning 4:error
config.database = "database"

config.logind = {
	name = "loginserver", 
	port = 9777, 
	ninstance = 8,
}

local max = 64
config.gamed = { 
	name = "gameserver", 
	port = 9555, 
	maxclient = max, 
	pool = math.ceil (max / 3),
}

return config
