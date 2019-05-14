local table2 = require "util.table2"

local Item = {}
Item.type = {}
Item.type.power = 0
Item.type.plus = 1

local imagePower = love.graphics.newImage("assets/images/itemPower.png")
local imagePlus = love.graphics.newImage("assets/images/itemPlus.png")

function Item:new(x,y,type,game)
  local t = {x=x,y=y,game=game,type=type}
  table.insert(game.items, t)
  return setmetatable(t, {__index=self})
end

function Item:draw()
  love.graphics.push()
  love.graphics.setColor(1, 1, 1, 1)

  local stageX, stageY = self.game:stagePosition(self.x, self.y)
  if self.type == Item.type.power then
    love.graphics.draw(imagePower, stageX-4, stageY-4)
  elseif self.type == Item.type.plus then
    love.graphics.draw(imagePlus, stageX-4, stageY-4)
  end
  love.graphics.pop()
end

function Item:delete()
  table2.removeItem(self.game.items, self)
end

return Item
