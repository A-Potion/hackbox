local socket = require "socket"
local udp = socket.udp()
local openaikey = require("conf")
print(openaikey)

udp:settimeout(0)
udp:setsockname('*', 45165)

local games = {} 
local data, msg_or_ip, port_or_nil
local entity, cmd, parms, code, ent
local hosts = {}

local running = true

function sendToAll(code, msg, send_to_host)
	for _, client in pairs(games[code]) do
		if type(client) == "table"	then
			udp:sendto(msg, client.ip, client.port)
			print(string.format("Sent %s to client %s:%s", msg, client.ip, client.port))
		end
		if send_to_host then
			udp:sendto(msg, hosts[code].ip, hosts[code].port)
			print(string.format("Sent %s to host %s:%s", msg, hosts[code].ip, hosts[code].port))
		end
	end
end

function notifyEntityRemoval(code, entity)
	for _, client in pairs(games[code]) do
			sendToAll(code, string.format("%s %s u", entity, 'remove'), true)
	end
end

function cleanupLocalEntity(code, entity)
	-- Print debug info
	print("Cleaning up local reference to entity:", entity)

	-- Notify clients about entity removal
	notifyEntityRemoval(code, entity)

	-- Remove from world table
	games[code][entity] = nil

	-- Clear any local references to this entity
	if localEntityData then localEntityData[entity] = nil end
	if entitySprites then entitySprites[entity] = nil end
	if entitySounds then entitySounds[entity] = nil end

	-- Clear any targeting or interaction references
	if selectedEntity == entity then selectedEntity = nil end
	if targetEntity == entity then targetEntity = nil end

	-- Clear any queued actions involving this entity
	if actionQueue then
		for i = #actionQueue, 1, -1 do
			if actionQueue[i].target == entity then
				table.remove(actionQueue, i)
			end
		end
	end

	-- Force garbage collection (optional)
	collectgarbage("collect")

	-- Verify cleanup
	print("Local entity cleanup complete. Verifying removal:", entity)
	print("World entry exists:", games[code][entity] ~= nil)
end

print "Beginning server loop."
while running do
    data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		-- more of these funky match paterns!
		entity, cmd, parms = data:match("^(%S*) (%S+) (.*)")
		print(entity)
        if cmd == 'move' then
			code, x, y = parms:match("^([^%s]+)%s+([^%s]+)%s+([^%s]+)")
			code = tonumber(code)
			ent = games[code][entity]
			if ent then
				assert(x and y) -- validation is better, but asserts will serve.
				-- don't forget, even if you matched a "number", the result is still a string!
				-- thankfully conversion is easy in lua.
				x, y = tonumber(x), tonumber(y)
				-- and finally we stash it away
				games[code][entity] = {x=ent.x+x, y=ent.y+y, ip=ent.ip, port=ent.port}
			end
		elseif cmd == 'at' then
			local code, x, y = parms:match("^([^%s]+)%s+([^%s]+)%s+([^%s]+)")
			assert(x and y) -- validation is better, but asserts will serve.
			code, x, y = tonumber(code), tonumber(x), tonumber(y)
			games[code][entity] = {x=x, y=y, ip=games[code][entity].ip, port=games[code][entity].port}
		elseif cmd == 'update' then
			code = tonumber(parms:match("([^%s]+)"))
			print(parms)
			for k, v in pairs(games[code]) do
				print(k, v.x, v.y)
				udp:sendto(string.format("%s %s %d %d", k, 'at', v.x, v.y), msg_or_ip,  port_or_nil)
			end
		elseif cmd == 'quit' then
			code = tonumber(parms:match("([^%s]+)"))
			cleanupLocalEntity(code, entity)
			print(entity ..  " left.")

        elseif cmd == 'new' then
			local code = #games + 1
			print("new game with code ", code)
			games[code] = {}
			hosts[code] = {ip = msg_or_ip, port = port_or_nil, active = true, accepting = true}
            udp:sendto(string.format("%s %s %i", 'placeholder', 'code', code), msg_or_ip, port_or_nil)
		elseif cmd == 'start' then
			code = tonumber(parms:match("([^%s]+)"))
			print("Starting game ", code)
			hosts[code].accepting = false
		elseif cmd == 'end' then
			print("Game " .. parms .. " is closing.")
			for k, v in pairs(games[code]) do
				cleanupLocalEntity(code, k)
			end
			hosts[code].active = false
            udp:sendto(string.format("%s %s %i", 'placeholder', 'code', code), msg_or_ip, port_or_nil)
		elseif cmd == 'join' then
			code = tonumber(parms:match("([^%s]+)"))
			if hosts[code].active and hosts[code].accepting then
				print("Game is active")
				games[code][entity] = {ip = msg_or_ip, port = port_or_nil, x = 0, y = 0}
				udp:sendto(string.format("placeholder %s %i", 'code', code), msg_or_ip, port_or_nil)
				udp:sendto(string.format("%s %s %d %d", entity, 'at', 0, 0), msg_or_ip,  port_or_nil)
				udp:sendto(string.format("%s %s %s", entity, 'join', entity), hosts[code].ip, hosts[code].port)
			elseif hosts[code].active and hosts[code].accepting == false then
				print("Game is active but not accepting new joins.")
				udp:sendto(string.format("placeholder %s %i", 'abn', code), msg_or_ip, port_or_nil)
			else
				print("Game is not active")
				udp:sendto(string.format("placeholder %s placeholder", 'dne'), msg_or_ip, port_or_nil)
			end
		elseif cmd == 'kick' then

        else
			print("unrecognised command:", cmd)
		end
	elseif msg_or_ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
	end
	
	socket.sleep(0.01)
end

print "Thank you."