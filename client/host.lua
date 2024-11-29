local host = {}
local socket = require("socket")
local adress, port = "37.27.51.34", 45165


local entity
local updaterate = 0.1
local code = "loading..."
local users = {}
local timeleft = -1
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
            elseif cmd == 'join' then
                table.insert(users, ent)
            elseif cmd == 'remove' then
                print("Received remove command.")
                for i, user in ipairs(users) do
                    if user == ent then
                        table.remove(users, i)
                        break
                    end
                end
            elseif cmd == 'time' then
                timeleft = tonumber(parms)
            else
				print("unrecognised command:", cmd)
			end
        elseif msg ~= 'timeout' then
			error("Network error: "..tostring(msg))
		end
	until not data

    suit.layout:reset(width/2, height/2)
    suit.layout:padding(10)
    if timeleft > 0 then
        suit.Label("Time left: " .. math.floor(timeleft/60) .. ":" .. math.floor(timeleft%60), suit.layout:row(200, 30))
    end

    suit.Label("Code: " .. code, suit.layout:row(200, 30))


    if #users ~= 0 then
        if suit.Button("Start!", suit.layout:row(200, 30)).hit then
            local dg = string.format("placeholder %s %s", 'start', code)
            udp:send(dg)
       end
        for i=1, #users do
           if suit.Button(users[i], suit.layout:row(200, 30)).hit then
                local dg = string.format("%s %s %s", users[i], 'quit', code)
                udp:send(dg)
           end
           if #users == 0 then
                nextState = require("client/menu")
                udp:close()
                return
           end
        end
    end

    

end

function love.quit()
    local dg = string.format("placeholder %s %s", 'end', code)
    udp:send(dg)
    udp:close()
end

function host.draw()
    suit.draw()
    
end

return host