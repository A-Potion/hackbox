local menu = {}
local name = {text = ""}
local code = {text = ""}

function menu.load()
    love.window.setTitle("HackBox - Menu")
end

function menu.update(dt)
    suit.Input(name, 100, 100, 200, 30)
    suit.Input(code, 100, 50, 200, 30)
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