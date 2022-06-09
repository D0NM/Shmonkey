--2017 Copyright Don Miguel mikhail.bratus@gmail.com
--LÖVE Jam https://itch.io/jam/love2d-jam
-- Please use the OLD Love2D version ^_- (2017)

SFX_VOLUME = 0.5
BGM_VOLUME = 0.25

game_state = nil

local image
local image_w, image_h = 520, 490
local fruit = {}
fruit.start_x = 64
fruit.start_y = 24

local monkey = {}
monkey.x, monkey.y = 2, 1 --table pos
monkey.speed = 30 --sprite speed
monkey.sx, monkey.sy = 80, -70 --sprite coords
monkey.screen_x, monkey.screen_y = nil, nil --offset @screen
monkey.width = 32
monkey.height = 32 * 2
monkey.quad = nil
monkey.quad_c = nil
monkey.quad_cb = nil
monkey.quad_l = nil
monkey.quad_r = nil
monkey.move = nil
monkey.sfx_move = "sfx/sfx_movement_ladder5loop.wav"
monkey.sfx_swap = "sfx/sfx_movement_jump10.wav"
monkey.sfx_fail_swap = "sfx/sfx_movement_jump18_landing.wav"
monkey.sfx_dead = "sfx/sfx_sounds_falling1.wav"
monkey.sfx_start_tentacle = "sfx/sfx_deathscream_alien1.wav"
monkey.sfx_start_pull_up = "sfx/sfx_movement_stairs5loop.wav"
--monkey.sx, monkey_y = 80, -70

local tentacle_quad = nil

local MIN_FRUIT_IN_ROW = 3
local FRUIT_DELETE = -1
local FRUIT_STUCK = 4

local score = 0
local hi_score = 0

local time0 = 0
local time1 = 0
local time2 = 0
local TIME_TO_CHECK = 1
local TIME_TO_PULL = 0.45

local font_game_over = love.graphics.newFont("font/kimberley_bl.ttf", 84)
local font_score = love.graphics.newFont("font/arcade_n.ttf", 16)
font_score:setFilter("nearest", "nearest")

local txt_game_over = love.graphics.newText(font_game_over, "GAME OVER")

local fruit_colors = {
    { 255, 20, 40 },
    { 30, 230, 20 },
    { 60, 10, 255 },
    { 55, 20, 40 }
}
fruit_colors[0] = { 255, 10, 255 }

local fruit_size = 32
fruits = {}
tentacles = {}

local o_ten_one = require "o-ten-one"

local function init_fruit()
    fruits = {}
    for i = 1, 15 do
        fruits[i] = {}
    end
    for i = 1, 15, 2 do
        local max_n = love.math.random(5, 12)
        local t = {}
        local f = 0
        for n = 1, max_n do
            if love.math.random(100) < 5 then
                f = FRUIT_STUCK
            else
                f = love.math.random(1, 3)
            end
            if t[n - 1] == f and t[n - 2] == f then
                f = f - 1
                if f < 1 then
                    f = 3
                end
            end
            t[n] = f
        end
        fruits[i] = t
    end
end

local function init_game()
    game_state = 3
    score = 0
    fruit.start_x = 64
    fruit.start_y = 24
    monkey.x, monkey.y = 2, 1 --table pos
    monkey.speed = 30 --sprite speed
    monkey.sx, monkey.sy = 80, -70 --sprite coords
    monkey.screen_x, monkey.screen_y = nil, nil --offset @screen
    tentacles = {
        {}, {}, {}, {}, {}, {}, {}, {},
        {}, {}, {}, {}, {}, {}, {}, {},
        {},
    }
    init_fruit()
end

local function init_game_over()
    game_state = 4
    time0 = 0
    TEsound.play(monkey.sfx_dead, "sfx")
    fruit.move = tween.new(5, fruit, { start_y = 480 + 20 }, 'linear')
end

