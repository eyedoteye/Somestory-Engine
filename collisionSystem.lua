--[[function rPrint(s, l, i) -- recursive Print (structure, limit, indent)
	l = (l) or 100; i = i or "";	-- default item limit, indent string
	if (l<1) then print "ERROR: Item limit reached."; return l-1 end;
	local ts = type(s);
	if (ts ~= "table") then print (i,ts,s); return l-1 end
	print (i,ts);           -- print "table"
	for k,v in pairs(s) do  -- print "[KEY] VALUE"
		l = rPrint(v, l, i.."\t["..tostring(k).."]");
		if (l < 0) then break end
	end
	return l
end]]



local collisionSystem = {
   collidableMap = {}, -- table[string][string] bool : Maps collidable entity types.
   movableMap = {}, -- table[string][string] bool : Maps movable entity types to their respective mover entity types.

   collisionEntities = {}, -- list: Contains all instantiated components that react witihin the collision system.
   collisionEntitiesSize = 0, -- number: Number of instantiated components within collisionEntities.
   collisionEntityIDToIndex = {} -- hashmap: Maps collision entity id to index within collisionEntities.
}

-- entity ids are random floats

-- table: EntityTypeComponent
-- name: EntityType
-- string: type

-- table: PositionComponent
-- name: Position
-- number: x
-- number: y

--- table: ColliderComponent
-- Circle or CircleLine
--
--    table: Circle
--       name: Collider.Circle
--       float: radius
--
--    table: CircleLine
--       name: Collider.CircleLine
--       float: radius
--       float: length

-- TODO:
--- Adds a collision entity to the collision system.
-- Collision entity {id, entityTypeComponent, positionComponent, colliderComponent}
-- @param entityTypeComponent[string]: Entity type of first colliding entity.
-- @param positionComponent[table]: Position of first colliding entity.
-- @param colliderComponent[table]: Collider of first colliding entity.
-- @return number: Collision entity id.
function collisionSystem.addCollisionEntity(
   self,
   entityTypeComponent,
   positionComponent,
   colliderComponent
)
   local entity = {
      id = math.random(),
      entityTypeComponent = entityTypeComponent,
      positionComponent = positionComponent,
      colliderComponent = colliderComponent,
   }

   self.collisionEntities[self.collisionEntitiesSize + 1] = entity
   self.collisionEntitiesSize = self.collisionEntitiesSize + 1

   return entity.id
end

function collisionSystem.removeCollisionEntity(self, id)
   local index = self.collisionEntityIDToIndex[id]

   local replacementEntity = self.collisionEntities[self.collisionEntitiesSize]
   self.collisionEntityIDToIndex[replacementEntity.id] = index
   self.collisionEntities[index] = replacementEntity

   self.collisionEntities[self.collisionEntitiesSize] = nil
   self.collisionEntityIDToIndex[id] = nil

   self.collisionEntitiesSize = self.collisionEntitiesSize - 1
end

--- Turns on collision checking between two entity types.
-- @param firstEntityType entityTypeComponent: Type name of the first entity to make collidable.
-- @param secondEntityType entityTypeComponent: Type name of the second entity to make collidable.
function collisionSystem.makeEntitiesCollidable(self, firstEntityType, secondEntityType)
   self.collidableMap[firstEntityType] = self.collidableMap[firstEntityType] or {}
   self.collidableMap[secondEntityType] = self.collidableMap[secondEntityType] or {}
   self.collidableMap[firstEntityType][secondEntityType] = true
   self.collidableMap[secondEntityType][firstEntityType] = true
end

--- Turns off collision checking between two entity types.
-- @param firstEntityType entityTypeComponent: Type name of the first entity to make uncollidable.
-- @param secondEntityType entityTypeComponent: Type name of the second entity to make uncollidable.
function collisionSystem.unmakeEntitiesCollidable(self, firstEntityType, secondEntityType)
   self.collidableMap[firstEntityType][secondEntityType] = nil
   self.collidableMap[secondEntityType][firstEntityType] = nil
end

--- Returns if two entity types are collidable.
-- @param firstEntityType entityTypeComponent: Type name of first entity.
-- @param secondEntityType entityTypeComponent: Type name of the second entity.
-- @returns bool: Return true if firstEntityType and secondEntityType are collidable.
function collisionSystem.areEntitiesCollidable(self, firstEntityType, secondEntityType)
   if self.collidableMap[firstEntityType] == nil then
      return false
   end
   return self.collidableMap[firstEntityType][secondEntityType]
end

--- Turns on one-way movability between two entity types.
-- @param firstEntityType entityTypeComponent: Type name of entity that will be made the movable.
-- @param secondEntityType entityTypeComponent: Type name of entity that will be made the mover.
function collisionSystem.makeEntityMovableByEntity(self, firstEntityType, secondEntityType)
   self.movableMap[firstEntityType] = self.movableMap[firstEntityType] or {}
   self.movableMap[firstEntityType][secondEntityType] = true
end

--- Turns off one-way movability between two entity types.
-- @param firstEntityType entityTypeComponent: Entity type that will no longer be the movable.
-- @param secondEntityType entityTypeComponent: Entity type that will no longer be the mover.
function collisionSystem.unmakeEntityMovableByEntity(self, firstEntityType, secondEntityType)
   self.movableMap[firstEntityType][secondEntityType] = nil
