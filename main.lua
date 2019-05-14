package.path = package.path .. ';' .. love.filesystem.getSource() .. '/lua_modules/share/lua/5.1/?.lua'
--require "monolith.module_manager".addPath "libs"

local monolith = require("monolith.core").new({ledColorBits=2})
local shutdownkey = require("util.shutdownkey"):new(monolith.input)

local musicSystem
local gameScene

function love.load(arg)
  love.filesystem.setIdentity("__global__")
  local s = require "util.storage":load("test")
  print(s.data[1], s.data[2])
  local arguments = require "util.parse_arguments" (arg)

    if require "util.osname" == "Linux" then
      for i,inp in ipairs(require "config.linux_input_settings") do monolith.input:setUserSetting(i, inp) end
    else
      for i,inp in ipairs(require "config.input_settings") do monolith.input:setUserSetting(i, inp) end
    end

  love.graphics.setDefaultFilter('nearest', 'nearest', 1)
  love.graphics.setLineStyle('rough')

  local devices, musicPathTable, priorityTable = unpack(require "config.music_data")
  musicSystem = require("music.music_system"):new(arguments.activeControllers, devices, musicPathTable, priorityTable)

  gameScene = require("game.gameScene"):new(17, 17, monolith, musicSystem, arguments.activeControllers)
  gameScene:reset()
end


function love.update(dt)
  shutdownkey:update(dt)

  gameScene:update(dt)
  if love.keyboard.isDown("0") then gameScene:reset() end
end


function love.draw()
  monolith:beginDraw()

  gameScene:draw()

  monolith:endDraw()

  local str = string.format("fps: %.1f", love.timer.getFPS())
  love.graphics.print(str)
end


function love.quit()
  musicSystem:gc()
  require "util.open_launcher"()
end
