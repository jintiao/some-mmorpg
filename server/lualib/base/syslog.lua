local skynet = require "skynet"

local config = require "config.system"

local syslog = {
	prefix = {
		"D|",
		"I|",
		"N|",
		"W|",
		"E|",
	},
}

local level
function syslog.level (lv)
	level = lv
end

local function write (priority, fmt, ...)
	if priority >= level then
		skynet.error (syslog.prefix[priority] .. fmt, ...)
	end
end

local function writef (priority, ...)
	if priority >= level then
		skynet.error (syslog.prefix[priority] .. string.format (...))
	end
end

function syslog.debug (...)
	write (1, ...)
end

function syslog.debugf (...)
	writef (1, ...)
end

function syslog.info (...)
	write (2, ...)
end

function syslog.infof (...)
	writef (2, ...)
end

function syslog.notice (...)
	write (3, ...)
end

function syslog.noticef (...)
	writef (3, ...)
end

function syslog.warning (...)
	write (4, ...)
end

function syslog.warningf (...)
	writef (4, ...)
end

function syslog.err (...)
	write (5, ...)
end

function syslog.errf (...)
	writef (5, ...)
end



syslog.level (tonumber (config.log_level) or 3)

return syslog
