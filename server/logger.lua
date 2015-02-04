local logger = {}

local function write (...)
	local t = {...}
	print (table.concat (t, " "))
end

function logger.debug (...)
	write (dstr, ...)
end

function logger.log (...)
	write (lstr, ...)
end

function logger.warning (...)
	write (wstr, ...)
end

function logger.error (...)
	write (estr, ...)
end

function logger.register (name)
	dstr = "[" .. name .. "][Debug] "
	lstr = "[" .. name .. "][Log] "
	wstr = "[" .. name .. "][Warning] "
	estr = "[" .. name .. "][Error] "
end

logger.register (SERVICE_NAME)

return logger