function love.load(arg)
    love.graphics.setLineStyle("rough")
    love.graphics.setDefaultFilter("nearest", "nearest")
    --	love.graphics.setBackgroundColor(0, 0, 40, 255)
    love.graphics.setBackgroundColor(0, 127, 255)

    love.filesystem.setIdentity("Shmonkey")

    image = love.graphics.newImage("palette.png")
    monkey.quad_c = love.graphics.newQuad(5, 7, 63, 84, image_w, image_h)
    monkey.quad_cb = love.graphics.newQuad(5, 125, 63, 84, image_w, image_h)
    monkey.quad_l = love.graphics.newQuad(83, 7, 63, 84, image_w, image_h)
    monkey.quad_r = love.graphics.newQuad(149, 7, 63, 84, image_w, image_h)
    monkey.quad = monkey.quad_c
    tentacle_quad = love.graphics.newQuad(225, 0, 39, 490, image_w, image_h)

    --Libraries
    class = require "lib/middleclass"
    require "lib/TEsound"
    inspect = require "lib/inspect"
    tween = require "lib/tween"
    tactile = require 'lib/tactile'
    require 'src/controls'

    bind_game_input()

    TEsound.stop("music")
    TEsound.playLooping("music/JUNGLE.S3M", "music")
    TEsound.volume("sfx", SFX_VOLUME)
    TEsound.volume("music", BGM_VOLUME)

    splash = o_ten_one()
    splash.onDone = function() game_state = 3 end

    init_game()
    game_state = 1 --need for the splash
end

local function get_fruit(x, y)
    if x > 0 and x <= #fruits then
        if y >= 1 and y <= #fruits[x] then
            return fruits[x][y] or FRUIT_DELETE
        end
    end
    return FRUIT_DELETE
end

local function tween_monkey_to(sx, sy)
    monkey.move = tween.new(0.12, monkey, { sx = sx, sy = sy }, 'outQuad')
end

local function remove_tween_move()
    monkey.move = nil
end

local function move_monkey(sx, sy)
    if sx ~= 0 and monkey.x + sx >= 0 and monkey.x + sx <= #fruits + 1 and monkey.y == 1 then
        monkey.x = monkey.x + sx
        --        monkey.screen_x = monkey.screen_x + fruit_size * sx
        TEsound.play(monkey.sfx_move, "sfx")
    elseif sx ~= 0 and (get_fruit(monkey.x - 1, monkey.y) > 0 or get_fruit(monkey.x + 1, monkey.y) > 0)
            and (get_fruit(monkey.x + sx - 1, monkey.y) > 0 or get_fruit(monkey.x + sx + 1, monkey.y) > 0) then
        monkey.x = monkey.x + sx
        --        monkey.screen_x = monkey.screen_x + fruit_size * sx
        TEsound.play(monkey.sfx_move, "sfx")
    elseif sy ~= 0 and (get_fruit(monkey.x - 1, monkey.y + sy) > 0 or get_fruit(monkey.x + 1, monkey.y + sy) > 0) then
        monkey.y = monkey.y + sy
        --        monkey.screen_y = monkey.screen_y + fruit_size * sy
        TEsound.play(monkey.sfx_move, "sfx")
    end
    tween_monkey_to(monkey.screen_x + fruit_size * (monkey.x - 1), monkey.screen_y + fruit_size * (monkey.y - 1))
end

