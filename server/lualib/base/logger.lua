local skynet = require "skynet"

local config = require "config.system"

local logger = {
	LEVEL_DEBUG = 1,
	LEVEL_LOG = 2,
	LEVEL_WARNING = 3,
	LEVEL_ERROR = 4,
}

local level

function logger.level (l)
	level = l
end

logger.level (tonumber (config.log_level) or logger.LEVEL_LOG)

local function write (...)
	skynet.error (...)
end

function logger.debug (...)
	if level <= 1 then 
		write (dstr, ...)
	end
end

function logger.debugf (...)
	if level <= 1 then 
		write (dstr, string.format (...))
	end
end

function logger.log (...)
	if level <= 2 then 
		write (lstr, ...)
	end
end

function logger.logf (...)
	if level <= 2 then
		write (lstr, string.format (...))
	end
end

function logger.warning (...)
	if level <= 3 then 
		write (wstr, ...)
	end
end

function logger.warningf (...)
	if level <= 3 then 
		write (wstr, string.format (...))
	end
end

function logger.error (...)
	if level <= 4 then 
		write (estr, ...)
	end
end

function logger.errorf (...)
	if level <= 4 then 
		write (estr, string.format (...))
	end
end

function logger.name (name)
	dstr = "[" .. name .. "]"
	lstr = "[" .. name .. "]"
	wstr = "[" .. name .. "]"
	estr = "[" .. name .. "]"
end

logger.name (SERVICE_NAME)

return logger
