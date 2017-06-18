local cairo = require("lgi").cairo
local mouse = mouse
local screen = screen
local wibox = require('wibox')
local table = table
local keygrabber = keygrabber
local math = require('math')
local awful = require('awful')
local gears = require("gears")
local timer = gears.timer
local client = client
awful.client = require('awful.client')

local naughty = require("naughty")
local string = string
local tostring = tostring
local tonumber = tonumber
local debug = debug
local pairs = pairs
local unpack = unpack

module("awesome-switcher-preview")

local surface = cairo.ImageSurface(cairo.Format.RGB24,20,20)
local cr = cairo.Context(surface)

-- settings

local settings = {
   preview_box = true,
   preview_box_bg = "#ddddddaa",
   preview_box_border = "#22222200",
   preview_box_fps = 30,
   preview_box_delay = 150,
   preview_box_title_font = {"sans","italic","normal"},
   preview_box_title_font_size_factor = 0.8,
   preview_box_title_color = {0,0,0,1},

   client_opacity = false,
   client_opacity_value = 0.5,
   client_opacity_delay = 150,

   cycle_raise_client = true,
}

-- Create a wibox to contain all the client-widgets
local preview_wbox = wibox({ width = screen[mouse.screen].geometry.width })
preview_wbox.border_width = 3
preview_wbox.ontop = true
preview_wbox.visible = false

local preview_live_timer = timer({ timeout = 1/settings.preview_box_fps })
local preview_widgets = {}

local altTabTable = {}
local altTabIndex = 1
local applyOpacity = false

local source = string.sub(debug.getinfo(1,'S').source, 2)
local path = string.sub(source, 1, string.find(source, "/[^/]*$"))
local noicon = path .. "noicon.png"

local function cairo_rounded_rectangle(cr, x, y, width, height)
   -- draw rounded rectangle with cairo context cr (without fill)
   -- thanks to https://www.cairographics.org/samples/rounded_rectangle/
   local aspect = 1.0
   local corner_radius = height / 10.0

   local radius = corner_radius / aspect
   local degrees = 3.1415 / 180.0

   cr:new_sub_path()
   cr:arc(x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees)
   cr:arc(x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees)
   cr:arc(x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees)
   cr:arc(x + radius, y + radius, radius, 180 * degrees, 270 * degrees)
   cr:close_path()
end

local function cycle(altTabTable, altTabIndex, dir)
   -- Switch to next client
   altTabIndex = altTabIndex + dir
   while altTabIndex > #altTabTable do
      altTabIndex = altTabIndex - #altTabTable -- wrap around
   end
   while altTabIndex < 1 do
      altTabIndex = altTabIndex + #altTabTable -- wrap around
   end

   altTabTable[altTabIndex].minimized = false

   if not settings.preview_box and not settings.client_opacity then
      client.focus = altTabTable[altTabIndex]
   end

   if settings.client_opacity then
      clientOpacity(altTabTable, altTabIndex)
   end

   return altTabIndex
end

