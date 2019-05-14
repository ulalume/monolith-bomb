local Timer = require "util.timer"
local table2 = require "util.table2"
local Explosion = require "game.explosion"
local anim8 = require 'anim8'

local image = love.graphics.newImage("assets/images/bomb.png")


local Bomb = {}
function Bomb:new(x,y,power,game,lifeTime)
  local grid = anim8.newGrid(8,8,image:getWidth(), image:getHeight())
  local t = {x=x,y=y,isBombed=false,power=power,game=game,
    anim=anim8.newAnimation(grid("1-4", 1), 0.1),
    lifeTimer=Timer:new(lifeTime or 3, 1)}
  table.insert(game.bombs, t)
  return setmetatable(t,{__index=self})
end

local function explosion(x,y,game,dir,isLast)
  local block = game:getBlock(x, y)
  if block == nil then
    Explosion:new(x,y,game,1,Explosion.getType(dir,isLast))
    return true
  end
  if block.isBreakable then
    Explosion:new(x,y,game,1,Explosion.getType(dir,true))
    return false
  end
  return false
end

function Bomb:update(dt)
  self.anim:update(dt)
  if self.lifeTimer:executable(dt) then
    self:bomb()
  end
end

function Bomb:bomb()
    local x,y,game,power=self.x,self.y,self.game,self.power
    explosion(x,y,game,Explosion.getType("center"))
    for i=1,power do if not explosion(x, y-i, game, "up", i==power) then break end end
    for i=1,power do if not explosion(x, y+i, game, "down", i==power) then break end end
    for i=1,power do if not explosion(x-i, y, game, "left", i==power) then break end end
    for i=1,power do if not explosion(x+i, y, game, "right", i==power) then break end end
    self:delete()
end

function Bomb:draw()
  love.graphics.push()
  love.graphics.setColor(1,1,1,1)
  local stageX, stageY = self.game:stagePosition(self.x, self.y)
  self.anim:draw(image, stageX-4, stageY-4)
  love.graphics.pop()
end

function Bomb:delete()
  table2.removeItem(self.game.bombs, self)
  self.isBombed = true
end

return Bomb
