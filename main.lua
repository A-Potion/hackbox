local state = {}
suit = require("lib/suit")

width, height = 960, 540
function love.load()
    love.window.setMode(width, height)
    love.window.setTitle("HackBox")

    state.current = require("client/menu")
    state.current.load()
end

function love.update(dt)
    state.current.update(dt)
end

function love.draw()
    state.current.draw()
end


-- server port: 45165
-- nest ip: 37.27.51.34
