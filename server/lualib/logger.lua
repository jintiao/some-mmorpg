local config = require "config.system"

local logger = {}

local level = tonumber (config.log_level) or 1

local function write (...)
	local t = {...}
	print (table.concat (t, " "))
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

function logger.register (name)
	dstr = "[" .. name .. "][Debug] "
	lstr = "[" .. name .. "][Log] "
	wstr = "[" .. name .. "][Warning] "
	estr = "[" .. name .. "][Error] "
end

logger.register (SERVICE_NAME)

return logger
