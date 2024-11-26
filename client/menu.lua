local menu = {}
local width, height = love.graphics.getDimensions()
menu.name = {text = ""}
menu.code = {text = ""}

function menu.load()
    love.window.setTitle("HackBox - Menu")
end

function menu.update(dt)
    suit.layout:reset(width/4, height/4)
    suit.layout:padding(10)

    suit.Input(menu.name, {id = 1}, suit.layout:row(200, 30))
    suit.Label("Name", {id = 2, align = "left"}, suit.layout:left(60, 30))
    suit.Label("Code", {id = 3, align = "left"}, suit.layout:down(60, 30))
    suit.Input(menu.code, {id = 4}, suit.layout:right(200, 30))
    local join = suit.Button("Join", {id = 5}, suit.layout:row(200, 30))

    if join.hit then
        
        if menu.name.text ~= "" and menu.code.text ~= "" then
            print(menu.name.text .. menu.code.text)
        end
    end

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