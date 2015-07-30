local config = {}

config.log_level = 1 -- 1:debug 2:info 3:notice 4:warning 5:error

config.debug_port = 9333

config.gamed = { 
	name = "gameserver", 
	port = 9555, 
	maxclient = 64, 
	pool = 32,
}

return config
