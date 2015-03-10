local cjson = require "cjson"

local packer = {}

function packer.pack (v)
	return cjson.encode (v)
end

function packer.unpack (v)
	return cjson.decode (v)
end

return packer
