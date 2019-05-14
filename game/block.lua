local table2 = require "util.table2"
local Timer = require "util.timer"

local Block = {}

local image = love.graphics.newImage("assets/images/block.png")
local imageBreakable = love.graphics.newImage("assets/images/breakableBlock.png")

function Block.initAtrandom(w, h, game)
local xl = {1 + 8, 1 + 8, 17 - 1, 1 + 1}
local yl = {17 - 1, 1 + 1, 1 + 8, 1 + 8}
  for y=1, h do
    for x=1, w do
      if x==1 or x==w or y==1 or y==w then
        Block:new(x, y, game, false)
      elseif x%2==1 and y%2==1 then
        Block:new(x, y, game, false)
      elseif math.random() < 0.5 or
        ((x==xl[1] and y==yl[1]) or (x==xl[1] - 1 and y==yl[1]) or (x==xl[1] - 1 and y==yl[1] - 1)) or
        ((x==xl[2] and y==yl[2]) or (x==xl[2] - 1 and y==yl[2]) or (x==xl[2] - 1 and y==yl[2] + 1)) or
        ((x==xl[3] and y==yl[3]) or (x==xl[3] and y==yl[3] - 1) or (x==xl[3] - 1 and y==yl[3] - 1)) or
        ((x==xl[4] and y==yl[4]) or (x==xl[4] and y==yl[4] - 1) or (x==xl[4] + 1 and y==yl[4] - 1)) then
      else
        Block:new(x, y, game, true)
      end
    end
  end
end

function Block:new(x, y, game, isBreakable)
  local t = {x=x,y=y,game=game,isBreakable=isBreakable or false,isBreaking=false}
  table.insert(game.blocks, t)
  return setmetatable(t, {__index=self})
end

function Block:draw()
  love.graphics.push()

  local stageX, stageY = self.game:stagePosition(self.x, self.y)
  if self.isBreakable then
    love.graphics.draw(imageBreakable, stageX-4, stageY-4)
  else
    love.graphics.draw(image, stageX-4, stageY-4)
  end
  love.graphics.pop()
end

function Block:update(dt)
  if self.delayTimer ~= nil then
    if self.delayTimer:executable(dt) then
      self:delete()
    end
  end
end

function Block:delayedDelete(delay)
  delay = delay or 0.1
  self.delayTimer = Timer:new(delay, 1)
  self.isBreaking = true
end

function Block:delete()
  table2.removeItem(self.game.blocks, self)
end

return Block