local function preview()
   if not settings.preview_box then return end

   -- Apply settings
   preview_wbox:set_bg(settings.preview_box_bg)
   preview_wbox.border_color = settings.preview_box_border

   local preview_widgets = {}

   -- Make the wibox the right size, based on the number of clients
   local n = math.max(7, #altTabTable)
   local W = screen[mouse.screen].geometry.width -- + 2 * preview_wbox.border_width
   local w = W / n -- widget width
   local h = w * 0.75  -- widget height -- without the titlebox!
   local textboxHeight = w * 0.125

   local x = screen[mouse.screen].geometry.x - preview_wbox.border_width
   local y = screen[mouse.screen].geometry.y + (screen[mouse.screen].geometry.height - h - textboxHeight) / 2
   preview_wbox:geometry({x = x, y = y, width = W, height = h + textboxHeight})

   -- determine fontsize -> find maximum classname-length
   local text, textWidth, textHeight, maxText
   local maxTextWidth = 0
   local maxTextHeight = 0
   local bigFont = textboxHeight / 2
   cr:set_font_size(fontSize)
   for i = 1, #altTabTable do
      text = " - " .. altTabTable[i].class
      textWidth = cr:text_extents(text).width
      textHeight = cr:text_extents(text).height
      if textWidth > maxTextWidth or textHeight > maxTextHeight then
         maxTextHeight = textHeight
         maxTextWidth = textWidth
         maxText = text
      end
   end

   while true do
      cr:set_font_size(bigFont)
      textWidth = cr:text_extents(maxText).width
      textHeight = cr:text_extents(maxText).height

      if textWidth < w - textboxHeight and textHeight < textboxHeight then
         break
      end

      bigFont = bigFont - 1
   end

   -- create all the widgets
   for i = 1, #altTabTable do
      preview_widgets[i] = wibox.widget.base.make_widget()
      preview_widgets[i].fit = function(preview_widget, width, height)
         return w, h
      end

      local c = altTabTable[i]

      preview_widgets[i].draw = function(preview_widget, preview_wbox, cr, width, height)
         if width ~= 0 and height ~= 0 then
            local focus = (c == altTabTable[altTabIndex])
            local fontSize = bigFont

   	      local sx, sy, tx, ty

            -- Icons
            -- TODO resolution of icons? (really bad atm)
            local icon
            if c.icon == nil then
               icon = gears.surface(gears.surface.load(noicon))
            else
               icon = gears.surface(c.icon)
            end

            local iconboxHeight = 0.8 * h
            local iconboxWidth = iconboxHeight

            -- Titles
            cr:select_font_face(unpack(settings.preview_box_title_font))
            cr:set_font_face(cr:get_font_face())
            cr:set_font_size(fontSize)

            text = c.class
            textWidth = cr:text_extents(text).width
            textHeight = cr:text_extents(text).height


            -- Draw icons and icon background for selected client
            tx = (w - iconboxWidth) / 2
            ty = (h - iconboxHeight) / 2
            sx = iconboxWidth / icon.width
            sy = iconboxHeight  / icon.height

            -- Draw icon background for selected client
            if focus then
               local width = iconboxWidth * 1.1
               local height = iconboxHeight * 1.1
               local x = tx - (width - iconboxWidth) / 2
               local y = ty - (height - iconboxHeight) / 2
               cairo_rounded_rectangle(cr, x, y, width, height)

               cr:set_source_rgba(0, 0, 0, 0.5)
               cr:fill()
            end

            cr:translate(tx, ty)
            cr:scale(sx, sy)
            cr:set_source_surface(icon, 0, 0)
            cr:paint()
            cr:scale(1/sx, 1/sy)
            cr:translate(-tx, -ty)

            -- Draw title for selected client
            if focus then
               tx = (w - textWidth) / 2
               ty = h + (textboxHeight + textHeight) / 2

               cr:set_source_rgba(unpack(settings.preview_box_title_color))
               cr:move_to(tx, ty)
               cr:show_text(text)
               cr:stroke()
            end
         end
      end

      -- Add mouse handler
      preview_widgets[i]:connect_signal("mouse::enter", function()
         altTabIndex = cycle(altTabTable, altTabIndex, i - altTabIndex)
      end)

      preview_live_timer:connect_signal("timeout", function()
					   preview_widgets[i]:emit_signal("widget::updated")
      end)

   end

   -- Spacers left and right
   local spacer = wibox.widget.base.make_widget()
   spacer.fit = function(leftSpacer, width, height)
      return (W - w * #altTabTable) / 2, preview_wbox.height
   end
   spacer.draw = function(preview_widget, preview_wbox, cr, width, height) end

   --layout
   preview_layout = wibox.layout.fixed.horizontal()

   preview_layout:add(spacer)
   for i = 1, #altTabTable do
      preview_layout:add(preview_widgets[i])
   end
   preview_layout:add(spacer)

   preview_wbox:set_widget(preview_layout)
end

local function clientOpacity(altTabTable, altTabIndex)
   if not settings.client_opacity then return end

   for i,c in pairs(altTabTable) do
      if i == altTabIndex then
	 c.opacity = 1
      elseif applyOpacity then
	 c.opacity = settings.client_opacity_value
      end
   end
end

local function switch(dir, alt, tab, shift_tab)

   altTabTable = {}
   local altTabMinimized = {}
   local altTabOpacity = {}

   -- Get focus history for current tag
   local s = mouse.screen;
   local idx = 0
   local c = awful.client.focus.history.get(s, idx)

   while c do
      table.insert(altTabTable, c)
      table.insert(altTabMinimized, c.minimized)
      table.insert(altTabOpacity, c.opacity)
      idx = idx + 1
      c = awful.client.focus.history.get(s, idx)
   end

   -- Minimized clients will not appear in the focus history
   -- Find them by cycling through all clients, and adding them to the list
   -- if not already there.
   -- This will preserve the history AND enable you to focus on minimized clients

   local t = s.selected_tag
   local all = client.get(s)

   for i = 1, #all do
      local c = all[i]
      local ctags = c:tags();

      -- check if the client is on the current tag
      local isCurrentTag = false
      for j = 1, #ctags do
         if t == ctags[j] then
            isCurrentTag = true
            break
         end
      end

      if isCurrentTag then
         -- check if client is already in the history
         -- if not, add it
         local addToTable = true
         for k = 1, #altTabTable do
            if altTabTable[k] == c then
               addToTable = false
               break
            end
         end

         if addToTable then
            table.insert(altTabTable, c)
            table.insert(altTabMinimized, c.minimized)
            table.insert(altTabOpacity, c.opacity)
         end
      end
   end

   if #altTabTable == 0 then
      return
   elseif #altTabTable == 1 then
      altTabTable[1].minimized = false
      altTabTable[1]:raise()
      return
   end

   -- reset index
   altTabIndex = 1

   -- preview delay timer
   local previewDelay = settings.preview_box_delay / 1000
   local previewDelayTimer = timer({timeout = previewDelay})
   previewDelayTimer:connect_signal("timeout", function()
				       preview_wbox.visible = true
				       previewDelayTimer:stop()
				       preview(altTabTable, altTabIndex)
   end)
   previewDelayTimer:start()
   preview_live_timer:start()

   -- opacity delay timer
   local opacityDelay = settings.client_opacity_delay / 1000
   local opacityDelayTimer = timer({timeout = opacityDelay})
   opacityDelayTimer:connect_signal("timeout", function()
				       applyOpacity = true
				       opacityDelayTimer:stop()
				       clientOpacity(altTabTable, altTabIndex)
   end)
   opacityDelayTimer:start()


   -- Now that we have collected all windows, we should run a keygrabber
   -- as long as the user is alt-tabbing:
   if(keygrabber.isrunning() == false) then
      keygrabber.run(function (mod, key, event)
         -- Stop alt-tabbing when the alt-key is released
         if key == alt or key == "Escape" and event == "release" then
            preview_wbox.visible = false
            applyOpacity = false
            preview_live_timer:stop()
            previewDelayTimer:stop()
            opacityDelayTimer:stop()

            if key == "Escape" then
               for i,c in pairs(altTabTable) do
                  c.opacity = altTabOpacity[i]
               end
               keygrabber.stop()
               return
            end

            -- Raise clients in order to restore history
            local c
            for i = 1, altTabIndex - 1 do
               c = altTabTable[altTabIndex - i]
               if not altTabMinimized[i] then
                  c:raise()
                  client.focus = c
               end
            end

            -- raise chosen client on top of all
            c = altTabTable[altTabIndex]
            c:raise()
            client.focus = c

            -- restore minimized clients
            for i = 1, #altTabTable do
               if i ~= altTabIndex and altTabMinimized[i] then
                  altTabTable[i].minimized = true
               end
               altTabTable[i].opacity = altTabOpacity[i]
            end

            keygrabber.stop()

         -- Move to next client on each Tab-press
         elseif (key == tab or key == "Right") and event == "press" then
            altTabIndex = cycle(altTabTable, altTabIndex, 1)
            if settings.cycle_raise_client == true then
               c = altTabTable[altTabIndex]
               c:raise()
            end

         -- Move to previous client on Shift-Tab
         elseif (key == shift_tab or key == "Left") and event == "press" then
            altTabIndex = cycle(altTabTable, altTabIndex, -1)
            if settings.cycle_raise_client == true then
               c = altTabTable[altTabIndex]
               c:raise()
            end
         end
         end)
   end

   -- switch to next client
   altTabIndex = cycle(altTabTable, altTabIndex, dir)
   if settings.cycle_raise_client == true then
      c = altTabTable[altTabIndex]
      c:raise()
   end

end -- function altTab

return {switch = switch, settings = settings}
