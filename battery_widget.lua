local awful = require("awful")
local HOME = os.getenv("HOME")
local IMAGES_DIR = HOME .. "/.config/awesome/battery_widget/assets/"
local wibox = require("wibox")
local dbus = dbus
local widget = {}
local battery_image = {}
local text = {}

local function worker(args)
    local args = args or {}
    local show_percentage = false or args.show_percentage

    battery_image = wibox.widget {
        forced_width = 18,
        forced_height = 25,
        halign = "center",
        valign = "center",
        widget = wibox.widget.imagebox
    }

    if show_percentage then
        text = wibox.widget {widget = wibox.widget.textbox}
    else
        text = wibox.widget {}
    end

    widget = wibox.widget {
        wibox.widget {
            text,
            battery_image,
            layout = wibox.layout.align.horizontal
        },
        margins = 2.5,
        widget = wibox.container.margin

    }

    function battery_image:setImagePercentage(number)
        local percent = tonumber(number)
        if percent == nil then
            battery_image:setPercentage()
            return 0
        end
        if percent ~= -1 then
            text.text = percent .. "% "
        else
            awful.spawn.easy_async_with_shell(
                "cat /sys/class/power_supply/BAT0/capacity",
                function(out)
                    text.text = out:gsub("\n", "") .. "% "
                end)
        end
        if percent == 100 then
            battery_image.image = IMAGES_DIR .. "full.png"
        elseif percent < 100 and percent >= 90 then
            battery_image.image = IMAGES_DIR .. "99.png"
        elseif percent < 90 and percent >= 80 then
            battery_image.image = IMAGES_DIR .. "90.png"
        elseif percent < 80 and percent >= 70 then
            battery_image.image = IMAGES_DIR .. "80.png"
        elseif percent < 70 and percent >= 60 then
            battery_image.image = IMAGES_DIR .. "70.png"
        elseif percent < 60 and percent >= 50 then
            battery_image.image = IMAGES_DIR .. "60.png"
        elseif percent < 50 and percent >= 40 then
            battery_image.image = IMAGES_DIR .. "50.png"
        elseif percent < 40 and percent >= 30 then
            battery_image.image = IMAGES_DIR .. "40.png"
        elseif percent < 30 and percent >= 20 then
            battery_image.image = IMAGES_DIR .. "30.png"
        elseif percent < 20 and percent >= 10 then
            battery_image.image = IMAGES_DIR .. "20.png"
        elseif percent < 10 and percent >= 0 then
            battery_image.image = IMAGES_DIR .. "10.png"
        elseif percent == 0 then
            battery_image.image = IMAGES_DIR .. "0.png"
        elseif percent == -1 then
            battery_image.image = IMAGES_DIR .. "charging.png"
        end
    end

    function battery_image:setPercentage()
        awful.spawn.easy_async_with_shell(
            "cat /sys/class/power_supply/BAT0/status", function(status)
                if status:find("Charging") then
                    battery_image:setImagePercentage(-1);
                else
                    awful.spawn.easy_async_with_shell(
                        "cat /sys/class/power_supply/BAT0/capacity",
                        function(out)
                            battery_image:setImagePercentage(out)
                        end)
                end
            end)
    end

    battery_image:setPercentage()

    dbus.add_match("system", [[interface='org.freedesktop.DBus.Properties',
    member='PropertiesChanged',
    path='/org/freedesktop/UPower/devices/DisplayDevice']])

    dbus.connect_signal("org.freedesktop.DBus.Properties",
                        function(dbus, interface, data)

        print(type(data.TimeToEmpty))
        for key, value in pairs(data) do print(key, value) end
        if data.TimeToEmpty ~= 0 and data.TimeToEmpty ~= nil then
            if interface == "org.freedesktop.UPower.Device" and data.Percentage ~=
                nil then
                local percentage, index = string.gsub(data.Percentage, ".0", "")
                print(percentage)
                battery_image:setImagePercentage(percentage)
            else
                battery_image:setPercentage()
            end
        elseif data.TimeToFull ~= 0 then
            battery_image:setImagePercentage(-1)
        end
    end)

    return widget
end

return setmetatable(widget, {__call = function(_, ...) return worker(...) end})
