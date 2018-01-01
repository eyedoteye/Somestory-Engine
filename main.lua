local debugMode = false
local stableMemory = true
local paused = false

inputSystem = require "inputSystem"
collisionSystem = require "collisionSystem"

function love.load()
end

function love.draw()
	if debugMode then
		love.graphics.setColor(255,0,0,255 * 0.8)
		love.graphics.print('Memory(kB): ' .. collectgarbage('count'), 5,5)
		love.graphics.print('FPS: ' .. love.timer.getFPS(), 5,25)
		love.graphics.print('Mouse: (' .. love.mouse.getX() .. ',' .. love.mouse.getY() .. ')', 85,25)
		love.graphics.setColor(255,255,255)
	end
end

function love.focus(focused)
	if not debugMode then paused = not focused end
end

local SPEED_PER_FRAME = 1 / 60
local frame = 0

local function update(dt)
   print("frame: " .. frame .. "   dt: " .. dt)
end

function love.update(dt)
	if debugMode and stableMemory then
		collectgarbage()
   end

	if not paused then
      frame = frame + 1

      local remainingTime = dt

      while remainingTime > 0 do
         if remainingTime > SPEED_PER_FRAME then
            update(SPEED_PER_FRAME)
            remainingTime = remainingTime - dt
         else
            update(remainingTime)
            remainingTime = 0
         end
      end
	end
end

function love.keypressed(key)
	if key == '`' then
		debugMode = not debugMode
	end
	if key == '1' and debugMode then
		paused = not paused
	end
	if key == '2' and debugMode then
		stableMemory = not stableMemory
	end
end