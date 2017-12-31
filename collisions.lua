local collisionSystem = {
   collidableMap = {}, -- table[string][string] bool : Maps collidable entity types.
   movableMap = {}, -- table[string][string] bool : Maps movable entity types to their respective mover entity types.

   collisionEntities = {}, -- table: Contains all instantiated components that react witihin the collision system.
   collisionEntitiesSize = 0, -- number: Number of instantiated components within collisionEntities.
}

-- string: entityTypeComponent

-- table: positionComponent
-- float: x
-- float: y

--- table: collisionComponent
-- Circle or CircleLine
--
--    table: Circle
--       float: radius
--
--    table: CircleLine
--       float: radius
--       float: length

-- TODO:
--- Adds a collision entity to the collision system.
-- Collision entity {entityTypeComponent, positionComponent, colliderComponent}
-- @param entityTypeComponent[string]: Entity type of first colliding entity.
-- @param positionComponent[table]: Position of first colliding entity.
-- @param colliderComponent[table]: Collider of first colliding entity.
function collisionSystem.addCollisionEntity(
   self,
   entityTypeComponent,
   positionComponent,
   colliderComponent
)
   local entity = {
      entityTypeComponent = entityTypeComponent,
      positionComponent = positionComponent,
      colliderComponent = colliderComponent
   }

   self.collisionEntities[self.collisionEntitiesSize] = entity
   self.collisionEntitiesSize = self.collisionEntitiesSize + 1
end

--- Turns on collision checking between two entity types.
-- @param firstEntityType entityTypeComponent[string]: Type name of the first entity to make collidable.
-- @param secondEntityType entityTypeComponent[string]: Type name of the second entity to make collidable.
function collisionSystem.makeEntitiesCollidable(self, firstEntityType, secondEntityType)
   self.collidableMap[firstEntityType] = self.collidableMap[firstEntityType] or {}
   self.collidableMap[secondEntityType] = self.collidableMap[secondEntityType] or {}
   self.collidableMap[firstEntityType][secondEntityType] = true
   self.collidableMap[secondEntityType][firstEntityType] = true
end

--- Turns off collision checking between two entity types.
-- @param firstEntityType entityTypeComponent[string]: Type name of the first entity to make uncollidable.
-- @param secondEntityType entityTypeComponent[string]: Type name of the second entity to make uncollidable.
function collisionSystem.unmakeEntitiesCollidable(self, firstEntityType, secondEntityType)
   self.collidableMap[firstEntityType][secondEntityType] = nil
   self.collidableMap[secondEntityType][firstEntityType] = nil
end

--- Returns if two entity types are collidable.
-- @param firstEntityType entityTypeComponent[string]: Type name of first entity.
-- @param secondEntityType entityTypeComponent[string]: Type name of the second entity.
-- @returns bool: Return true if firstEntityType and secondEntityType are collidable.
function collisionSystem.areEntitiesCollidable(self, firstEntityType, secondEntityType)
   return self.collidableMap[firstEntityType][secondEntityType]
end

--- Turns on one-way movability between two entity types.
-- @param firstEntityType entityTypeComponent[string]: Type name of entity that will be made the movable.
-- @param secondEntityType entityTypeComponent[string]: Type name of entity that will be made the mover.
function collisionSystem.makeEntityMovableByEntity(self, firstEntityType, secondEntityType)
   self.movableMap[firstEntityType] = self.movableMap[firstEntityType] or {}
   self.movableMap[firstEntityType][secondEntityType] = true
end

--- Turns off one-way movability between two entity types.
-- @param firstEntityType entityTypeComponent[string]: Entity type that will no longer be the movable.
-- @param secondEntityType entityTypeComponent[string]: Entity type that will no longer be the mover.
function collisionSystem.unmakeEntityMovableByEntity(self, firstEntityType, secondEntityType)
   self.movableMap[firstEntityType][secondEntityType] = nil
end

--- Returns if first entity type is movable by second entity type.
-- @param firstEntityType entityTypeComponent[string]: Entity type to be checked for being the movable.
-- @param secondEntityType entityTypeComponent[string]: Entity type to be checked for being the mover.
function collisionSystem.isEntityMovableByEntity(self, firstEntityType, secondEntityType)
   return self.movableMap[firstEntityType][secondEntityType]
end

-- TODO: Port this from tlz
--- Checks if two entities are colliding.
-- @param firstEntity entity{
--    entityTypeComponent,
--    positionComponent,
--    colliderComponent}: First colliding entity.
-- @param secondEntity entity{
--    entityTypeComponent,
--    positionComponent,
--    colliderComponent}: Second colliding entity.
-- @return bool: True if the two entities are colliding.
-- @return collisionData[table]: Holds collision information between entities.
--    table: collisionData
--       bool: isColliding
--       table: firstToSecondDirection
--          float: x
--          float: y
--       float: distanceToProjectedCenter
function collisionSystem.areEntitiesColliding(self, firstEntity, secondEntity)
end

--- Collides all collision entities with each other and resolves their collisions.
function collisionSystem.collideAllEntities(self)
	local collisions = {}

	local i = 1
	while i <= self.collisionEntitiesSize do
		local ii = i + 1
		while ii <= self.collisionEntitiesSize do
			local collisionEntity1 = self.collisionEntities[i]
			local collisionEntity2 = self.collisionEntities[ii]

         local isColliding, collisionData = self:areEntitiesColliding(collisionEntity1, collisionEntity2)

         if isColliding then
            table.insert(collisions, {collisionEntity1, collisionEntity2, collisionData})
         end

			ii = ii + 1
		end
		i = i + 1
	end

	for _, collisionPair in pairs(collisions) do
		collisionPair[1]:onCollision(collisionPair[2], collisionPair[3])
		collisionPair[3].firstToSecondDirection.x = -collisionPair[3].firstToSecondDirection.x
		collisionPair[3].firstToSecondDirection.y = -collisionPair[3].firstToSecondDirection.y
		collisionPair[2]:onCollision(collisionPair[1], collisionPair[3])
	end
end

return collisionSystem