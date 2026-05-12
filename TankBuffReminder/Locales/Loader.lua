-- Locales/Loader.lua
-- Creates TBR_L with a fallback metatable before any locale file loads.
-- Must be first in the Locales/ load order (see TankBuffReminder.toc).
--
-- Two fallback cases are handled:
--   1. Key not in the table at all  → __index returns the key string (English)
--   2. Key is set to `true`         → __newindex stores it; __index returns key string
--      (enUS uses `true` as shorthand for "display this key as-is")
--
-- Usage in all addon files:
--   local L = TBR_L
--   someWidget:SetText(L["My Label"])   -- always returns a string

TBR_L = setmetatable({}, {
    __index = function(t, k)
        return k   -- missing key → return the English key string itself
    end,
    __newindex = function(t, k, v)
        -- Store `true` values as nil so __index fires and returns the key string.
        -- Explicit string translations are stored normally.
        if v ~= true then
            rawset(t, k, v)
        end
        -- v == true: do nothing; __index will handle it at read time
    end,
})