local NUM_SPELL_SLOTS = 5
local SPELL_UI_FADE_IN = 0.3
local SPELL_UI_FADE_OUT = 0.6
local SPELL_SLOT_SPREAD = Vector(17.5, 0)
local SPELL_UI_Y_OFFSET = Vector(0, -40)
local SPELL_UI_OFFSET_SPRITESCALE = Vector(0, -32)
local SPELL_SELECT_MOUSE_RANGE = math.huge
local DEFAULT_SPELL = (NUM_SPELL_SLOTS + 1) // 2

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
    return Isaac.WorldToScreen(player.Position) + SPELL_UI_Y_OFFSET + SPELL_UI_OFFSET_SPRITESCALE * (player.SpriteScale.Y - 1)
end

---@param index integer
---@return Vector
local function GetSlotOffset(index)
    return SPELL_SLOT_SPREAD * index - SPELL_SLOT_SPREAD * (NUM_SPELL_SLOTS + 1) / 2
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

    if not noSFX then
        if index > save.SelectedSpell then
            SFXManager():Play(SoundEffect.SOUND_CHARACTER_SELECT_RIGHT, nil, 0)
        elseif index < save.SelectedSpell then
            SFXManager():Play(SoundEffect.SOUND_CHARACTER_SELECT_LEFT, nil, 0)
        end
    end

    if index > NUM_SPELL_SLOTS then
        index = 1
    elseif index < 1 then
        index = NUM_SPELL_SLOTS
    end

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

        local save = GetSave(player)

        if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then
            SelectSpell(player, save.SelectedSpell + 1)
        end

        if Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) then
            SelectSpell(player, save.SelectedSpell - 1)
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

-- ---@param player EntityPlayer
-- local function TempSelectionRenderer(player)
--     local save = GetSave(player)
--     local pos = Isaac.WorldToScreen(player.Position)

--     Isaac.RenderText(tostring(save.SelectedSpell), pos.X - 20, pos.Y, 1, 1, 1, 1)
-- end

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    if Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local data = GetData(player)

    -- TempSelectionRenderer(player)

    if data.SlotSprites[1].Color.A > 0.0005 then
        local playerPos = GetSlotAnchor(player)

        for i, sprite in ipairs(data.SlotSprites) do
            local adjustedPos = playerPos + GetSlotOffset(i)

            sprite:Render(adjustedPos)
        end
    end
end)