--[[
    Custom status effect library by Kerkel
    Version 0.1.4
]]

---@class CustomStatusData
---@field Timeout integer
---@field Flags integer
---@field Tags string[]
---@field Source Entity?
---@field Sprite Sprite?
---@field FirstApplyFrame integer
---@field NewestApplyFrame integer

---@class CustomStatusEntry
---@field Anm2Path string?
---@field Animation string?
---@field Color Color?

local LOCAL_CustomStatusLib = {}

function LOCAL_CustomStatusLib.Init()
    local LOCAL_VERSION = -0.77999999

    if CustomStatusLib then
        if CustomStatusLib.Version > LOCAL_VERSION then
            return
        end
        CustomStatusLib.Internal:RemoveCallbacks()
    end

    CustomStatusLib = RegisterMod("CustomStatusLib", 1)
    CustomStatusLib.Version = LOCAL_VERSION

    CustomStatusLib.Internal = {
        CallbackEntries = {},
        RemoveCallbacks = function ()
            for _, v in ipairs(CustomStatusLib.Internal.CallbackEntries) do
                CustomStatusLib:RemoveCallback(v.Callback, v.Function)
            end
        end,
        ---@param entity Entity
        ---@return table
        GetData = function (self, entity)
            local data = entity:GetData()
            data.__CUSTOMSTATUSLIB = data.__CUSTOMSTATUSLIB or {}
            return data.__CUSTOMSTATUSLIB
        end,
    }

    CustomStatusLib.Flag = {
        ---Set status effect timeout instead of adding if it is already applied
        SET_TIMEOUT = 1 << 0
    }

    CustomStatusLib.Entries = {}

    ---@enum CustomStatusCallback
    CustomStatusLib.Callback = {
        ---Called before a status effect is gained
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* identifier - `string`
        ---* newlyApplied - `boolean`
        ---* duration - `integer`
        ---* flags - `integer`
        ---* tags - `string[]`
        ---* source - `Entity?`
        ---
        ---Returns:
        ---* Return table:
        ---  * Entity - `Entity`
        ---  * Identifier - `string`
        ---  * Duration - `integer`
        ---  * Flags - `integer`
        ---  * Tags - `string[]`
        ---  * Source - `Entity`
        ---* Return `true` to cancel
        PRE_INFLICT = "CustomStatusLib_PRE_GAIN_CUSTOM_STATUS_EFFECT",
        ---Called when a status effect is gained
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* data - `CustomStatusEffectData`
        ---* identifier - `string`
        ---* newlyApplied - `boolean`
        ---* duration - `integer`
        ---* flags - `integer`
        ---* tags - `string[]`
        ---* source - `Entity?`
        POST_INFLICT = "CustomStatusLib_POST_GAIN_CUSTOM_STATUS_EFFECT",
        ---Called when a status effect is lost
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* data - `CustomStatusEffectData`
        ---* identifier - `string`
        POST_WEAROUT = "CustomStatusLib_POST_LOSE_CUSTOM_STATUS_EFFECT",
        ---Called every 30 frames for every active status effect
        ---
        ---Parameters:
        ---* entity - `Entity`
        ---* data - `CustomStatusEffectData`
        ---* identifier - `string`
        POST_STATUS_UPDATE = "CustomStatusLib_POST_STATUS_UPDATE",
    }

    ---@param entity Entity
    ---@param identifier string
    ---@param duration integer
    ---@param flags? integer
    ---@param tags? string | string[]
    ---@param source? Entity
    function CustomStatusLib:ApplyCustomStatus(entity, identifier, duration, flags, tags, source)
        if not CustomStatusLib.Entries[identifier] then return end

        local data = CustomStatusLib.Internal:GetData(entity)
        local newlyApplied = not data[identifier]

        if not tags then
            tags = {}
        elseif type(tags) == "string" then
            tags = {tags}
        end

        flags = flags or 0

        for _, v in ipairs(Isaac.GetCallbacks(CustomStatusLib.Callback.PRE_INFLICT)) do
            if not v.Param or v.Param == identifier then
                local _return = v.Function(v.Mod, entity, identifier, newlyApplied, duration, flags, tags, source)

                if _return == true then
                    return
                elseif type(_return) == "table" then
                    entity = entity or _return.Entity
                    identifier = identifier or _return.Identifier
                    duration = duration or _return.Duration
                    flags = flags or _return.Flags
                    tags = tags or _return.Tags
                    source = source or _return.Source
                end
            end
        end

        data[identifier] = data[identifier] or {}

        data[identifier].Flags = flags
        data[identifier].FirstApplyFrame = data[identifier] or entity.FrameCount
        data[identifier].NewestApplyFrame = entity.FrameCount

        if not data[identifier].Sprite then
            if CustomStatusLib.Entries[identifier].Anm2Path then
                local sprite = Sprite()

                sprite:Load(CustomStatusLib.Entries[identifier].Anm2Path, true)
                sprite:Play(CustomStatusLib.Entries[identifier].Animation or sprite:GetDefaultAnimation(), true)

                data[identifier].Sprite = sprite
            end
        end

        if data[identifier].Tags then
            for _, v in pairs(tags) do
                table.insert(data[identifier].tags, v)
            end
        else
            data[identifier].Tags = tags
        end

        if source then
            data[identifier].Source = source
        end

        if data[identifier].Timeout and flags & CustomStatusLib.Flag.SET_TIMEOUT == 0 then
            data[identifier].Timeout = data[identifier].Timeout + duration
        else
            data[identifier].Timeout = duration
        end

        for _, v in ipairs(Isaac.GetCallbacks(CustomStatusLib.Callback.POST_INFLICT)) do
            if not v.Param or v.Param == identifier then
                v.Function(v.Mod, entity, data[identifier], identifier, newlyApplied, duration, flags, tags, source)
            end
        end
    end

    ---@param identifier string
    ---@param anm2Path? string
    ---@param animation? string
    ---@param color? Color
    function CustomStatusLib:RegisterCustomStatus(identifier, anm2Path, animation, color)
        CustomStatusLib.Entries[identifier] = {
            Anm2Path = anm2Path,
            Animation = animation,
            Color = color,
        }
    end

    ---@param entity Entity
    ---@param identifier string
    function CustomStatusLib:ClearCustomStatus(entity, identifier)
        entity.Color = Color()

        local player = entity:ToPlayer() if player then
            player:AddCacheFlags(CacheFlag.CACHE_COLOR, true)
        end

        CustomStatusLib.Internal:GetData(entity)[identifier] = nil

        for _, v in ipairs(Isaac.GetCallbacks(CustomStatusLib.Callback.POST_WEAROUT)) do
            if not v.Param or v.Param == identifier then
                v.Function(v.Mod, entity, CustomStatusLib:GetCustomStatusData(entity, identifier), identifier)
            end
        end
    end

    ---@param entity Entity
    ---@param identifier string
    ---@return CustomStatusData?
    function CustomStatusLib:GetCustomStatusData(entity, identifier)
        return CustomStatusLib.Internal:GetData(entity)[identifier]
    end

    ---@param entity Entity
    ---@param identifier string
    ---@return boolean
    function CustomStatusLib:HasCustomStatus(entity, identifier)
        return not not CustomStatusLib:GetCustomStatusData(entity, identifier)
    end

    ---@param callback ModCallbacks | string
    ---@param fn function
    ---@param param any
    local function AddCallback(callback, fn, param)
        table.insert(CustomStatusLib.Internal.CallbackEntries, {
            Callback = callback,
            Function = fn,
            Param = param,
        })
    end

    ---@param entity EntityNPC | EntityPlayer
    for _, v in ipairs({ModCallbacks.MC_POST_PLAYER_RENDER, ModCallbacks.MC_POST_NPC_RENDER}) do AddCallback(v, function (_, entity)
        if entity:IsDead() then return end
        if Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end
        for k in pairs(CustomStatusLib.Entries) do
            local data = CustomStatusLib:GetCustomStatusData(entity, k)

            if data and data.Sprite then
                local renderPos = Isaac.WorldToScreen(entity.Position + entity:GetNullOffset("OverlayEffect")) - Vector(0, JumpLib and JumpLib:GetData(entity).Height or 0) + entity.SpriteOffset

                if entity:ToPlayer() then
                    renderPos.Y = renderPos.Y - entity.SpriteScale.Y * 30
                end

                data.Sprite:Render(renderPos)

                break
            end
        end
    end) end

    ---@param entity EntityNPC | EntityPlayer
    for _, v in ipairs({ModCallbacks.MC_POST_PEFFECT_UPDATE, ModCallbacks.MC_NPC_UPDATE}) do AddCallback(v, function (_, entity)
        for k in pairs(CustomStatusLib.Entries) do
            local data = CustomStatusLib:GetCustomStatusData(entity, k)

            if data then
                entity.Color = CustomStatusLib.Entries[k].Color or entity.Color

                data.Timeout = data.Timeout - 1

                if data.Sprite then
                    data.Sprite:Update()
                end

                for _, _v in ipairs(Isaac.GetCallbacks(CustomStatusLib.Callback.POST_STATUS_UPDATE)) do
                    if not _v.Param or _v.Param == k then
                        _v.Function(_v.Mod, entity, data, k)
                    end
                end

                if data.Timeout == 0 then
                    CustomStatusLib:ClearCustomStatus(entity, k)
                end
            end
        end
    end) end

    ---@param entity Entity
    AddCallback(CustomStatusLib.Callback.PRE_INFLICT, function (_, entity)
        if entity:HasEntityFlags(EntityFlag.FLAG_NO_STATUS_EFFECTS) or (entity.Type == EntityType.ENTITY_PLAYER and entity:ToPlayer():HasCollectible(CollectibleType.COLLECTIBLE_EVIL_CHARM)) then
            return true
        end
    end)

    for _, v in ipairs(CustomStatusLib.Internal.CallbackEntries) do
        CustomStatusLib:AddCallback(v.Callback, v.Function, v.Param)
    end
end

return LOCAL_CustomStatusLib