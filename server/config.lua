local config = {}

config.logind = { name = "loginserver", port = 9777, ninstance = 8 }
config.gamed = { name = "gameserver", port = 9555, maxclient = 64 }

return config
