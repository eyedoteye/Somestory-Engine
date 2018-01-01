local entityFactory = {
   usedIdsSinceRuntimeStart = {}
}

function entityFactory.createEntity(self, entityComponents)
   local entity = entityComponents
   local id = math.random()
   local collisions = 0
   while collisions < 10 and self.usedIdsSinceRuntimeStart[id] ~= nil do
      print("entityID collision: " .. id)
      id = math.random()
   end
   self.usedIdsSinceRuntimeStart[id] = true
   entity.id = id
   return entity
end

return entityFactory