local state = {}
suit = require("lib/suit")
nextState = require("client/menu")

width, height = 960, 540
function love.load()
    love.window.setMode(width, height)
    love.window.setTitle("HackBox")

    state.current = require("client/menu")
    state.current.load()
end

function love.update(dt)
    if nextState ~= state.current then
        state.current = nextState
        state.current.load()
    end
    state.current.update(dt)

end

function love.draw()
    state.current.draw()
end

-- server port: 45165
-- nest ip: 37.27.51.34
