local skynet = require "skynet"
local srp = require "srp"

skynet.start (function ()
	local I = "jintiao"
	local p = "123abc*()DEF"

	-- call at server side when user register new user
	local s, v = srp.create_verifier (I, p)
	assert (s and v)

	-- call at client side when user try to login
	local a, A = srp.create_client_key ()

	-- call at server side. A is send from client to server
	local Ks, b, B = srp.create_server_session_key (v, A)

	-- call at client side. s, B is send from server to client
	local Kc = srp.create_client_session_key (I, p, s, a, A, B)

	-- we should not use this in real world, K must not expose to network
	-- use this key to encrypt something then verify it on other side is more reasonable
	if assert (Ks == Kc) then
		print ("srp test passed")
	else
		print ("srp test failed")
	end
end)
