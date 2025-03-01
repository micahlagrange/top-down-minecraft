WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

CHUNK_DEBUG = true

function love.conf(t)
    t.title = "GameNameGoesHere"
    t.version = "11.4" -- It's a lie, we actually use 12 but makelove throws a dumb error!
    t.console = false
    t.window.width = WINDOW_WIDTH
    t.window.height = WINDOW_HEIGHT
    t.window.vsync = 0
end
