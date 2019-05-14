local math2 = require "util.math2"
local table2 = require "util.table2"

local Timer = require "util.timer"
local color = require "graphics.color"
local anim8 = require 'anim8'

local Bomb = require "game.bomb"
local Item = require "game.item"

local font = love.graphics.newFont("assets/font/Chack'n-Pop.ttf", 8)

local calcDirection = require "util.calc_direction"
local rainbowBase = require "graphics.rainbow":new(1/30, {color.black, color.black, color.black, color.blue, color.cyan, color.red})
local rainbow = require "graphics.rainbow":new(1/30, {color.white, color.magenta, color.white, color.green, color.white, color.yerrow})

local function loadAndChangeColor(imageNames, from, to)

  local function pixelFunction(x, y, r, g, b, a)
    if r == from.r and g == from.g and b == from.g then return to.r, to.g, to.b, a end
    return r, g, b, a
  end

  local changedImages = {}
  for k, v in pairs(imageNames) do
    local imageData = love.image.newImageData(v)
    if from ~= nil then
      imageData:mapPixel(pixelFunction)
    end
    changedImages[k] = love.graphics.newImage(imageData)
  end
  return changedImages
end

local imageNames = {}
imageNames.wait = "assets/images/playerWait2.png"
imageNames.walk = "assets/images/playerWalk.png"
imageNames.setBomb = "assets/images/playerSet.png"

local images = {}
images[1] = loadAndChangeColor(imageNames)
images[2] = loadAndChangeColor(imageNames, color.red, color.magenta)
images[3] = loadAndChangeColor(imageNames, color.red, color.blue)
images[4] = loadAndChangeColor(imageNames, color.red, color.cyan)

local grids = {}
grids.wait = anim8.newGrid(8, 8, images[1].wait:getWidth(), images[1].wait:getHeight())
grids.walk = anim8.newGrid(8, 8, images[1].walk:getWidth(), images[1].walk:getHeight())
grids.setBomb = anim8.newGrid(8, 8, images[1].setBomb:getWidth(), images[1].setBomb:getHeight())

local function move(self, dt)
  if self.moveTimer:isLimit() then
    local movX, movY
    if self.getButton("up") then
      movX, movY = 0, - 1
    elseif self.getButton("down") then
      movX, movY = 0, 1
    elseif self.getButton("left") then
      self.anim.walk.flippedH = true
      movX, movY = -1, 0
    elseif self.getButton("right") then
      self.anim.walk.flippedH = false
      movX, movY = 1, 0
    end

    if movX ~= nil then
      local hit = self.game:hitTest(self.x + movX, self.y + movY)
      if not hit then
        self.movX = movX
        self.movY = movY
        self.moveTimer:reset()

        if not self.soundNowPlaying("walk") then self.soundPlay("walk") end
        return true
      end
    else
      --waiting
      if not self.isSettingBomb then
        if self.nowAnim ~= self.anim.wait then
          self.nowAnim = self.anim.wait
          self.nowAnim:gotoFrame(1)
          self.nowImage = images[self.index].wait
        end
      end
      return false
    end
  elseif self.moveTimer:executable(dt) then
    --walking
    self.x = self.x + self.movX / self.moveTimer.limit
    self.y = self.y + self.movY / self.moveTimer.limit

    if self.moveTimer:isLimit() then
      self.x = math2.round(self.x)
      self.y = math2.round(self.y)

      if not move(self, dt) then
        self.soundStop("walk")
      end
    end

    if not self.isSettingBomb then
      self.nowAnim = self.anim.walk
      self.nowImage = images[self.index].walk
    end

    local rx, ry = self:roundPosition()
    for _, v in ipairs(self.game.items) do
      if v.x == rx and v.y == ry then
        if v.type == Item.type.power then
          self.bombPower = self.bombPower + 1
        end
        if v.type == Item.type.plus then
          self.bombLimit = self.bombLimit + 1
        end
        v:delete()

        self.soundPlay("item")
      end
    end
  end
end

local function bomb(self, dt)
  -- clear end bomb
  for i = #self.usingBombs, 1, - 1 do
    local bomb = self.usingBombs[i]
    if bomb.isBombed then
      table.remove(self.usingBombs, i)
    end
  end

  if self.isSettingBomb then return end

  if self.getButtonDown("a") or self.getButtonDown("b") then
    self.isSettingBomb = true

    self.nowAnim = self.anim.setBomb
    self.nowAnim:gotoFrame(1)
    self.nowAnim.onLoop = function()
      self.isSettingBomb = false
      self.nowAnim.onLoop = function() end

      local roundX, roundY = self:roundPosition()
      local hit = self.game:getBomb(roundX, roundY)

      if self.bombLimit ~= #self.usingBombs and not hit then
        local bomb = Bomb:new(roundX, roundY, self.bombPower, self.game)
        table.insert(self.usingBombs, bomb)
        self.soundPlay("put")
      end
    end
    self.nowImage = images[self.index].setBomb

  end
