local NUM_SPELL_SLOTS = 4
local SPELL_UI_FADE_IN = 0.3
local SPELL_UI_FADE_OUT = 0.6
local SPELL_SLOT_SPREAD = 40
local SPELL_UI_Y_OFFSET = Vector(0, -17.5)
local SPELL_SELECT_MOUSE_RANGE = math.huge
local DEFAULT_SPELL = NUM_SPELL_SLOTS + 1
local SLOT_OFFSETS = {
    Vector(SPELL_SLOT_SPREAD, 0),
    Vector(0, SPELL_SLOT_SPREAD),
    Vector(-SPELL_SLOT_SPREAD, 0),
    Vector(0, -SPELL_SLOT_SPREAD)
}
local SpellSlot = {
    RIGHT = 1,
    DOWN = 2,
    LEFT = 3,
    UP = 4,
}
local Spell = {
    WATER = 1,
    AIR = 2,
    FIRE = 3,
    EARTH = 4,
    CANTRIP = 5,
}
local ACTION_TO_SPELL_SLOT  = {
    [ButtonAction.ACTION_SHOOTRIGHT] = SpellSlot.RIGHT,
    [ButtonAction.ACTION_SHOOTDOWN] = SpellSlot.DOWN,
    [ButtonAction.ACTION_SHOOTLEFT] = SpellSlot.LEFT,
    [ButtonAction.ACTION_SHOOTUP] = SpellSlot.UP,
}

---@return Sprite
local function FrameSprite()
    local sprite = Sprite()

    sprite:Load("gfx_ma/ui_inventory.anm2", true)
    sprite:Play("Pip", true)
    sprite.Color = MothsAflame.Color.WHITE_ZERO_ALPHA

    return sprite
end

---@return Sprite[]
local function CreateSlotSprites()
    ---@type Sprite[]
    local sprites = {}

    for i = 1, NUM_SPELL_SLOTS do
        sprites[i] = FrameSprite()
    end

    return sprites
end

---@param player EntityPlayer
local function GetData(player)
    ---@class MittleData
    ---@field SlotSprites Sprite[]
    ---@field HoldingTab boolean
    return MothsAflame:GetData(player, "Mittle", nil, {
        SlotSprites = CreateSlotSprites(),
        HoldingTab = false,
    })
end

---@param player EntityPlayer
local function GetSave(player)
    ---@class MittleSave
    ---@field SelectedSpell integer
    return MothsAflame:GetData(player, "Mittle", ksil.DataPersistenceMode.RUN, {
        SelectedSpell = DEFAULT_SPELL
    })
end

---@param player EntityPlayer
---@return Vector
local function GetSlotAnchor(player)
    return Isaac.WorldToScreen(player.Position) + SPELL_UI_Y_OFFSET
end

---@param index integer
---@return Vector
local function GetSlotOffset(index)
    return SLOT_OFFSETS[index]
end

---@param player EntityPlayer
---@param index integer
---@return Vector
local function GetSlotPos(player, index)
    return GetSlotAnchor(player) + GetSlotOffset(index)
end

---@param player EntityPlayer
---@param index integer
---@param noSFX? boolean
local function SelectSpell(player, index, noSFX)
    local save = GetSave(player)
    local data = GetData(player)

    save.SelectedSpell = index

    for i, sprite in ipairs(data.SlotSprites) do
        if i == index then
            sprite:PlayOverlay("Frame", true)
        else
            sprite:RemoveOverlay()
        end
    end

    MothsAflame:AddCacheFlags(player, CacheFlag.CACHE_ALL)
end

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if player:GetPlayerType() ~= MothsAflame.Character.MITTLE then return end

    local data = GetData(player)
    local holdingTab = Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex)

    if holdingTab then
        for _, sprite in ipairs(data.SlotSprites) do
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 1, SPELL_UI_FADE_IN)
        end

        for k, v in pairs(ACTION_TO_SPELL_SLOT) do
            if Input.IsActionTriggered(k, player.ControllerIndex) then
                SelectSpell(player, v)
            end
        end

        if player:IsExtraAnimationFinished() then
            player:AnimatePickup(MothsAflame.Sprite.EMPTY, true, "LiftItem")
        end

        if player.ControllerIndex == 0 then
            if Input.IsMouseBtnPressed(0) then
                local mousePos = Isaac.WorldToScreen(Input.GetMousePosition(true))
                local closestSlot, closestPos

                for i = 1, NUM_SPELL_SLOTS do
                    local slotPos = GetSlotPos(player, i)

                    if not closestSlot or mousePos:Distance(slotPos) < mousePos:Distance(closestPos) then
                        closestSlot = i
                        closestPos = slotPos
                    end
                end

                if closestSlot and mousePos:Distance(closestPos) < SPELL_SELECT_MOUSE_RANGE then
                    SelectSpell(player, closestSlot)
                end
            end
        end
    else
        for _, sprite in ipairs(data.SlotSprites) do
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 0, SPELL_UI_FADE_OUT)
        end
    end

    if not holdingTab and data.HoldingTab then
        player:AnimatePickup(MothsAflame.Sprite.EMPTY, true, "HideItem")
    end

    if holdingTab and not data.HoldingTab then
        SelectSpell(player, DEFAULT_SPELL, true)
    end

    data.HoldingTab = holdingTab
end)

---@param player EntityPlayer
local function TempSelectionRenderer(player)
    local save = GetSave(player)
    local pos = Isaac.WorldToScreen(player.Position)

    Isaac.RenderText(tostring(save.SelectedSpell), pos.X - 20, pos.Y, 1, 1, 1, 1)
end

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    if Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local data = GetData(player)

    TempSelectionRenderer(player)

    if data.SlotSprites[1].Color.A > 0.0005 then
        local playerPos = GetSlotAnchor(player)

        for i, sprite in ipairs(data.SlotSprites) do
            local adjustedPos = playerPos + GetSlotOffset(i)

            sprite:Render(adjustedPos)
        end
    end
end)