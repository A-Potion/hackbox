local menu = {}
local name = {text = ""}
local code = {text = ""}

function menu.load()
    love.window.setTitle("HackBox - Menu")
end

function menu.update(dt)
    suit.layout:reset(width/2, height/2)
    suit.layout:padding(10)

    suit.Input(name, {id = 1}, suit.layout:row(200, 30))
    suit.Label("Name", {id = 2, align = "left"}, suit.layout:left(60, 30))
    suit.Label("Code", {id = 4, align = "left"}, suit.layout:down(60, 30))
    suit.Input(code, {id = 3}, suit.layout:right(200, 30))
    suit.Button("Join", {id = 5}, suit.layout:row(200, 30))
    
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