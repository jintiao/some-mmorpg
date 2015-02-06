local skynet = require "skynet"
local aes = require "aes"

skynet.start (function ()
	local text = "hello aes"
	local key = "key"
	local okey = "other key"

	local a = aes.encrypt (text, key)
	local b = aes.decrypt (a, key)
	local c = aes.decrypt (a, okey)

	if not (assert (text == b)) then
		print ("aes test failed")
	end

	if not (assert (text ~= c)) then
		print ("aes test failed")
	end

	print ("aes test passed")
end)
