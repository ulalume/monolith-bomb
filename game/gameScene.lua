local Block = require "game.block"
local Player = require "game.player"

local table2 = require "util.table2"
local Timer = require "util.timer"

local gameScene = {}


function gameScene:new(w, h, monolith, musicSystem, activeControllers)

  return setmetatable({
    w=w,h=h,
    bombs={},
    blocks={},
    items={},
    explosions={},
    musicSystem=musicSystem,
    monolith=monolith,

    gameIsEnding= false,
    gameEndTimer=Timer:new(4, 1),

    activeControllers=activeControllers,
    players={}}, {__index=self})
end


function gameScene:getBlock(x, y)
  for _,v in ipairs(self.blocks) do
    if v.x == x and v.y == y then
      return v
    end
  end
end

function gameScene:getBomb(x, y)
  for _,v in ipairs(self.bombs) do
    if v.x == x and v.y == y then
      return v
    end
  end
end

function gameScene:hitTest(x, y)
  for _,v in ipairs(self.blocks) do
    if v.x == x and v.y == y then
      return true
    end
  end
  for _,v in ipairs(self.bombs) do
    if v.x == x and v.y == y then
      return true
    end
  end
  for _,v in ipairs(self.players) do
    local vx, vy = v:roundPosition()
    if vx == x and vy == y then
      return true
    end
  end
  return false
end

function gameScene:reset()
  self.bombs={}
  self.blocks={}
  self.items={}
  self.explosions={}
  self.players={}

  Block.initAtrandom(self.w, self.h, self)

  local x = {1 + 8, 1 + 8, 17 - 1, 1 + 1}
  local y = {17 - 1, 1 + 1, 1 + 8, 1 + 8}
  for i, b in ipairs(self.activeControllers) do
    if b then
      Player:new(i, x[i], y[i], self)
    end
  end
end

function gameScene:update(dt)
  local updatable = table2.merge({}, self.musicSystem.players, self.players, self.bombs, self.explosions, self.blocks)
  for _,v in ipairs(updatable) do
    v:update(dt)
  end

  if self.gameIsEnding then
    if self.gameEndTimer:executable(dt) then
      love.event.quit()
    end
  else
    if #self.players == 0 then
      for _,player in ipairs(self.players) do
        self.gameIsEnding = true
      end
    end
    if #self.players == 1 then
      self.players[1]:win()
      self.gameIsEnding = true
    end
  end
end

function gameScene:stagePosition(x, y)
  return (x - 1) * 8, (y - 1) * 8
end

function gameScene:draw()
  local drawable = table2.merge({}, self.blocks, self.players, self.bombs, self.explosions, self.items)
  for _,v in ipairs(drawable) do
    v:draw()
  end
end


return gameScene