end

--- Returns if first entity type is movable by second entity type.
-- @param firstEntityType entityTypeComponent: Entity type to be checked for being the movable.
-- @param secondEntityType entityTypeComponent: Entity type to be checked for being the mover.
function collisionSystem.isEntityMovableByEntity(self, firstEntityType, secondEntityType)
   if self.movableMap[firstEntityType] == nil then
      return false
   end
   return self.movableMap[firstEntityType][secondEntityType]
end

local function areCirclesColliding(
   x1, y1, r1,
   x2, y2, r2
)
	local offsetX = x2 - x1
	local offsetY = y2 - y1
   local distance = math.sqrt(offsetX * offsetX + offsetY * offsetY)

   local totalRadius = r1 + r2

   local isColliding = false
   if distance <= totalRadius then
      isColliding = true
   end

   local collisionData = {
      isColliding = isColliding,
      firstToSecondDirection = {
         x = -offsetX / distance,
         y = -offsetY / distance
      },
      secondToFirstDirection = {
         x = offsetX / distance,
         y = offsetY / distance
      },
      distanceBetweenCenters = distance,
      displacementDistance = totalRadius - distance,
   }

	return isColliding, collisionData
end

-- TODO: Port this from tlz
--- Collides two entities and resolves any needed position displacements.
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
--       table: secondToFirstDirection
--          float: x
--          float: y
--       float: distanceBetweenCenters
--       float: displacementDistance
local function collideEntities(collisionSystem, firstEntity, secondEntity)
   if firstEntity.colliderComponent.name == "Collider.Circle" then
      if secondEntity.colliderComponent.name == "Collider.Circle" then
         local isColliding, collisionData = areCirclesColliding(
            firstEntity.positionComponent.x, firstEntity.positionComponent.y, firstEntity.colliderComponent.radius,
            secondEntity.positionComponent.x, secondEntity.positionComponent.y, secondEntity.colliderComponent.radius
         )

         if isColliding then
            if collisionSystem:isEntityMovableByEntity(
               secondEntity.entityTypeComponent,
               firstEntity.entityTypeComponent
            ) then

               if collisionSystem:isEntityMovableByEntity(
                  firstEntity.entityTypeComponent,
                  secondEntity.entityTypeComponent
               ) then
                  collisionData.displacementDistance = collisionData.displacementDistance / 2

                  firstEntity.positionComponent.x = firstEntity.positionComponent.x +
                     collisionData.firstToSecondDirection.x * collisionData.displacementDistance
                  firstEntity.positionComponent.y = firstEntity.positionComponent.y +
                     collisionData.firstToSecondDirection.y * collisionData.displacementDistance
               end

               secondEntity.positionComponent.x = secondEntity.positionComponent.x +
                  collisionData.secondToFirstDirection.x * collisionData.displacementDistance
               secondEntity.positionComponent.y = secondEntity.positionComponent.y +
                  collisionData.secondToFirstDirection.y * collisionData.displacementDistance

            elseif collisionSystem:isEntityMovableByEntity(
               firstEntity.entityTypeComponent,
               secondEntity.entityTypeComponent
            ) then
               firstEntity.positionComponent.x = firstEntity.positionComponent.x +
                  collisionData.firstToSecondDirection.x * collisionData.firstDisplacementDistance
               firstEntity.positionComponent.y = firstEntity.positionComponent.y +
                  collisionData.firstToSecondDirection.y * collisionData.firstDisplacementDistance
            end
         end

         return isColliding, collisionData

      elseif secondEntity.colliderComponent.name == "Collider.CircleLine" then
         print("collideEntities: Collider.Circle + Collider.CircleLine not implemented")
      end
   elseif firstEntity.colliderComponent.name == "Collider.CircleLine" then
      if secondEntity.colliderComponent.name == "Collider.Circle" then
         print("collideEntities: Collider.CircleLine + Collider.Circle not implemented")
      elseif secondEntity.colliderComponent.name == "Collider.CircleLine" then
         print("collideEntities: Collider.CircleLine + Collider.CircleLine not implemented")
      end
   end
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

         --print("i = .. " .. i .. "   ii = " .. ii)
         if collisionEntity1 == nil then
            print("collisionEntity1 == nil   i = " .. i .. "   ii = " .. ii)
         end
         if collisionEntity2 == nil then
            print("collisionEntity2 == nil   i = " .. i .. "   ii = " .. ii)
         end
         local isColliding, collisionData = collideEntities(collisionSystem, collisionEntity1, collisionEntity2)

         if isColliding then
            table.insert(collisions, {collisionEntity1, collisionEntity2, collisionData})
         end

			ii = ii + 1
		end
		i = i + 1
	end

   --[[
	for _, collisionPair in pairs(collisions) do
		collisionPair[1]:onCollision(collisionPair[2], collisionPair[3])
		collisionPair[3].firstToSecondDirection.x = -collisionPair[3].firstToSecondDirection.x
		collisionPair[3].firstToSecondDirection.y = -collisionPair[3].firstToSecondDirection.y
		collisionPair[2]:onCollision(collisionPair[1], collisionPair[3])
   end
   ]]--
end

return collisionSystem