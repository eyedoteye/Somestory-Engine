



local debugMode = false
local stableMemory = true
local paused = false
local SPEED_PER_FRAME = 1 / 60
local frame = 0


local inputSystem = require "inputSystem"
local collisionSystem = require "collisionSystem"

local systems = {
   inputSystem = inputSystem,
   collisionSystem = collisionSystem,
}

local componentFactory = require "componentFactory"
local entityFactory = require "entityFactory"



local entity1 = entityFactory:createEntity(
   {
      entityTypeComponent = componentFactory:createComponent("EntityType", {type = "Player"}),
      positionComponent = componentFactory:createComponent("Position", {x = 50, y = 50}),
      colliderComponent = componentFactory:createComponent("Collider.Circle", {radius = 10})
   }
)

local entity2 = entityFactory:createEntity(
   {
      entityTypeComponent = componentFactory:createComponent("EntityType", {type = "Ball"}),
      positionComponent = componentFactory:createComponent("Position", {x = 100, y = 50}),
      colliderComponent = componentFactory:createComponent("Collider.Circle", {radius = 10})
   }
)

collisionSystem:addCollisionEntity(
   entity1.entityTypeComponent,
   entity1.positionComponent,
   entity1.colliderComponent
)
collisionSystem:addCollisionEntity(
   entity2.entityTypeComponent,
   entity2.positionComponent,
   entity2.colliderComponent
)

collisionSystem:makeEntitiesCollidable(entity1.entityTypeComponent, entity2.entityTypeComponent)
collisionSystem:makeEntityMovableByEntity(entity2.entityTypeComponent, entity1.entityTypeComponent)

function love.load()
end

function love.draw()
	if debugMode then
		love.graphics.setColor(255, 0, 0, 255 * 0.8)
		love.graphics.print('Memory(kB): ' .. collectgarbage('count'), 5,5)
		love.graphics.print('FPS: ' .. love.timer.getFPS(), 5,25)
		love.graphics.print('Mouse: (' .. love.mouse.getX() .. ',' .. love.mouse.getY() .. ')', 85,25)
		love.graphics.setColor(255, 255, 255)
   end

   love.graphics.setColor(0, 255, 0, 255)
   love.graphics.circle(
      "fill",
      entity1.positionComponent.x, entity1.positionComponent.y,
      entity1.colliderComponent.radius,
      32)
   love.graphics.circle(
      "fill",
      entity2.positionComponent.x, entity2.positionComponent.y,
      entity2.colliderComponent.radius,
      32)
end

local function update(dt)
   --print("frame: " .. frame .. "   dt: " .. dt)

   local y = 0
   local x = 0
   if inputSystem:isDown(1, "up") then
      y = y - 1
   end
   if inputSystem:isDown(1, "down") then
      y = y + 1
   end
   if inputSystem:isDown(1, "left") then
      x = x - 1
   end
   if inputSystem:isDown(1, "right") then
      x = x + 1
   end
   local speed = 100
   entity1.positionComponent.x = entity1.positionComponent.x + x * speed * dt
   entity1.positionComponent.y = entity1.positionComponent.y + y * speed * dt

   collisionSystem:collideAllEntities()
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

function love.focus(focused)
	if not debugMode then paused = not focused end
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
