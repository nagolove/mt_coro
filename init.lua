local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; print('hello. I scene from separated thread')


require("love")
require("love_inc").require()
require('pipeline')



love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/mt_coro/?.lua")
local i18n = require("i18n")
















local event_channel = love.thread.getChannel("event_channel")




local mx, my = 0, 0

local last_render

local pipeline = Pipeline.new('scenes/mt_coro')








local function init()
   i18n.set('en.welcome', 'welcome to this program')
   i18n.load({
      en = {
         good_bye = "good-bye!",
         age_msg = "your age is %{age}.",
         phone_msg = {
            one = "you have one new message.",
            other = "you have %{count} new messages.",
         },
      },
   })
   print("translated", i18n.translate('welcome'))
   print("translated", i18n('welcome'))

   local rendercode = [[
    while true do
        local w, h = love.graphics.getDimensions()
        local x, y = math.random() * w, math.random() * h
        love.graphics.setColor{0, 0, 0}
        love.graphics.print("TestTest", x, y)
        coroutine.yield()
    end
    ]]
   pipeline:pushCode('text', rendercode)

   rendercode = [[
    while true do
        local y = graphic_command_channel:demand()
        local x = graphic_command_channel:demand()
        local rad = graphic_command_channel:demand()
        love.graphics.setColor{0, 0, 1}
        love.graphics.circle('fill', x, y, rad)
        coroutine.yield()
    end
    ]]
   pipeline:pushCode('circle_under_mouse', rendercode)



   pipeline:pushCode('clear', [[
    repeat
        love.graphics.clear{0.5, 0.5, 0.5}
        coroutine.yield()
    until false
    ]])

   pipeline:pushCode('tank_sprite', [[
        local img = love.graphics.newImage(SCENE_PREFIX .. '/korpus1.png')
        local color = {1, 1, 1, 1}
        while true do
            local x = graphic_command_channel:demand()
            local y = graphic_command_channel:demand()
            love.graphics.setColor(color)
            love.graphics.draw(img, x, y)
            coroutine.yield()
        end
    ]])














   last_render = love.timer.getTime()
end

local tank_x, tank_y = 0., 0.

local function render()
   if pipeline:ready() then

      pipeline:openAndClose('clear')

      pipeline:open('text')
      pipeline:close()

      local x, y = love.mouse.getPosition()
      local rad = 50
      pipeline:open('circle_under_mouse')
      pipeline:push(y)
      pipeline:push(x)
      pipeline:push(rad)
      pipeline:close()

      pipeline:open('tank_sprite')
      pipeline:push(tank_x)
      pipeline:push(tank_y)
      pipeline:close()
   end
end

local isDown = love.keyboard.isDown

local function mainloop()
   while true do

      local events = event_channel:pop()
      if events then
         for _, e in ipairs(events) do
            local evtype = (e)[1]
            if evtype == "mousemoved" then
               mx = math.floor((e)[2])
               my = math.floor((e)[3])
            elseif evtype == "keypressed" then

               local scancode = (e)[3]
               if scancode == "escape" then
                  love.event.quit()
               end
            elseif evtype == "mousepressed" then





            end
         end
      end

      local d = 1
      if isDown('left') then
         tank_x = tank_x - d
      end
      if isDown('right') then
         tank_x = tank_x + d
      end
      if isDown('up') then
         tank_y = tank_y - d
      end
      if isDown('down') then
         tank_y = tank_y + d
      end

      local nt = love.timer.getTime()

      local pause = 1. / 300.
      if nt - last_render >= pause then
         last_render = nt


         render()
      end









      love.timer.sleep(0.0001)
   end
end

init()
mainloop()

print('goodbye. I scene from separated thread')
