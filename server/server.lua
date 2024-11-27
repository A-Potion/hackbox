local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 45165)

local games = {} 
local data, msg_or_ip, port_or_nil
local entity, cmd, parms, code, ent

local running = true

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
			games[code][entity] = {x=ent.x+x, y=ent.y+y}
		elseif cmd == 'at' then
			local code, x, y = parms:match("^([^%s]+)%s+([^%s]+)%s+([^%s]+)")
			assert(x and y) -- validation is better, but asserts will serve.
			code, x, y = tonumber(code), tonumber(x), tonumber(y)
			games[code][entity] = {x=x, y=y}
		elseif cmd == 'update' then
			code = tonumber(parms:match("([^%s]+)"))
			print(parms)
			print(code)
			for k, v in pairs(games[code]) do
				udp:sendto(string.format("%s %s %d %d", k, 'at', v.x, v.y), msg_or_ip,  port_or_nil)
			end
		elseif cmd == 'quit' then
			running = false;
        elseif cmd == 'new' then
			local code = #games + 1
			print("new game with code ", code)
			games[code] = {}
            udp:sendto(string.format("%s %i", 'code', code), msg_or_ip, port_or_nil)
		elseif cmd == 'join' then
			code = tonumber(parms:match("([^%s]+)"))
			if games[code] then
				print("Game is active")
				games[code][entity] = entity
			else
				print("Game is not active")
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