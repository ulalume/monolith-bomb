local Item = require "game.item"

local Timer = require "util.timer"
local table2 = require "util.table2"
local Rainbow = require "graphics.rainbow"
local mycolor = require "graphics.color"


local Explosion = {}
Explosion.type={}
Explosion.type.up=0
Explosion.type.upLast=1
Explosion.type.down=2
Explosion.type.downLast=3
Explosion.type.left=4
Explosion.type.leftLast=5
Explosion.type.right=6
Explosion.type.rightLast=7
Explosion.type.center=8

local rainbow = Rainbow:new(3/60,{ mycolor.yellow, mycolor.magenta, mycolor.red,mycolor.black, })

function Explosion.getType(dir, isLast)
  if dir=="center" then return Explosion.type.center end
  if dir=="up" and not isLast then return Explosion.type.up end
  if dir=="up" and isLast then return Explosion.type.upLast end
  if dir=="down" and not isLast then return Explosion.type.down end
  if dir=="down" and isLast then return Explosion.type.downLast end
  if dir=="left" and not isLast then return Explosion.type.left end
  if dir=="left" and isLast then return Explosion.type.leftLast end
  if dir=="right" and not isLast then return Explosion.type.right end
  if dir=="right" and isLast then return Explosion.type.rightLast end
end

function Explosion:new(x,y,game,lifeTime,type)
  local t = {x=x,y=y,
    type=type or Explosion.type.center,
    lifeTimer=Timer:new(lifeTime or 1, 1),
    item=nil,
    game=game,
    sound=sound}
  table.insert(game.explosions, t)

  game.musicSystem:playAllPlayer("explosion")

  return setmetatable(t,{__index=self})
end

function Explosion:update(dt)


  if self.lifeTimer:executable(dt) then

    if self.item ~= nil then
      Item:new(self.x,self.y,self.item,self.game)
    end
    self:delete()
    return
  end

  for _,p in ipairs(self.game.players) do
    local x, y = p:roundPosition()
    if x==self.x and y==self.y then
      p:delete()
    end
  end

  for _,b in ipairs(self.game.bombs) do
    if b.x==self.x and b.y==self.y then
      b:bomb()
    end
  end

  for _,b in ipairs(self.game.blocks) do
    if not b.isBreaking and b.isBreakable and b.x==self.x and b.y==self.y then
      b:delayedDelete()
      local ran = love.math.random(1,5)
      if ran == 1 then
        self.item=Item.type.power
      elseif ran == 2 then
        self.item=Item.type.plus
      end
    end
  end

end
function Explosion:draw()
  love.graphics.push()
  local stageX, stageY = self.game:stagePosition(self.x, self.y)

  for i=0, 3 do
    love.graphics.setColor(rainbow:color(i):rgb())

    if self.type == Explosion.type.up or self.type == Explosion.type.down then
      love.graphics.rectangle("fill", stageX+i - 4, stageY - 4, 8-i*2, 8)
    end
    if self.type == Explosion.type.right or self.type == Explosion.type.left then
      love.graphics.rectangle("fill", stageX - 4, stageY+i - 4, 8, 8-i*2)
    end
    if self.type == Explosion.type.center then
      love.graphics.rectangle("fill", stageX+i - 4, stageY - 4, 8-i*2, 8)
      love.graphics.rectangle("fill", stageX - 4, stageY+i - 4, 8, 8-i*2)
    end

    if self.type == Explosion.type.upLast then
      love.graphics.rectangle("fill", stageX+i - 4, stageY+4 - 4, 8-i*2, 4)
      love.graphics.circle("fill", stageX, stageY, 4-i)
    end

    if self.type == Explosion.type.downLast then
      love.graphics.rectangle("fill", stageX+i - 4, stageY - 4, 8-i*2, 4)
      love.graphics.circle("fill", stageX, stageY, 4-i)
    end

    if self.type == Explosion.type.rightLast then
      love.graphics.rectangle("fill", stageX - 4, stageY+i - 4, 4, 8-i*2)
      love.graphics.circle("fill", stageX, stageY, 4-i)
    end
    if self.type == Explosion.type.leftLast then
      love.graphics.rectangle("fill", stageX+4 - 4, stageY+i - 4, 4, 8-i*2)
      love.graphics.circle("fill", stageX, stageY, 4-i)
    end
  end
  love.graphics.pop()
end

function Explosion:delete()
  table2.removeItem(self.game.explosions, self)
  if #self.game.explosions == 0 then
    self.game.musicSystem:stopAllPlayer("explosion")
  end
end

return Explosion
