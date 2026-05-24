-- Locales/Loader.lua

TBR_L = setmetatable({}, {
    __index = function(t, k)
        return k
    end,
    __newindex = function(t, k, v)

        if v ~= true then
            rawset(t, k, v)
        end
    end,
})