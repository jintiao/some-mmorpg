local sparser = require "sprotoparser"

local login_proto = {}

login_proto.c2s = sparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	request {
		name 0 : string
		client_pub 1 : string
	}
	response {
		user_exists 0 : boolean
		salt 1 : string
		server_pub 2 : string
	}
}

login 2 {
	request {
		name 0 : string
		password 1 : string
	}
	response {
		account 0 : integer
		token 1 : string
	}
}

]]

login_proto.s2c = sparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}
]]

return login_proto
