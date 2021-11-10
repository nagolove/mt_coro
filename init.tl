print('hello. I scene from separated thread')

--local tl = require "tl"
require "love"
require "love_inc".require()
require 'pipeline'

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
--local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
--local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
--local graphic_code_channel = love.thread.getChannel("graphic_code_channel")

local mx, my = 0, 0

local time = love.timer.getTime()
local dt = 0.

local pipeline = Pipeline.new()

-- Как часто перекомпилировать код рисовки?
-- Варианты - 
--  * по таймеру
--  * используя метод :peek() на каждой итерации цикла
-- Сейчас функция компилируется один раз при загрузке файла исходного текста
-- потока.

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

    local rendercode = [[
    --local y = graphic_command_channel:demand()
    --local x = graphic_command_channel:demand()
    --local x, y = 100, 100
    local w, h = love.graphics.getDimensions()
    local x, y = math.random() * w, math.random() * h
    love.graphics.setColor{0, 0, 0}
    love.graphics.print("TestTest", x, y)
    --]]
    pipeline:pushCode('text', rendercode)

    rendercode = [[
    local y = graphic_command_channel:demand()
    local x = graphic_command_channel:demand()
    local rad = graphic_command_channel:demand()
    love.graphics.setColor{0, 0, 0}
    love.graphics.circle('fill', x, y, rad)
    --]]
    pipeline:pushCode('circle_under_mouse', rendercode)
end

init()

while true do
    --print('mainloop iter')
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


    if pipeline:ready() then

        -- Как передавать данные?
        --graphic_command_channel:push({ mx, my })
        --graphic_command_channel:push(tostring( math.floor( 1 / dt ) ) )

        -- Связать как-то(bind) следущую пару положенных на стек чисел с
        -- определенной функцией рисования и порядком вызова всех функций
        -- рисования в кадре?
        pipeline:openAndClose('clear')

        pipeline:open('text')
        pipeline:close()

        -- Как избежать случайных лишних заталкиваний данных в канал?
        --pipeline:push(y)
        --pipeline:push(x)

        --[[

        -- Создание и отправка блока данных
        pipeline:open('cursor')
        pipeline:push(y)
        pipeline:push(x)
        pipeline:close()

        -- Отправка только имени функции для рисования
        pipeline:pushName('background')
        --]]

        local x, y = love.mouse.getPosition()
        local rad = 50
        pipeline:open('circle_under_mouse')
        pipeline:push(x)
        pipeline:push(y)
        pipeline:push(rad)
        pipeline:close()

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
