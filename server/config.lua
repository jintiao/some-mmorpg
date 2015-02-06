local config = {}

config.log_level = 1 -- 1:debug 2:log 3:warning 4:error
config.logind = { name = "loginserver", port = 9777, ninstance = 8 }
config.gamed = { name = "gameserver", port = 9555, maxclient = 64 }

return config
