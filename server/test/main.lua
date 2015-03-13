local skynet = require "skynet"

skynet.start(function()
	skynet.newservice ("test_srp")
	skynet.newservice ("test_aes")
end)
