-- TODO: Add support for joystick devices (unrecognized as gamepad)
-- TODO: Add support for keyboard input
-- TODO: Add support for mouse input

local function clearTable(table)
   for key in pairs(table) do
      table[key] = nil
   end
end

local input = {
   players = {},
   index = 1,
   capacity = 2,
   size = 0,
   freeIndices = {},

   gamepadHandler = {
      joystickIDToPlayerIndex = {},
      name = "Gamepad",
      defaultConfig = {
         deadzones = {
            leftx = 0.2,
            lefty = 0.2,
            rightx = 0.2,
            righty = 0.2
         }
      }
   }

}

function input.load(self, playerMax)
   self.capacity = playerMax
end

function input.joystickadded(self, joystick)
   if (joystick:isGamepad()) then
         if (self.size ~= self.capacity) then
            local index = self.index
            while (self.players[index] ~= nil) do
               index = index + 1
            end

            self.players[index] = self.gamepadHandler:newplayer(index, joystick)

            self.size = self.size + 1
            self.index = index + 1
         end
   end
end

function input.joystickremoved(self, joystick)
   local players = self.players
   local index = self.gamepadHandler.joystickIDToPlayerIndex[joystick:getID()]

   if (players[index] ~= nil) then
      clearTable(players[index].args)
      clearTable(players[index])
      self.gamepadHandler.joystickIDToPlayerIndex[joystick:getID()] = nil
      players[index] = nil

      if (index < self.index) then
         self.index = index
      end

      self.size = self.size - 1
   end
end

function input.isDown(self, playerIndex, button)
   local player = self.players[playerIndex]
   return player ~= nil and player.controller.isDown(player.args, button) or false
end

function input.getAxis(self, playerIndex, axis, flags)
   local player = self.players[playerIndex]
   return player ~= nil and player.controller.getAxis(player.args, axis, flags) or 0
end

function input.gamepadpressed(self, joystick, button)
   self.pressed(self.gamepadHandler.joystickIDToPlayerIndex[joystick:getID()], button)
end

function input.gamepadreleased(self, joystick, button)
   self.released(self.gamepadHandler.joystickIDToPlayerIndex[joystick:getID()], button)
end

function input.gamepadHandler.newplayer(self, index, joystick, config)
   config = config or self.defaultConfig

   local player = {
      index = index,
      controller = self,
      args = {
         joystick = joystick,
         deadzones = config.deadzones or self.defaultConfig.deadzones
      }
   }

   self.joystickIDToPlayerIndex[joystick:getID()] = index

   return player
end

function input.gamepadHandler.isDown(args, button)
   return args.joystick:isGamepadDown(button)
end

function input.gamepadHandler.getAxis(args, axis, flags)
   local raw = false

   if (flags ~= nil) then
     raw = flags.raw or raw
   end

   if (raw) then
      return args.joystick:getGamepadAxis(axis)
   end

   local v = args.joystick:getGamepadAxis(axis)

   if (math.abs(v) > args.deadzones[axis]) then
      return args.joystick:getGamepadAxis(axis)
   end

   return 0
end

-- TODO: Figure out what these are for
function input.pressed(player, button) end
function input.released(player, button) end

function input.debugString(self)
   local s =
      "---input---"
      .. "\nsize: " .. self.size
      .. "\ncapacity: " .. self.capacity
      .. "\nindex: " .. self.index
      .. "\nfreeIndices:"

   local i = 0
   for _, v in pairs(self.freeIndices) do
      s = s .. " " .. v
      i = i + 1
   end
   if (i == 0) then
      s = s .. " nil"
   end

   for k, v in pairs(self.players) do
      s = s .. "\nPlayer#" .. k
            .. "\n controller: " .. v.controller.name
   end

   for k, v in pairs(self.gamepadHandler.joystickIDToPlayerIndex) do
      local leftx = self:getAxis(v, "leftx")
      local leftx_raw = self:getAxis(v, "leftx", {raw = true})
      local lefty = self:getAxis(v, "lefty")
      local lefty_raw = self:getAxis(v, "lefty", {raw = true})

      local rightx = self:getAxis(v, "rightx")
      local rightx_raw = self:getAxis(v, "rightx", {raw = true})
      local righty = self:getAxis(v, "righty")
      local righty_raw = self:getAxis(v, "righty", {raw = true})

      s = s .. "\nGamepad#" .. k
            .. "\n player: " .. v
            .. "\n leftx: " .. leftx
            .. "\n  raw: " .. leftx_raw
            .. "\n lefty: " .. lefty
            .. "\n  raw: " .. lefty_raw
            .. "\n = left(dir): " .. math.deg(math.atan2(lefty, leftx))
            .. "\n =       raw: " .. math.deg(math.atan2(lefty_raw, leftx_raw))
            .. "\n rightx: " .. rightx
            .. "\n  raw: " .. rightx_raw
            .. "\n righty: " .. righty
            .. "\n  raw: " .. righty_raw
            .. "\n = right(dir): " .. math.deg(math.atan2(righty, rightx))
            .. "\n =         raw: " .. math.deg(math.atan2(righty_raw, rightx_raw))
            .. "\n leftshoulder: " .. (self:isDown(k, "leftshoulder") and "true" or "false")
            .. "\n rightshoulder: " .. (self:isDown(k, "rightshoulder") and "true" or "false")
            .. "\n start: " .. (self:isDown(k, "start") and "true" or "false")
   end

   -- Intentional access of undefined variable 'love'
   -- Global exists in love2d v0.10.2 api:
   --    https://love2d.org/w/index.php?title=love.joystick.getJoystickCount&oldid=11320
   s = s .. "\n#Of [All] Detected Controllers: " .. love.joystick.getJoystickCount()

   return s .. "\n"
end

-- Intentional mutation of non-standard global variable 'love'
-- Implementation of love2d v0.10.2 api:
--    https://love2d.org/w/index.php?title=love.joystickadded&oldid=11897
function love.joystickadded(joystick)
   input:joystickadded(joystick)
end

-- Intentional mutation of non-standard global variable 'love'
-- Implementation of love2d v0.10.2 api:
--    https://love2d.org/w/index.php?title=love.joystickremoved&oldid=11902
function love.joystickremoved(joystick)
   input:joystickremoved(joystick)
end

-- Intentional mutation of non-standard global variable 'love'
-- Implementation of love2d v0.10.2 api:
--    https://love2d.org/w/index.php?title=love.gamepadpressed&oldid=11895
function love.gamepadpressed(joystick, button)
   input:gamepadpressed(joystick, button)
end

-- Intentional mutation of non-standard global variable 'love'
-- Implementation of love2d v0.10.2 api:
--    https://love2d.org/w/index.php?title=love.gamepadreleased&oldid=11896
function love.gamepadreleased(joystick, button)
   input:gamepadreleased(joystick, button)
end

return input