local function swap_fruit(x1, y1, x2, y2)
    local f1 = get_fruit(x1, y1)
    local f2 = get_fruit(x2, y2)
    if f1 == FRUIT_STUCK or f2 == FRUIT_STUCK then
        return false
    end
    if f1 > 0 and f2 > 0 then
        fruits[x1][y1], fruits[x2][y2] = fruits[x2][y2], fruits[x1][y1]
        return true
    end
    if ((y1 == 1 or y2 == 1) and x1 > 0 and x1 < #fruits and x2 > 0 and x2 < #fruits) and (f1 > 0 or f2 > 0) then
        if f1 <= 0 then
            f1 = FRUIT_DELETE
        end
        if f2 <= 0 then
            f2 = FRUIT_DELETE
        end
        fruits[x1][y1], fruits[x2][y2] = f2, f1
        return true
    end
    return false
end

--xxx = 0
local function prepare_for_delete_fruit_row(x, y, n)
    --xxx = xxx + 1
    --print(xxx , "At "..x.." from "..y.." to "..(y + n - 1).." #"..#fruits[x])
    for i = y, y + n - 1 do
        fruits[x][i] = FRUIT_DELETE
    end
end

local function pull_fruit_row_up(x)
    for i = 1, #fruits[x] do
        if fruits[x][i] == FRUIT_DELETE then
--            print(time0, "try remove", inspect(fruits[x]), i)
            table.remove(fruits[x], i)
--            print(time0, "->", inspect(fruits[x]))
            TEsound.play(monkey.sfx_start_pull_up, "sfx")
            return
        end
    end
end

local function add_score(n)
    score = score + math.floor(100 * n)
    hi_score = math.max(score, hi_score)
    --TODO sfx
end

local function draw_score()
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor(255, 255, 255)
    love.graphics.setFont(font_score)
    love.graphics.print("SCORE: " .. score .. " HI-SCORE: " .. hi_score, 16, 8)
    love.graphics.setColor(255, 255, 255, 100)
    love.graphics.print("by @d0nm", width - 140, 8)
end

local function draw_help()
    local width, height = love.graphics.getDimensions()
    if time0 > 10 then
        love.graphics.setColor(55, 55, 55, (11 - time0) * 255)
    else
        love.graphics.setColor(55, 55, 55)
    end
    love.graphics.setFont(font_score)
    love.graphics.print("HOLD ON A FRUIT OR YOU'LL FALL\nJUMP WITH ARROWS, SWAP FRUIT WITH X, C", 16, height - 48)
end

local function draw_try_again()
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor(55, 55, 55, 200 + math.sin(time0) * 55)
    love.graphics.setFont(font_score)
    love.graphics.print("PRESS X OR C TO TRY AGAIN\nPRESS ESCAPE TO QUIT", 120, height - 48)
end

local function check_fruit_row(x)
    local cur_f = -2
    local count = 1
    for y = 1, #fruits[x] do
        local f = get_fruit(x, y)
        if f > 0 then
            if f == cur_f then
                count = count + 1
            else
                if count >= MIN_FRUIT_IN_ROW then
                    add_score(count)
                    --replace fruit with FRUIT_DELETE
                    prepare_for_delete_fruit_row(x, y - count, count)
                    return
                end
                count = 1
            end
            cur_f = f
        else
            cur_f = -2
            count = 1
        end
    end
    --the lowest
    if count >= MIN_FRUIT_IN_ROW then
        add_score(count)
        --replace fruit with FRUIT_DELETE
        prepare_for_delete_fruit_row(x, #fruits[x] - count + 1, count)
    end
end

local function check_all_fruit()
    for x = 1, #fruits do
        check_fruit_row(x)
    end
end

local function pull_all_fruit()
    for x = 1, #fruits do
        pull_fruit_row_up(x)
    end
end

local function update_monkey(dt)
    local width, height = love.graphics.getDimensions()
    --	if not monkey.sx or not monkey.screen_x then
    --		return
    --    end
    if monkey.move then
        monkey.move:update(dt)
    end
    if game_state ~= 4 then
        --fall down and die
        if monkey.y ~= 1 and get_fruit(monkey.x - 1, monkey.y) <= 0 and get_fruit(monkey.x + 1, monkey.y) <= 0 then
            monkey.move = tween.new(3, monkey, { sy = height + 20 }, 'inElastic')
            init_game_over()
        end
    end
end

local function draw_monkey()
    if not monkey.sx then
        return
    end
    love.graphics.setColor(255, 255, 255)
    local f1 = get_fruit(monkey.x - 1, monkey.y)
    local f2 = get_fruit(monkey.x + 1, monkey.y)
    if f1 > 0 and f2 > 0 then
        if math.sin(time0) < 0.95 then
            monkey.quad = monkey.quad_c
        else
            monkey.quad = monkey.quad_cb
        end
    elseif f2 > 0 then
        monkey.quad = monkey.quad_r
    else
        monkey.quad = monkey.quad_l
    end
    love.graphics.draw(image, monkey.quad, monkey.sx - 31, monkey.sy - 18)

    --	love.graphics.setColor(255,200,200)
    --	love.graphics.rectangle("fill", monkey.sx - monkey.width / 2, monkey.sy - monkey.width / 2, monkey.width, monkey.height)
--    	love.graphics.setColor(255,255,0)
--    	love.graphics.print("F"..get_fruit(monkey.x - 1, monkey.y).."F"..get_fruit(monkey.x + 1, monkey.y), monkey.sx - 10, monkey.sy + 60)
--    	love.graphics.print("F"..f1.." F"..f2, monkey.sx - 10, monkey.sy + 60)
end

local function draw_fruit(x, y, color)
    if not color then
        --print("wrong fruit color", x, y, color)
        --i love u, my g-code ^_-
        color = FRUIT_DELETE
        fruits[x1][y1] = color
    end
    if color == FRUIT_DELETE then
        love.graphics.setColor(40, 40, 40, 50)
        love.graphics.circle("line", x, y, fruit_size / 3 + math.sin(time0 * 3 + x) )
        return
    end
    if color < 1 or color > #fruit_colors then
        love.graphics.setColor(255, 0, 0)
        love.graphics.circle("line", x, y, fruit_size / 2 - 2)
        love.graphics.print("" .. color, x - 7, y - 8)
        return
    end
    x = x + math.sin(time0 + x + y)
    local c = fruit_colors[color]
    local dc = 0.75
    local c_dark = { c[1] * dc, c[2] * dc, c[3] * dc }
    love.graphics.setColor(unpack(c_dark))
    if color ~= FRUIT_STUCK then
        love.graphics.circle("fill", x, y, fruit_size / 2 - 2)
    else
        love.graphics.circle("fill", x, y, fruit_size / 2 - 4)
    end
    love.graphics.setColor(unpack(c))
    love.graphics.circle("fill", x - 2, y - 2, fruit_size / 2 - 5)
    love.graphics.setColor(255, 255, 255, 90)
    love.graphics.circle("fill", x - fruit_size / 6, y - fruit_size / 6, fruit_size / 8)
    --	love.graphics.setColor(255,255,255)
    --	love.graphics.circle("fill", x, y, 2)
end

local function draw_all_fruit()
    for x = 1, #fruits do
        for y = 1, #fruits[x] do
            draw_fruit(fruit.start_x + x * fruit_size, fruit.start_y + y * fruit_size, fruits[x][y])
            if not monkey.screen_x then
                --monkey star pos
                monkey.screen_x, monkey.screen_y = fruit.start_x + x * fruit_size, fruit.start_y + y * fruit_size
                tween_monkey_to(monkey.screen_x + fruit_size * (monkey.x - 1), monkey.screen_y + fruit_size * (monkey.y - 1))
                TEsound.play(monkey.sfx_move, "sfx")
            end
        end
    end
end

local function draw_bg()
    local height_leaves = 54 - fruit_size / 2
    local width, height = love.graphics.getDimensions()

    for x = 10, 0, -1 do
        love.graphics.setColor(0, 107, 215)
        love.graphics.circle("fill", x * 64 + math.sin(time0 + x * 2.3) * 2, height - 16 - math.sin(time0) * 3, 87 + math.sin(time0 + x) * 9)
    end
    for x = 0, 10 do
        love.graphics.setColor(217, 236, 255)
        love.graphics.circle("fill", 0 + x * 64 + math.sin(time0 + x) * 3, height, 64 + math.sin(time0 + x) * 10)
        love.graphics.setColor(113, 184, 255)
        love.graphics.circle("fill", 0 + x * 64 + math.sin(time0 - x * 1.02) * 2, height, 64 + math.sin(time0 - x * 1.04) * 8)
    end

    love.graphics.setColor(0, 140, 0)
    love.graphics.rectangle("fill", 0, 0, width, height_leaves)
    love.graphics.setColor(0, 102, 26)
    love.graphics.rectangle("fill", 0, height_leaves, width, fruit_size / 3)
    for x = 1, #fruits do
--        if #fruits[x] > 0 then
            love.graphics.setColor(0, 102, 26)
            love.graphics.circle("fill", fruit.start_x + x * fruit_size + math.sin(time0 + x) * 3, height_leaves - fruit_size / 2, fruit_size * 1.32 + math.sin(time0 + x) / 10)
--        end
    end
    for x = 1, #fruits do
        if #fruits[x] > 0 then
            love.graphics.setColor(217, 109, 0)
            love.graphics.rectangle("fill", fruit.start_x + x * fruit_size - 3, height_leaves - fruit_size / 8 + math.sin(time0 + x * 3) * 2, 6, fruit_size * #fruits[x] + fruit_size / 3)
            love.graphics.setColor(255, 166, 77)
            love.graphics.rectangle("fill", fruit.start_x + x * fruit_size - 2, height_leaves - fruit_size / 8 + math.sin(time0 + x * 3) * 2, 2, fruit_size * #fruits[x] - 2 + fruit_size / 3)

            love.graphics.setColor(0, 140, 0)
            love.graphics.circle("fill", fruit.start_x + x * fruit_size + math.sin(time0 + x) * 2, height_leaves - fruit_size, fruit_size * 1.32 + math.sin(time0 + x) / 14)

        end
    end
end

local function draw_tentacles()
    local width, height = love.graphics.getDimensions()
    for i = 1, #tentacles do
        if tentacles[i].move then
            love.graphics.draw(image, tentacle_quad, fruit.start_x + (i - 1) * fruit_size - 20 + math.sin(time0 + i) * 2, tentacles[i].y)
        end
    end
end

local function draw_game_over()
    local screen_width, screen_height = love.graphics.getDimensions()
    love.graphics.setColor(55, 55, 55, 255)
    love.graphics.draw(txt_game_over, (screen_width - txt_game_over:getWidth()) / 2 + 1, (screen_height - txt_game_over:getHeight()) / 2 + 1)
    love.graphics.draw(txt_game_over, (screen_width - txt_game_over:getWidth()) / 2 - 1, (screen_height - txt_game_over:getHeight()) / 2 + 1)
    love.graphics.draw(txt_game_over, (screen_width - txt_game_over:getWidth()) / 2 + 1, (screen_height - txt_game_over:getHeight()) / 2 - 1)
    love.graphics.draw(txt_game_over, (screen_width - txt_game_over:getWidth()) / 2 - 1, (screen_height - txt_game_over:getHeight()) / 2 - 1)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(txt_game_over, (screen_width - txt_game_over:getWidth()) / 2, (screen_height - txt_game_over:getHeight()) / 2)
end

local function update_tentacles(dt)
    local width, height = love.graphics.getDimensions()
    love.graphics.setColor(255, 255, 255)
    for i = 1, #tentacles do
        if not tentacles[i].move then
            --make tentacles more often with time
            if game_state ~= 4 and love.math.random(10000) < time0 + 15 and monkey.x + 1 == i then
                --,ove it up
                tentacles[i].y = height
                tentacles[i].move = tween.new(love.math.random(3, 7), tentacles[i], { y = height - love.math.random(150, 400) }, 'linear')
                --				print("ADD tentacle")
                if game_state ~= 4 then
                    TEsound.play(monkey.sfx_start_tentacle, "sfx")
                end
            elseif game_state == 4 then
                tentacles[i].y = height
                tentacles[i].move = tween.new(love.math.random(1, 1.9), tentacles[i], { y = height - love.math.random(50, 150) }, 'inQuad')
            end
        else
            local complete = tentacles[i].move:update(dt)
            if complete then
                if tentacles[i].y < height then
                    --move it down
                    tentacles[i].move = tween.new(love.math.random(2, 4), tentacles[i], { y = height + 2 }, 'inQuad')
                else
                    --remove
                    tentacles[i].move = nil
                end
            else
                --touch monkey?
                if game_state ~= 4 and monkey.x + 1 == i and tentacles[i].y < (monkey.y + 2) * fruit_size then
                    --move it down
                    tentacles[i].move = tween.new(3, tentacles[i], { y = height + 2 }, 'inQuad')
                    monkey.move = tween.new(3, monkey, { sy = height + 20 }, 'inQuad')
                    init_game_over()
                end
            end
        end
    end
end

function love.update(dt)
    for index, value in pairs(Control1) do
        local b = Control1[index]
        b:update(dt)
    end
    TEsound.cleanup()
    time0 = time0 + dt
    if game_state == 1 then
        splash:update(dt)
    elseif game_state == 2 then
        --title
        game_state = 3
    elseif game_state == 3 then
        if Control1.up:pressed() then
            move_monkey(0, -1)
        elseif Control1.down:pressed() then
            move_monkey(0, 1)
        elseif Control1.left:pressed() then
            move_monkey(-2, 0)
        elseif Control1.right:pressed() then
            move_monkey(2, 0)
        end
        update_monkey(dt)
        update_tentacles(dt)
        if Control1.a:pressed() then
            if swap_fruit(monkey.x - 1, monkey.y + 0, monkey.x + 1, monkey.y + 1) then
                --TODO sfx swap
                TEsound.play(monkey.sfx_swap, "sfx")
                time1 = 0
            else
                --TODO beep
                TEsound.play(monkey.sfx_fail_swap, "sfx")
            end
        elseif Control1.b:pressed() then
            if swap_fruit(monkey.x - 1, monkey.y + 1, monkey.x + 1, monkey.y + 0) then
                --TODO sfx swap
                TEsound.play(monkey.sfx_swap, "sfx")
                time1 = 0
            else
                --TODO beep
                TEsound.play(monkey.sfx_fail_swap, "sfx")
            end
        end
        time1 = time1 + dt
        if time1 > TIME_TO_CHECK then
            time1 = 0
            check_all_fruit()
        end
        time2 = time2 + dt
        if time2 > TIME_TO_PULL then
            time2 = 0
            pull_all_fruit()
        end
        --	self.b.horizontal:getValue() == -self.face ) then
        --	self.b.attack:isDown()
    elseif game_state == 4 then
        --Game Over
        time1 = time1 + dt
        if time1 > TIME_TO_CHECK then
            time1 = 0
            --check_all_fruit()
        end
        time2 = time2 + dt
        if time2 > TIME_TO_PULL then
            time2 = 0
            --pull_all_fruit()
        end
        update_monkey(dt)
        update_tentacles(dt)
        fruit.move:update(dt)

        if time0 > 3 then
            if Control1.a:pressed()
                    or Control1.b:pressed()
                    or Control1.start:pressed() then
                init_game()
            end
        end
    end

    if Control1.back:pressed() then
        love.event.quit()
    end
end

function love.draw()
    local width, height = love.graphics.getDimensions()
    if game_state == 1 then
        splash:draw()
    elseif game_state == 2 then
        --title
    elseif game_state == 3 then
        draw_bg()
        draw_all_fruit()
        draw_monkey()
        draw_tentacles()
        draw_score()
        if time0 < 11 then
            draw_help()
        end
    elseif game_state == 4 then
        --GAME OVER
        draw_bg()
        draw_all_fruit()
        draw_monkey()
        draw_tentacles()
        draw_score()
        draw_game_over()
        if time0 > 5 then
            draw_try_again()
        end
    end
end

function love.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
end

function love.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
end

function love.wheelmoved(dx, dy)
end