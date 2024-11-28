local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 45165)

local games = {} 
local data, msg_or_ip, port_or_nil
local entity, cmd, parms, code, ent

local running = true

function notifyEntityRemoval(code, entity)
	for _, client in pairs(games[code]) do
		if type(client) == "table" then
			udp:sendto(string.format("%s %s u", entity, 'remove'), client.ip, client.port)
			print("Notified " .. client.ip .. ":" .. client.port)
		end
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
			assert(x and y) -- validation is better, but asserts will serve.
			-- don't forget, even if you matched a "number", the result is still a string!
			-- thankfully conversion is easy in lua.
			x, y = tonumber(x), tonumber(y)
			-- and finally we stash it away
			code = tonumber(code)
			ent = games[code][entity]
			games[code][entity] = {x=ent.x+x, y=ent.y+y, ip=ent.ip, port=ent.port}
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
            udp:sendto(string.format("%s %i", 'code', code), msg_or_ip, port_or_nil)
		elseif cmd == 'join' then
			code = tonumber(parms:match("([^%s]+)"))
			if games[code] then
				print("Game is active")
				games[code][entity] = {ip = msg_or_ip, port = port_or_nil, x = 0, y = 0}
				udp:sendto(string.format("%s %i", 'code', code), msg_or_ip, port_or_nil)
				udp:sendto(string.format("%s %s %d %d", entity, 'at', 0, 0), msg_or_ip,  port_or_nil)
			else
				print("Game is not active")
				udp:sendto(string.format("%s %s", 'dne', 'no'), msg_or_ip, port_or_nil)
			end
        else
			print("unrecognised command:", cmd)
		end
	elseif msg_or_ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
	end
	
	socket.sleep(0.01)
end

print "Thank you."