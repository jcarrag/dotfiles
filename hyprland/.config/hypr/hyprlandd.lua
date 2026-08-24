-- Hyprland *debug build* config, lua flavour. Ported from hyprlandd.conf.
-- Debug builds look for hyprlandd.{lua,conf}; .lua wins when both exist, so
-- the old .conf stays as a fallback: delete/rename this file to revert.
--
-- This is the nested/debug session, so mainMod is CTRL+SUPER to avoid
-- swallowing the host session's SUPER binds.

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- scale hm90 fake hdmi x2
hl.monitor({ output = "desc:XMD Mi TV", mode = "3840x2160@60.00000", position = "auto", scale = "1.33333" })
-- scale xps screen x2
hl.monitor({ output = "desc:Samsung Display Corp. 0x4163", mode = "preferred", position = "auto", scale = "2" })
-- fwk screen
hl.monitor({ output = "desc:BOE 0x0BCA", mode = "preferred", position = "auto", scale = "1.33333" })
-- home monitor
-- disable hdr as it makes monitor dim: cm = "hdredid", bitdepth = 10
hl.monitor({
	output = "desc:LG Electronics LG HDR 4K 0x0003EE6B",
	mode = "highres",
	position = "auto-right",
	scale = "1.6",
	vrr = 1,
})
-- A01
hl.monitor({
	output = "desc:LG Electronics LG ULTRAFINE 309MARZBH982",
	mode = "preferred",
	position = "auto-left",
	scale = "1.6",
})
-- A02
hl.monitor({
	output = "desc:LG Electronics LG ULTRAFINE 306MABT6SK41",
	mode = "preferred",
	position = "auto-left",
	scale = "1.6",
})
-- carl's desk
hl.monitor({
	output = "desc:LG Electronics LG ULTRAFINE 306MAEG6SK32",
	mode = "preferred",
	position = "auto-left",
	scale = "1.6",
})
-- asus monitor
hl.monitor({
	output = "desc:Ancor Communications Inc ASUS MG28U 0x0001052F",
	mode = "preferred",
	position = "auto-up",
	scale = "1.6",
})
-- benq home
hl.monitor({ output = "desc:BNQ BenQ GW2480 N8K0004401Q", mode = "preferred", position = "auto", scale = "1" })
-- fallback for other screens (must be last to be configured)
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })

--------------------------------
---- WINDOW/WORKSPACE RULES ----
--------------------------------

hl.window_rule({
	name = "gamescope",
	match = { class = "^gamescope$" },
	fullscreen = true,
	monitor = "2",
})

hl.window_rule({
	name = "steam-games",
	match = { class = "^steam_app_\\d+$" },
	fullscreen = true,
	monitor = "1",
	workspace = "10",
})

-- legacy `border:false, rounding:false` are inverted as no_border/no_rounding
hl.workspace_rule({ workspace = "10", no_border = true, no_rounding = true })

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")

-- explicitly set the GPUs available to Hyprland to prevent the dGPU from being selected so that
-- the dGPU can be unbound after being initialised by amdgpu (necessary for VFIO to work)
-- FIXME: try moving to nixos config to define per host
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/amd-5700xt:/dev/dri/amd-igpu:/dev/dri/nuc-intel-igpu")
-- hl.env("AQ_DRM_DEVICES", "/dev/dri/amd-rx9070xt:/dev/dri/amd-5700xt:/dev/dri/amd-igpu:/dev/dri/nuc-intel-igpu")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
	-- fix for gamescope: https://discourse.nixos.org/t/gamescope-not-working-after-updating-to-25-05-amd-gpu/65233/7
	-- TODO: remove when merged (v0.51.0): https://github.com/hyprwm/Hyprland/commit/4e8875b
	debug = {
		full_cm_proto = true,
		disable_logs = false,
	},

	input = {
		kb_layout = "gb",
		kb_variant = "",
		kb_model = "",
		kb_options = "shift:both_capslock",
		kb_rules = "",

		follow_mouse = 2,

		touchpad = {
			natural_scroll = false,
			-- registry key is "tap-and-drag"; lua normalises '-' to '_'
			tap_and_drag = false,
		},

		sensitivity = 0.25, -- -1.0 - 1.0, 0 means no modification.
		accel_profile = "adaptive",
	},

	general = {
		gaps_in = 5,
		gaps_out = 20,
		border_size = 2,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		layout = "dwindle",

		-- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
		allow_tearing = false,
	},

	decoration = {
		rounding = 10,

		blur = {
			enabled = true,
			size = 3,
			passes = 1,
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		-- NOTE: legacy `pseudotile` was removed upstream; only the
		-- hl.dsp.window.pseudo() keybind remains (mainMod + P below).
		preserve_split = true, -- you probably want this
	},

	cursor = {
		hide_on_key_press = true,
		-- these two are tri-state ints (0 = disable, 1 = enable, 2 = auto), not bools
		use_cpu_buffer = 1,
		no_hardware_cursors = 1,
	},

	misc = {
		force_default_wallpaper = -1, -- Set to 0 to disable the anime mascot wallpapers
		disable_splash_rendering = true,
		disable_hyprland_logo = true,
	},

	xwayland = {
		-- disable scaling so that xwayland apps can use 4K
		force_zero_scaling = true,
	},
})

