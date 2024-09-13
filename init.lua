
-- TODO : check if balamod is present?
local flushhotkeys = require"flushhotkeys"

local keyupdate_ref = Controller.key_press_update
function Controller:key_press_update(key, dt)
  keyupdate_ref(self, key, dt)
  flushhotkeys.handle_hotkeys(key)
end
