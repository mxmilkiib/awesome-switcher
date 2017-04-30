awesome-switcher-preview
========================

Integrate familiar Alt-Tab functionality in [awesome wm](https://github.com/awesomeWM/awesome).

![Screenshot of awesome-switcher-preview](screenshot.png)

Features:

* Live previews while alt-tabbing AND/OR Opacity effects for unselected clients
* Easily adjustable settings
* No previews when alt-tab is released within some time-frame
* Backward cycle using shift
* Intuitive order, respecting your client history
* Includes minimized clients (in contrast to some of the default window-switching utilies)

## Installation ##

Clone the repo into your `$XDG_CONFIG_HOME/awesome` directory and add the
dependency to your `rc.lua`.

```Shell
cd "$XDG_CONFIG_HOME/awesome"
git clone https://github.com/berlam/awesome-switcher-preview.git awesome-switcher-preview
```

```Lua
local switcher = require("awesome-switcher-preview")
```

## Configuration ##

Optionally edit any subset of the following settings, the defaults are:

```Lua
switcher.settings.preview_box = true,                                 -- display preview-box
switcher.settings.preview_box_bg = "#ddddddaa",                       -- background color
switcher.settings.preview_box_border = "#22222200",                   -- border-color
switcher.settings.preview_box_fps = 30,                               -- refresh framerate
switcher.settings.preview_box_delay = 150,                            -- delay in ms
switcher.settings.preview_box_title_font = {"sans","italic","normal"},-- the font for cairo
switcher.settings.preview_box_title_font_size_factor = 0.8,           -- the font sizing factor
switcher.settings.preview_box_title_color = {0,0,0,1},                -- the font color

switcher.settings.client_opacity = false,                             -- opacity for unselected clients
switcher.settings.client_opacity_value = 0.5,                         -- alpha-value
switcher.settings.client_opacity_delay = 150,                         -- delay in ms
```

Add key-bindings:
On my particular system, and I guess most, Shift-Tab is captured by the keygrabber as a 
single key, namely `ISO_LEFT_TAB`. Therefore, this is what my keybindings look like:

```Lua
awful.key({ "Mod1",           }, "Tab",
   function ()
       switcher.switch( 1, "Alt_L", "Tab", "ISO_Left_Tab")
   end),
 
awful.key({ "Mod1", "Shift"   }, "Tab",
   function ()
       switcher.switch(-1, "Alt_L", "Tab", "ISO_Left_Tab")
   end),
```

## Credits ##

The original plugin was created by [Joren Heit](https://github.com/jorenheit)
and later improved upon by [Matthias Berla](https://github.com/berlam).

Mac OS look and feel was done by [David Schatz](https://github.com/wyv3rn).

## License ##

See [LICENSE](LICENSE).
