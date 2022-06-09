local function dp() end
function love.joystickadded(joystick)
    p1joystick = joystick
    dp(joystick:getGUID().." added joystick "..joystick:getName().." with "..joystick:getButtonCount().." buttons")
    if p1joystick then
        p2joystick = joystick
    elseif p2joystick then
        p3joystick = joystick
    end

    love.joystick.loadGamepadMappings( "res/gamecontrollerdb.txt" )
    local joysticks = love.joystick.getJoysticks()
    for i, joystick in ipairs(joysticks) do
        dp("detected ",joystick:getName())
    end
end

function love.joystickremoved( joystick )
    dp("removed joystick "..joystick:getName())
end

DUMMY_CONTROL = {}
DUMMY_CONTROL.horizontal = {
    getValue = function() return 0 end,
    isDown = function() return false end,
    pressed = function() return false end,
    released = function() return false end,
    update = function() return false end,
    ikp = {getLast = function() return false end},
    ikn = {getLast = function() return false end}
}
DUMMY_CONTROL.vertical = {
    getValue = function() return 0 end,
    isDown = function() return false end,
    pressed = function() return false end,
    released = function() return false end,
    update = function() return false end,
    ikp = {getLast = function() return false end},
    ikn = {getLast = function() return false end}
}
DUMMY_CONTROL.attack = {
    getValue = function() return 0 end,
    isDown = function() return false end,
    pressed = function() return false end,
    released = function() return false end,
    update = function() return false end
}
DUMMY_CONTROL.jump = {
    getValue = function() return 0 end,
    isDown = function() return false end,
    pressed = function() return false end,
    released = function() return false end,
    update = function() return false end
}

local function gamepadHat(num, hat, axis)
    local joystick = love.joystick.getJoysticks()[num]
    if not joystick then
        return function()
            return 0
        end
    end
    if axis == "horizontal" then
        return function()
            local joystick = love.joystick.getJoysticks()[num]
            local h = joystick:getHat(hat)
            if h == "l" or h == "lu" or h == "ld" then
                return -1
            elseif h == "r" or h == "ru" or h == "rd" then
                return 1
            end
            return 0
        end
    else
        return function()
            local joystick = love.joystick.getJoysticks()[num]
            local h = joystick:getHat(hat)
            if h == "u" or h == "ru" or h == "lu" then
                return -1
            elseif h == "d" or h == "rd" or h == "ld" then
                return 1
            end
            return 0
        end
    end
end

function bind_game_input()
    -- define Player 1 controls
    local gamepad1 = 2
    local gamepad2 = 1
    local gamepad3 = 3
    Control1 = {
        up = tactile.newControl()
        :addButton(tactile.keys('up')),
        down = tactile.newControl()
        :addButton(tactile.keys('down')),
        left = tactile.newControl()
        :addButton(tactile.keys('left')),
        right = tactile.newControl()
        :addButton(tactile.keys('right')),
--
        horizontal = tactile.newControl()
        :addAxis(tactile.gamepadAxis(gamepad1, 'leftx'))
        :addAxis(gamepadHat(gamepad1, 1, "horizontal"))
        --:addAxis(tactile.gamepadAxis(1, 'rightx'))
        :addButtonPair(tactile.keys('left'), tactile.keys('right')),
        vertical = tactile.newControl()
        :addAxis(tactile.gamepadAxis(gamepad1, 'lefty'))
        :addAxis(gamepadHat(gamepad1, 1, "vertical"))
        --:addAxis(tactile.gamepadAxis(1, 'righty'))
        :addButtonPair(tactile.keys('up'), tactile.keys('down')),

        a = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad1, 'a'))
        :addButton(tactile.keys('x')),
        b = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad1, 'b'))
        :addButton(tactile.keys('c')),
        --TODO test
        start = tactile.newControl()
        :addButton(tactile.keys('return'))
        :addButton(tactile.gamepadButtons(gamepad1, 'start')),
        back = tactile.newControl()
        :addButton(tactile.keys('escape'))
        :addButton(tactile.gamepadButtons(gamepad1, 'back')),
        fullScreen = tactile.newControl()
        :addButton(tactile.keys('f11')),
        screenshot = tactile.newControl()
        :addButton(tactile.keys('p'))
    }
    -- define Player 2 controls
    Control2 = {
        horizontal = tactile.newControl()
        :addAxis(tactile.gamepadAxis(gamepad2, 'leftx'))
        :addAxis(gamepadHat(gamepad2, 1, "horizontal"))
        :addButtonPair(tactile.keys('a'), tactile.keys('d')),
        vertical = tactile.newControl()
        :addAxis(tactile.gamepadAxis(gamepad2, 'lefty'))
        :addAxis(gamepadHat(gamepad2, 1, "vertical"))
        :addButtonPair(tactile.keys('w'), tactile.keys('s')),
        attack = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad2, 'a'))
        :addButton(tactile.keys 'i'),
        jump = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad2, 'b'))
        :addButton(tactile.keys 'o'),
        start = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad2, 'start')),
        back = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad2, 'back'))
    }
    -- define Player 3 controls
    Control3 = {
        horizontal = tactile.newControl()
        :addAxis(tactile.gamepadAxis(gamepad3, 'leftx'))
        :addAxis(gamepadHat(gamepad3, 1, "horizontal"))
        :addButtonPair(tactile.keys('f'), tactile.keys('h')),
        vertical = tactile.newControl()
        :addAxis(tactile.gamepadAxis(gamepad3, 'lefty'))
        :addAxis(gamepadHat(gamepad3, 1, "vertical"))
        :addButtonPair(tactile.keys('t'), tactile.keys('g')),
        attack = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad3, 'a'))
        :addButton(tactile.keys 'r'),
        jump = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad3, 'b'))
        :addButton(tactile.keys 'y'),
        start = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad3, 'start')),
        back = tactile.newControl()
        :addButton(tactile.gamepadButtons(gamepad3, 'back'))
    }

    local double_press_delta = 0.25
    --add keyTrace into every player 1 button
end
