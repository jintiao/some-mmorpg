local skynet = require "skynet"
local logger = require "logger"
local print_r = require "print_r"
local sharemap = require "sharemap"

local REQUEST = {}

function REQUEST:aoi_add (list)
	local s = skynet.self ()
	for _, a in pairs (list) do
		skynet.fork (function ()
			local reader = skynet.call (a, "lua", "aoi_subscribe", s)
			local c = sharemap.reader ("character", reader)
			self.subscribing[c.id] = { character = c, agent = a, wantmore = false, dirty = false }
			self.agent2cid[a] = c.id

			self.send_request ("aoi_add", { character = c })
		end)
	end
end

function REQUEST:aoi_subscribe (agent)
	if not self.character_writer then
		self.character_writer = sharemap.writer ("character", self.character)
	end
	self.subscriber[agent] = agent
	return self.character_writer:copy ()
end

function REQUEST:aoi_remove (list)
	for _, agent in pairs (list) do
		local id = self.agent2cid[agent]
		if not id then return end
	
		self.subscribing[id] = nil
		self.agent2cid[agent] = nil

		self.send_request ("aoi_remove", { character = id })
	end
end

function REQUEST:aoi_move (list)
	for _, agent in pairs (list) do
		local id = self.agent2cid[agent]
		local t = self.subscribing[id]
		if t.wantmore then 
			t.wantmore = false
			t.dirty = false
			local c = t.character
			c:update ()
			self.send_request ("aoi_update_move", { character = c })
		else
			t.dirty = true
		end
	end
end

local RESPONSE = {}

local function send_aoi_move (self, id)
	local t = self.subscribing[id]
	if t.dirty then
		t.wantmore = false
		t.dirty = false

		local c = t.character
		c:update ()
		self.send_request ("aoi_update_move", { character = c })
	else
		t.wantmore = true
	end
end

function RESPONSE:aoi_add (request, response)
	if not response or not response.wantmore then return end
	send_aoi_move (self, request.character.id)	
end

function RESPONSE:aoi_update_move (request, response)
	if not response or not response.wantmore then return end
	send_aoi_move (self, request.character.id)	
end

local handler = {}

function handler:register ()
	local t = self.REQUEST
	for k, v in pairs (REQUEST) do
		t[k] = v
	end
	t = self.RESPONSE
	for k, v in pairs (RESPONSE) do
		t[k] = v
	end
end

function handler:unregister ()
	local t = self.REQUEST
	for k, _ in pairs (REQUEST) do
		t[k] = nil
	end
	t = self.RESPONSE
	for k, _ in pairs (RESPONSE) do
		t[k] = nil
	end
end

return handler