end


local function soundPlay (index, game)
  return function (key)
    game.musicSystem:play(index, key)
  end
end
local function soundStop (index, game)
  return function (key)
    game.musicSystem:stop(index, key)
  end
end
local function soundNowPlaying (index, game)
  return function (key)
    return game.musicSystem:nowPlaying(index, key)
  end
end


local function getButton (index, game)
  return function (key)
    return game.monolith.input:getButton(index, calcDirection(index, key))
  end
end
local function getButtonDown (index, game)
  return function (key)
    return game.monolith.input:getButtonDown(index, calcDirection(index, key))
  end
end


local Player = {}
function Player:new(index, x, y, game)
  local timer = Timer:new(0.03, 8)
  timer.count = timer.limit

  local t = {
    index = index,
    isSettingBomb = false,
    x = x, y = y,
    bombLimit = 1, bombPower = 1, usingBombs = {},
    game = game,
    moveTimer = timer,
    sound = nil,
    isWin = false,
    anim = {
      wait = anim8.newAnimation(grids.wait("1-8", 1, "1-8", 2, "1-8", 3, 1, 4), 0.1),
      walk = anim8.newAnimation(grids.walk("1-4", 1), 0.05),
      setBomb = anim8.newAnimation(grids.setBomb("1-5", 1), 0.03)
    }
  }

  t.nowAnim = t.anim.wait
  t.nowImage = images[index].wait

  t.soundPlay = soundPlay(index, game)
  t.soundStop = soundStop(index, game)
  t.soundNowPlaying = soundNowPlaying(index, game)

  t.getButton = getButton(index, game)
  t.getButtonDown = getButtonDown(index, game)

  table.insert(game.players, t)
  return setmetatable(t, {__index = self})
end

function Player:update(dt)
  self.nowAnim:update(dt)

  move(self, dt)
  bomb(self, dt)
end

function Player:win()
  self.isWin = true
end

local function draw(anim, img, x, y, dir)
  --local directions = {"up", "down", "left", "right"}
  local rotations = {0, math.pi, math.pi / 2 * 3, math.pi / 2}
  local xs = {-4, 4, -4, 4}
  local ys = {-4, 4, 4, -4}

  anim:draw(img, x + xs[dir], y + ys[dir], rotations[dir])
end

local function drawWin(x, y, dir)
  local txt = "I WON"
  local fontSize = 8
  local xd = -#txt * fontSize / 2

  local yd = math2.round(-fontSize * 2.3 + math.sin(love.timer.getTime()*6)*2)

  local rotations = {0, math.pi, math.pi / 2 * 3, math.pi / 2}
  local xs = {xd, -xd, yd, -yd}
  local ys = {yd, -yd, -xd, xd}

  local d = 2
  local rxs = {xd - d, xd - d,            yd - d, -yd-fontSize - d}
  local rys = {yd - d, -yd-fontSize - d,  xd - d, xd - d}
  local rws = {fontSize*#txt + d * 2, fontSize*#txt + d * 2, fontSize + d * 2, fontSize + d * 2}
  local rhs = {fontSize + d * 2, fontSize + d * 2, fontSize*#txt + d * 2, fontSize*#txt + d * 2}

  love.graphics.push()

  love.graphics.setColor(rainbowBase:color():rgb())
  love.graphics.rectangle("fill", x + rxs[dir], y + rys[dir], rws[dir], rhs[dir])
  love.graphics.setColor(rainbow:color():rgb())
  love.graphics.rectangle("line", x + rxs[dir]-1, y + rys[dir], rws[dir]+2, rhs[dir])
  love.graphics.rectangle("line", x + rxs[dir], y + rys[dir] - 1, rws[dir], rhs[dir]+2)
  love.graphics.rectangle("line", x + rxs[dir], y + rys[dir], rws[dir], rhs[dir])

  love.graphics.setFont(font)
  love.graphics.print(txt, x + xs[dir], y + ys[dir], rotations[dir])

  love.graphics.pop()
end


function Player:draw()
  love.graphics.push()

  love.graphics.setColor(1, 1, 1, 1)
  local stageX, stageY = self.game:stagePosition(self.x, self.y)
  draw(self.nowAnim, self.nowImage, stageX, stageY, self.index)
  if self.isWin then
    drawWin(stageX, stageY, self.index)
  end
  love.graphics.pop()
end

function Player:roundPosition()
  return math2.round(self.x), math2.round(self.y)
end

function Player:delete()
  self.soundStop("walk")
  table2.removeItem(self.game.players, self)
end

return Player
