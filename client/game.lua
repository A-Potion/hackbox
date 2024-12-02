local game = {}
local socket = require("socket")
local adress, port = "37.27.51.34", 45165

local entity
local updaterate = 0.1

local prompt
local world = {}
local timeleft, round, t, preview_now, voting_now
local submitted = {}
local myanswer = { text = "" }

local gameexists = false
local input = {text = ""}
round = 0

local width, height = love.graphics.getDimensions()

function game.load()
    prompt = ""

    love.window.setTitle("HackBox - Game: " .. code.text)
    udp = socket.udp()
    gameexists = false
    timeleft = 0

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
                elseif cmd == 'code' then
                    print("Joined game ", parms)
                    gameexists = true
                elseif cmd == 'uat' then
                    error = "Please choose a different username."
                    nextState = require("client/menu")
                    return
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
                        udp:close()
                        nextState = require("client/menu")
                        return
                    end
                elseif cmd == 'answer' then
                    round, answer = parms:match("^(%S+)%s+(.*)")
                    round = tonumber(round)

                    if not world[round] then
                        world[round] = {}
                    end
                    table.insert(world[round], answer)
                elseif cmd == 'voting' then
                    if parms == 'preview' then
                        preview_now = true
                    elseif parns == 'start' then
                        voting_now = true
                        preview_now = false
                    elseif parms == 'end' then
                        voting_now = false
                    end
                elseif cmd == 'start' then
                    prompt = parms
                    prompt1, prompt2 = prompt:match("([^_]+)___([^_]+)")
                    print("Received prompt: " .. prompt)
                    round = round + 1
                    submitted[round] = false
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
    elseif prompt ~= "" and preview_now ~= true then
        suit.Label(prompt1, {id = 1}, suit.layout:row(width/5, 30))
        if submitted[round] == false then
            suit.Input(myanswer, {id = 2}, suit.layout:col(width/8, 30))
        else
            suit.Label(myanswer.text, {id = 2}, suit.layout:col(width/8, 30))
        end
        
        suit.Label(prompt2, {id = 3}, suit.layout:col(width/5, 30))



        if submitted[round] == false then
            if suit.Button("Submit", {id = 4}, suit.layout:row(width/2, 30)).hit then
                if myanswer.text ~= "" then
                    local dg = string.format("%s %s %s %s", entity, 'submit', code.text, myanswer.text)
                    submitted[round] = true
                    udp:send(dg)
                    print(dg)
                end
            end
        end
    end

    if preview_now == true then
        for i=1, #world[round] do
            if world[round][i] ~= myanswer.text then
                if suit.Button(world[round][i], suit.layout:row(width/2, 30)).hit then
                local dg = string.format("%s %s %s %i %s", entity, 'vote', code.text, round, world[round][i])
                udp:send(dg)
                print(dg)
                end
            end
        end
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