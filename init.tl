print('hello. I scene from separated thread')

--local tl = require "tl"
require "love"
require "love_inc".require()
require 'pipeline'

--require "love.timer"

love.filesystem.setRequirePath("?.lua;?/init.lua;scenes/mt_coro/?.lua")
local i18n = require "i18n"
--local colorize = require 'ansicolors2'.ansicolors
--local format = string.format

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

local last_render: number

local pipeline = Pipeline.new('scenes/mt_coro')

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

    -- Допустимо-ли переопределение функций? Или добавить специальный флаг?
    -- Нормально-ли использовать константы?
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

    --[[
    -- Добавлять-ли такую функцию? Будет использоваться?
    -- Стоимость реализации и возможности применения.
    pipeline:pushCodes({
        { 
            'text',
            'code',
        },
        {},
        {},
    })
    --]]

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
        --print('mainloop iter')
        local events = event_channel:pop() as {any}
        if events then
            for _, e in ipairs(events) do
                local evtype: string = (e as {string})[1]
                if evtype == "mousemoved" then
                    mx = math.floor((e as {number})[2])
                    my = math.floor((e as {number})[3])
                elseif evtype == "keypressed" then
                    --local key = (e as {string})[2]
                    local scancode = (e as {string})[3]
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
        --local pause = 1. / 10.
        local pause = 1. / 300.
        if nt - last_render >= pause then
            last_render = nt
            --local msg = 'love.timer.getTime() = %f'
            --print(colorize('%{blue}' .. format(msg, love.timer.getTime())))
            render()
        end
        --]]

        --render()

        --[[
        Ограничение кадров в секунду до 60
        --]]

        --love.timer.sleep(0.0008)
        love.timer.sleep(0.0001)
    end
end

init()
mainloop()

print('goodbye. I scene from separated thread')
