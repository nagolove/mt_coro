local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local math = _tl_compat and _tl_compat.math or math; print('hello. I scene from separated thread')


require("love")
require("love_inc").require()

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/empty/?.lua")
local i18n = require("i18n")
















local event_channel = love.thread.getChannel("event_channel")
local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local accum = 0

local mx, my = 0, 0

local time = love.timer.getTime()
local dt = 0.

local rendercode = [[
--local mpos = graphic_command_channel:demand()
--local ups = graphic_command_channel:demand()

gr.clear(0.5, 0.5, 0.5)
gr.setColor{0, 0, 0}
gr.print("TestTest")
]]

graphic_code_channel:push(rendercode)

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
   graphic_command_channel:push(rendercode)
end

init()

while true do
   local events = event_channel:pop()
   if events then
      for _, e in ipairs(events) do
         local evtype = (e)[1]
         if evtype == "mousemoved" then
            mx = math.floor((e)[2])
            my = math.floor((e)[3])
         elseif evtype == "keypressed" then
            local key = (e)[2]
            local scancode = (e)[3]
            print('keypressed', key, scancode)
            if scancode == "escape" then
               love.event.quit()
            end
         elseif evtype == "mousepressed" then





         end
      end
   end

   local nt = love.timer.getTime()
   dt = nt - time
   time = nt


   if draw_ready_channel:peek() then
      print('thread drawing')




      local res = draw_ready_channel:pop()
      if res ~= "ready" then
         error("Bad message in draw_ready_channel: " .. res)
      end
   end


   love.timer.sleep(0.001)
end









print('goodbye. I scene from separated thread')
