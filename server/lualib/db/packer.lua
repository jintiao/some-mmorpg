local cjson = require "cjson"
cjson.encode_sparse_array(true, 1, 1)

local packer = {}

function packer.pack (v)
	return cjson.encode (v)
end

function packer.unpack (v)
	return cjson.decode (v)
end

return packer
