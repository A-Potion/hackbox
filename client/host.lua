local host = {}
local socket = require("socket")
local adress, port = "37.27.51.34", 45165


local entity
local updaterate = 0.1
local t
local code, timeleft, voting_now, preview_now, round
local world = {}
local round = 1
local display = {}


local width, height = love.graphics.getDimensions()

function host.load()
    code = "loading..."
    users = {}
    timeleft = -1

    love.window.setTitle("HackBox - Hosting: " .. code)
    udp = socket.udp()

    udp:settimeout(0)
    udp:setpeername(adress, port)

    math.randomseed(os.time())

    print("Asking server for code...")
    local dg = string.format("%s %s %s", entity, 'new', 'code')
    udp:send(dg)
    t = 0
end

function host.update(dt)
    t = t + dt

    suit.layout:reset(10, 10)
    if suit.Button("End", suit.layout:row(200, 30)).hit then
        local dg = string.format("placeholder %s %s", 'end', code)
        print("Sent request to end game " .. code .. " to server.")
        udp:send(dg)
        udp:close()
        nextState = require("client/menu")
        return
    end

    
    repeat
		data, msg = udp:receive()

		if data then
            ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
            if cmd == 'code' then
				code = parms
                print("Received code:" .. code)
            elseif cmd == 'join' then
                table.insert(users, ent)
            elseif cmd == 'remove' then
                print("Received remove command for " .. ent .. ".")
                for i, user in ipairs(users) do
                    if user == ent then
                        table.remove(users, i)
                        break
                    end
                end
            elseif cmd == 'time' then
                timeleft = tonumber(parms)
            elseif cmd == 'answer' then
                round, answer = parms:match("^(%S*) (.*)")
                round = tonumber(round)
                table.insert(world[round], answer)
                print("Received answer from " .. ent .. " for round " .. round .. ": " .. answer)
            elseif cmd == 'start' then
                world[round] = {}
                display[round] = {}
                print("Received start command and sentence: " .. parms)
            elseif cmd == 'voting' then
                if parms == 'preview' then
                    preview_now = true
                    voting_now = false
                elseif parns == 'start' then
                    voting_now = true
                    preview_now = false
                elseif parms == 'end' then
                    voting_now = false
                    preview_now = false
                end
            else
				print("Unrecognised command:", cmd)
			end
        elseif msg ~= 'timeout' then
			error("Network error: "..tostring(msg))
		end
	until not data

    suit.layout:reset(width/3, height/3)
    suit.layout:padding(10)
    if timeleft > 0 then
        suit.Label("Time left: " .. math.floor(timeleft/60) .. ":" .. math.floor(timeleft%60), suit.layout:row(200, 30))
    end

    suit.Label("Code: " .. code, suit.layout:row(200, 30))


    if #users ~= 0 then
        if timeleft <= 0 then
            if suit.Button("Start!", suit.layout:row(200, 30)).hit then
                print("Sent request to start game " .. code .. " to server.")
                local dg = string.format("placeholder %s %s", 'start', code)
                udp:send(dg)
            end
        end
        for i=1, #users do
           if suit.Button(users[i], suit.layout:row(200, 30)).hit then
                local dg = string.format("%s %s %s", users[i], 'quit', code)
                udp:send(dg)
           end
        end
    end

    if preview_now == true then
        if display[round].started ~= true then
            display[round].started = true
            display[round].elapsed = 0
            display[round].displaying = 1
        end
        display[round].elapsed = display[round].elapsed + dt

        if display[round].elapsed % 5 == 0 then
            display[round].displaying = display[round].displaying + 1
            if display[round].displaying > #world[round] then
                preview_now = false
                voting_now = true
                dg = string.format("placeholder %s %s", 'voting', 'preview_done')
                udp:send(dg)
            end
        end
        print(world[round][display[round].displaying])
        suit.Label(world[round][display[round].displaying], suit.layout:row(width/2, 30))
    end

    

end

function love.quit()
    local dg = string.format("placeholder %s %s", 'end', code)
    print("Sent request to end game " .. code .. " to server.")
    udp:send(dg)
    udp:close()
end

function host.draw()
    suit.draw()
    
end

return host