-- Some default animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
-- the 4 legacy bezier numbers are the 2 control points
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

---------------------
---- KEYBINDINGS ----
---------------------

-- legacy was `$mainMod = CTRL_SUPER`; the lua parser splits on '+' only,
-- so the combined token has to be spelled out
local mainMod = "CTRL + SUPER"

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brillo -A 10"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brillo -U 10"), { repeating = true })

hl.bind("CONTROL + SPACE", hl.dsp.exec_cmd("swaync-client --close-latest"))

hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.exec_cmd("hyprlock"))

hl.bind(mainMod .. " + CONTROL + LEFT", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CONTROL + RIGHT", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CONTROL + UP", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CONTROL + DOWN", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + bracketright", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + bracketleft", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(
	mainMod .. " + SHIFT + bracketright",
	hl.dsp.window.resize({ x = 0, y = -40, relative = true }),
	{ repeating = true }
)
hl.bind(
	mainMod .. " + SHIFT + bracketleft",
	hl.dsp.window.resize({ x = 0, y = 40, relative = true }),
	{ repeating = true }
)

-- legacy `fullscreen, 2` -> real fullscreen; `fullscreen, 1` -> maximized
-- (only "1" maps to maximized; every other arg means fullscreen)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + Y", hl.dsp.window.move({ out_of_group = true }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down", group_aware = true }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up", group_aware = true }))

hl.bind(mainMod .. " + CONTROL + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + CONTROL + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mainMod .. " + CONTROL + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + CONTROL + L", hl.dsp.window.swap({ direction = "right" }))

hl.bind(mainMod .. " + CONTROL + semicolon", hl.dsp.group.move_window({ forward = false }))
hl.bind(mainMod .. " + CONTROL + quoteright", hl.dsp.group.move_window({ forward = true }))
hl.bind(mainMod .. " + semicolon", hl.dsp.group.prev())
hl.bind(mainMod .. " + quoteright", hl.dsp.group.next())

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("alacritty"))
hl.bind(mainMod .. " + BACKSPACE", hl.dsp.window.close())
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | wl-copy'))
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("rofi -show run -show-icons"))
hl.bind(
	mainMod .. " + SHIFT + E",
	hl.dsp.exec_cmd(
		"SUDO_ASKPASS=/home/james/bin/askpass-rofi rofi -dpi 1 -matching fuzzy -modi combi -show combi -combi-modi run,drun -run-command 'sudo -A {cmd}'"
	)
)
hl.bind(mainMod .. " + CONTROL + E", hl.dsp.exec_cmd("rofi -show drun -show-icons"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + comma", hl.dsp.layout("togglesplit")) -- dwindle

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + CONTROL + [0-9]
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i, on_current_monitor = true }))
	hl.bind(mainMod .. " + CONTROL + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Move to next/previous workspace
hl.bind(mainMod .. " + SHIFT + comma", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + SHIFT + period", hl.dsp.focus({ workspace = "e+1" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize())

-- Sends the active window to a "minimised" workspace and pops it off the stack back into current workspace
hl.bind(mainMod .. " + W", hl.dsp.window.move({ workspace = "special:minimised", follow = false }))
hl.bind(mainMod .. " + CONTROL + W", function()
	hl.dispatch(hl.dsp.workspace.toggle_special("minimised"))
	hl.dispatch(hl.dsp.window.move({ workspace = "+0" }))
end)

hl.bind("XF86PowerOff", hl.dsp.exec_cmd("wlogout"))

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd HYPRLAND_INSTANCE_SIGNATURE")

	-- hl.exec_cmd("sunsetr")

	hl.exec_cmd("waybar")

	-- The rest of the host session's autostart is intentionally left off in the
	-- nested debug session; see hyprland.lua for the full list.
end)
