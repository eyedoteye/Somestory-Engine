local componentFactory ={
   componentCreators = {
      ["EntityType"] = function(properties)
         local component = {
            name = "EntityType",
            type = properties.type
         }
         return component
      end,

      ["Position"] = function(properties)
         local component = {
            name = "Position",
            x = properties.x,
            y = properties.y
         }
         return component
      end,

      ["Collider.Circle"] = function(properties)
         local component = {
            name = "Collider.Circle",
            radius = properties.radius
         }
         return component
      end,

      ["Collider.CircleLine"] = function(properties)
         local component = {
            name = "Collider.CircleLine",
            radius = properties.radius,
            length = properties.length
         }
         return component
      end
   }
}

function componentFactory.createComponent(self, componentName, componentProperties)
   local componentCreator = self.componentCreators[componentName]
   if componentCreator == nil then
      error("componentFactory.createComponent: Invalid componentName")
      return nil
   end

   return componentCreator(componentProperties)
end

return componentFactory