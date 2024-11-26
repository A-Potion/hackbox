local menu = {}
local width, height = love.graphics.getDimensions()
name = {text = ""}
code = {text = ""}

function menu.load()
    love.window.setTitle("HackBox - Menu")
end

function menu.update(dt)
    -- Join menu layout
    suit.layout:reset(width/4, height/4)
    suit.layout:padding(10)

    -- Join menu layout elements
    suit.Input(name, {id = 1}, suit.layout:row(200, 30))
    suit.Label("Name", {id = 2, align = "left"}, suit.layout:left(60, 30))
    suit.Label("Code", {id = 3, align = "left"}, suit.layout:down(60, 30))
    suit.Input(code, {id = 4}, suit.layout:right(200, 30))
    local join = suit.Button("Join", {id = 5}, suit.layout:row(200, 30))

    -- Join info passing
    if join.hit then
        if name.text ~= "" and code.text ~= "" then
            print(name.text .. " joins " .. code.text)
            nextState = require("client/game")
            return
        end
    end

    -- Host menu layout & elem
    suit.layout:reset((width/4) * 3, height/4)
    suit.Button("Host", {id = 6}, suit.layout:row(200, 30))

end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key)
    suit.keypressed(key)
end

function menu.draw()
    suit.draw()
end

return menu