local host = {}
local socket = require("socket")
local adress, port = "37.27.51.34", 45165


local entity
local updaterate = 0.1
local code = "loading..."

local world = {}
local t

local width, height = love.graphics.getDimensions()

function host.load()
    love.window.setTitle("HackBox - Hosting")
    udp = socket.udp()

    udp:settimeout(0)
    udp:setpeername(adress, port)

    math.randomseed(os.time())
    entity = name.text

    print("sending code request")
    local dg = string.format("%s %s %s", entity, 'new', 'code')
    udp:send(dg)
    t = 0
end

function host.update(dt)
    t = t + dt

    if t > updaterate then

		t=t-updaterate
    end
    repeat
		data, msg = udp:receive()

		if data then
            ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
            if cmd == 'code' then
				code = parms
            else
				print("unrecognised command:", cmd)
			end
        elseif msg ~= 'timeout' then 
			error("Network error: "..tostring(msg))
		end
	until not data

    suit.Label("Code: " .. code, 100, 100)
end

function host.draw()
    suit.draw()
    
end

return host