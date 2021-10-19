print('hello. I scene from separated thread')

--local tl = require "tl"
require "love"
require "love_inc".require()

--require "love.timer"

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/empty/?.lua")
local i18n = require "i18n"

--require "external"
--require "common"

--package.path = package.path .. ";scenes/automato/?.lua"

--local cam = require "camera".new()
--local gr = love.graphics
--local imgui = require "imgui"
--local inspect = require "inspect"
--local keyconfig = require "keyconfig"
--local next = next
--local timer = require "Timer"

local event_channel = love.thread.getChannel("event_channel")
local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local mx, my = 0, 0

local time = love.timer.getTime()
local dt = 0.

local rendercode = [[
local s: integer = 1
local y = graphic_command_channel:demand()
local x = graphic_command_channel:demand()

local gr = love.graphics
gr.clear(0.5, 0.5, 0.5)
gr.setColor{0, 0, 0}
gr.print("TestTest", x, y)
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
                other = "you have %{count} new messages."
            }
        }
    })
    print("translated", i18n.translate('welcome'))
    print("translated", i18n('welcome'))
    graphic_code_channel:push(rendercode)
end

init()

while true do
    local events = event_channel:pop() as {any}
    if events then
        for _, e in ipairs(events) do
            local evtype: string = (e as {string})[1]
            if evtype == "mousemoved" then
                mx = math.floor((e as {number})[2])
                my = math.floor((e as {number})[3])
            elseif evtype == "keypressed" then
                local key = (e as {string})[2]
                local scancode = (e as {string})[3]
                print('keypressed', key, scancode)
                if scancode == "escape" then
                    love.event.quit()
                end
            elseif evtype == "mousepressed" then
                --local x: number = (e as {number})[2]
                --local y: number = (e as {number})[3]
                --local button: number = (e as {number})[4]
                --local istouch: boolean = (e as {boolean})[5]
                --local presses: number = (e as {number})[6]
            end
        end
    end
    
    local nt = love.timer.getTime()
    dt = nt - time
    time = nt

    if draw_ready_channel:peek() then
        -- Как передавать данные?
        --graphic_command_channel:push({ mx, my })
        --graphic_command_channel:push(tostring( math.floor( 1 / dt ) ) )

        local x, y = love.mouse.getPosition()
        graphic_command_channel:push(y)
        graphic_command_channel:push(x)

        local res = draw_ready_channel:pop() as string
        if res ~= "ready" then
            error("Bad message in draw_ready_channel: " .. res)
        end
    end

    love.timer.sleep(0.001)
end

--[[
local function keypressed(key: string)
    if key == "escape" then
        love.event.quit()
    end
end
--]]

print('goodbye. I scene from separated thread')
