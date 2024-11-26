local game = {}
local socket = require("socket")
local adress, port = "37.27.51.34", 45165

local entity
local updaterate = 0.1

local world = {}
local t

local width, height = love.graphics.getDimensions()

function game.load()
    love.window.setTitle("HackBox - Game: " .. code.text)
    udp = socket.udp()

    upd:settimeout(0)
    udp:setpeername(adress, port)

    math.randomseed(os.time())
    entity  = tostring(ath.random(99999))

    local dg = string.format("%s %s %d %d", entity, "at", 0, 0)
    udp:send(dg)
    t = 0
end

function game.update()
    t = t + deltatime

    if t > updaterate then
        local x, y = 0
        if love.keyboard.isDown('up') then 	y=y-(20*t) end
		if love.keyboard.isDown('down') then 	y=y+(20*t) end
		if love.keyboard.isDown('left') then 	x=x-(20*t) end
		if love.keyboard.isDown('right') then 	x=x+(20*t) end

        local dg = string.format("%s %s %f %f", entity, 'move', x, y)
		udp:send(dg)

        local dg = string.format("%s %s $", entity, 'update')
		udp:send(dg)

		t=t-updaterate
    end
    repeat
		data, msg = udp:receive()

		if data then
            ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
			if cmd == 'at' then
				local x, y = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
                assert(x and y)
				x, y = tonumber(x), tonumber(y)
				world[ent] = {x=x, y=y}
            else
				print("unrecognised command:", cmd)
			end
        elseif msg ~= 'timeout' then 
			error("Network error: "..tostring(msg))
		end
	until not data
end

function game.draw()
    for k, v in pairs(world) do
		love.graphics.print(k, v.x, v.y)
	end
end

return game