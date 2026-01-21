local hyper = { "ctrl", "cmd" }

hs.hotkey.bind(hyper, "b", function()
	local win = hs.window.focusedWindow()
	if win then
		win:sendToBack()
	end
end)

function reloadConfig(files)
	doReload = false
	for _, file in pairs(files) do
		if file:sub(-3) == ".lua" then
			doReload = true
		end
	end
	if doReload then
		hs.reload()
	end
end

myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Config loaded")
