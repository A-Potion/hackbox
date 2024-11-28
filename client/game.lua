local game = {}
local socket = require("socket")
local adress, port = "37.27.51.34", 45165

local entity
local updaterate = 0.1

local world = {}
local t

local gameexists = false

local width, height = love.graphics.getDimensions()

function game.load()
    love.window.setTitle("HackBox - Game: " .. code.text)
    udp = socket.udp()
    gameexists = false

    udp:settimeout(0)
    udp:setpeername(adress, port)

    entity = name.text

    local dg = string.format("%s %s %s", entity, "join", code.text)
    udp:send(dg)

    while not gameexists do
        t = 0
        data, msg = udp:receive()

            if data then
                ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
                print("Checking if game exists...")
                if cmd == 'dne' then
                    print("Game does not exist")
                    nextState = require("client/menu")
                    return
                elseif cmd == 'abn' then
                    print("Game exists, but is in progress.")
                    nextState = require("client/menu")
                    return
                elseif cmd == 'code' then
                    print("Code: ", parms)
                    gameexists = true
                end
            end
    end


end

function game.update(dt)
    t = t + dt

    if t > updaterate then
        local x, y = 0, 0
        if love.keyboard.isDown('up') then 	y=y-(20*t) end
		if love.keyboard.isDown('down') then 	y=y+(20*t) end
		if love.keyboard.isDown('left') then 	x=x-(20*t) end
		if love.keyboard.isDown('right') then 	x=x+(20*t) end

        local dg = string.format("%s %s %s %d %d", entity, 'move', code.text, x, y)
		udp:send(dg)

        local dg = string.format("%s %s %s", entity, 'update', code.text)
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
            elseif cmd == 'remove' then
                print("Received remove command.")
                world[ent] = nil
                if ent == entity then
                    nextState = require("client/menu")
                    return
                end
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

function love.quit()
    local dg = string.format("%s %s %s", entity, 'quit', code.text)
    udp:send(dg)
    udp:close()
end

return game