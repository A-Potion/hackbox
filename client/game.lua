local game = {}
local socket = require("socket")
local adress, port = "37.27.51.34", 45165

local entity
local updaterate = 0.1

local prompt = ""
local world = {}
local t
local timeleft = 0

local gameexists = false
local input = {text = ""}

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

    while gameexists == false do
        t = 0
        data, msg = udp:receive()

            if data then
                ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
                print("Asked server if game " .. code.text .. "  exists.")
                if cmd == 'dne' then
                    error = "Game does not exist"
                    nextState = require("client/menu")
                    return
                elseif cmd == 'abn' then
                    error = "Game exists, but is in progress."
                    nextState = require("client/menu")
                    return
                elseif cmd == 'code' then
                    print("Joined game ", parms)
                    gameexists = true
                end
            end
    end


end

function game.update(dt)
    if gameexists then
        t = t + dt

        
        repeat
            data, msg = udp:receive()

            if data then
                ent, cmd, parms = data:match("^(%S*) (%S*) (.*)")
                if cmd == "time" then
                    timeleft = tonumber(parms)
                elseif cmd == 'remove' then
                    print("Received remove command for " .. ent .. ".")
                    world[ent] = nil
                    if ent == entity then
                        nextState = require("client/menu")
                        udp:close()
                        return
                    end
                elseif cmd == 'start' then
                    prompt = parms
                    prompt1, prompt2 = prompt:match("([^_]+)___([^_]+)")
                    print("Received prompt: " .. prompt)
                else
                    print("Unrecognised command:", cmd)
                end
            elseif msg ~= 'timeout' then 
                error("Network error: "..tostring(msg))
            end
        until not data

    suit.layout:reset(width/8, height/2)
    suit.layout:padding(10)
    

    if timeleft > 0 then
        suit.Label("Time left: " .. math.floor(timeleft/60) .. ":" .. math.floor(timeleft%60), suit.layout:row(width/2, height/8))
    end

    if prompt == "" then
        suit.Label("Waiting for host to start the game...", {id = 1}, suit.layout:row(200, 30))
    else
        suit.Label(prompt1, {id = 1}, suit.layout:row(width/5, 30))
        suit.Input(input, {id = 2}, suit.layout:col(width/8, 30))
        suit.Label(prompt2, {id = 3}, suit.layout:col(width/5, 30))
        suit.Button("Submit", {id = 4}, suit.layout:row(width/2, 30))
    end


end
end

function game.draw()
    suit.draw()
end

function love.quit()
    local dg = string.format("%s %s %s", entity, 'quit', code.text)
    udp:send(dg)
    udp:close()
end

return game