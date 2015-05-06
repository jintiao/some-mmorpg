local skynet = require "skynet"
local sharemap = require "sharemap"

local logger = require "logger"
local handler = require "agent.handler"


local REQUEST = {}
local RESPONSE = {}
local user
handler = handler.new (REQUEST, RESPONSE)

handler:init (function (u)
	user = u
end)


function REQUEST.aoi_add (list)
	logger.debugf ("aoihandler.aoi_add : \n%s", logger.dump (list))

	local s = skynet.self ()
	for _, a in pairs (list) do
		skynet.fork (function ()
			local reader = skynet.call (a, "lua", "aoi_subscribe", s)
			local c = sharemap.reader ("character", reader)
			user.subscribing[c.id] = { character = c, agent = a, wantmore = false, dirty = false }
			user.agent2cid[a] = c.id

			user.send_request ("aoi_add", { character = c })
		end)
	end
end

function REQUEST.aoi_subscribe (agent)
	if not user.character_writer then
		user.character_writer = sharemap.writer ("character", user.character)
	end
	user.subscriber[agent] = agent
	return user.character_writer:copy ()
end

function REQUEST.aoi_remove (list)
	for _, agent in pairs (list) do
		local id = user.agent2cid[agent]
		if not id then return end
	
		user.subscribing[id] = nil
		user.agent2cid[agent] = nil

		user.send_request ("aoi_remove", { character = id })
	end
end

function REQUEST.aoi_move (list)
	for _, agent in pairs (list) do
		local id = user.agent2cid[agent]
		local t = user.subscribing[id]
		if t.wantmore then 
			t.wantmore = false
			t.dirty = false
			local c = t.character
			c:update ()
			user.send_request ("aoi_update_move", { character = c })
		else
			t.dirty = true
		end
	end
end

function REQUEST.aoi_update_attribute (agent)
	local id = user.agent2cid[agent]
	local t = user.subscribing[id]
	local c = t.character
	c:update ()
	user.send_request ("aoi_update_attribute", { character = c })
end

local function send_aoi_move (id)
	local t = user.subscribing[id]
	if t.dirty then
		t.wantmore = false
		t.dirty = false

		local c = t.character
		c:update ()
		user.send_request ("aoi_update_move", { character = c })
	else
		t.wantmore = true
	end
end

function RESPONSE.aoi_add (request, response)
	if not response or not response.wantmore then return end
	send_aoi_move (request.character.id)	
end

function RESPONSE.aoi_update_move (request, response)
	if not response or not response.wantmore then return end
	send_aoi_move (request.character.id)	
end

function handler.boardcast_attribute ()
	local writer = user.character_writer
	if not writer then return end

	writer:commit ()

	user.send_request ("aoi_update_attribute", { character = writer })
	for _, a in pairs (user.subscriber) do
		skynet.fork (function ()
			skynet.call (a, "lua", "aoi_update_attribute", skynet.self ())
		end)
	end
end

return handler
