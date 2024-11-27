local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 45165)

local games = {} 
local data, msg_or_ip, port_or_nil
local entity, cmd, parms

local running = true

print "Beginning server loop."
while running do
    data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		-- more of these funky match paterns!
		entity, cmd, parms = data:match("^(%S*) (%S*) (.*)")
        if cmd == 'move' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y) -- validation is better, but asserts will serve.
			-- don't forget, even if you matched a "number", the result is still a string!
			-- thankfully conversion is easy in lua.
			x, y = tonumber(x), tonumber(y)
			-- and finally we stash it away
			local ent = games[entity] or {x=0, y=0}
			games[entity] = {x=ent.x+x, y=ent.y+y}
		elseif cmd == 'at' then
			local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
			assert(x and y) -- validation is better, but asserts will serve.
			x, y = tonumber(x), tonumber(y)
			games[entity] = {x=x, y=y}
		elseif cmd == 'update' then
			for k, v in pairs(games) do
				udp:sendto(string.format("%s %s %d %d", k, 'at', v.x, v.y), msg_or_ip,  port_or_nil)
			end
		elseif cmd == 'quit' then
			running = false;
        elseif cmd == 'new' then
			local code = math.random(9999)
            udp:sendto(string.format("%i", code), msg_or_ip, port_or_nil)
        else
			print("unrecognised command:", cmd)
		end
	elseif msg_or_ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
	end
	
	socket.sleep(0.01)
end

print "Thank you."