local NUM_SPELL_SLOTS = 4
local SPELL_UI_FADE_IN = 0.3
local SPELL_UI_FADE_OUT = 0.6
local SPELL_SLOT_SPREAD = Vector(17.5, 0)
local SPELL_UI_Y_OFFSET = Vector(0, -40)
local SPELL_UI_OFFSET_SPRITESCALE = Vector(0, -32)

---@return Sprite
local function FrameSprite()
    local sprite = Sprite()

    sprite:Load("gfx/ui/ui_inventory.anm2", true)
    sprite:Play("Idle", true)
    sprite.Color = MothsAflame.Color.WHITE_ZERO_ALPHA

    return sprite
end

---@return Sprite[]
local function CreateFrameSprites()
    ---@type Sprite[]
    local sprites = {}

    for i = 1, NUM_SPELL_SLOTS do
        sprites[i] = FrameSprite()
    end

    return sprites
end

---@class MittleData
---@field FrameSprites Sprite[]
---@field HoldingTab boolean
---@field SelectedSlot integer

---@param player EntityPlayer
---@return MittleData
local function GetData(player)
    return MothsAflame:GetData(player, "Mittle", nil, {
        FrameSprites = CreateFrameSprites(),
        HoldingTab = false,
        SelectedSlot = 1
    })
end

local emptySprite = Sprite()

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if player:GetPlayerType() ~= MothsAflame.Character.MITTLE then return end

    local data = GetData(player)
    local holdingTab = Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex)

    if holdingTab then
        for _, sprite in ipairs(data.FrameSprites) do
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 1, SPELL_UI_FADE_IN)
        end

        if data.SelectedSlot < NUM_SPELL_SLOTS and Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) then
            data.SelectedSlot = data.SelectedSlot + 1
            SFXManager():Play(SoundEffect.SOUND_CHARACTER_SELECT_RIGHT)
        end

        if data.SelectedSlot > 1 and Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) then
            data.SelectedSlot = data.SelectedSlot - 1
            SFXManager():Play(SoundEffect.SOUND_CHARACTER_SELECT_LEFT)
        end

        if player:IsExtraAnimationFinished() then
            player:AnimatePickup(emptySprite, true, "LiftItem")
        end
    else
        for _, sprite in ipairs(data.FrameSprites) do
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 0, SPELL_UI_FADE_OUT)
        end
    end

    if not holdingTab and data.HoldingTab then
        player:AnimatePickup(emptySprite, true, "HideItem")
    end

    data.HoldingTab = holdingTab
end)

---@param player EntityPlayer
local function TempSelectionRenderer(player)
    local data = GetData(player)
    local pos = Isaac.WorldToScreen(player.Position)

    Isaac.RenderText(tostring(data.SelectedSlot), pos.X - 20, pos.Y, 1, 1, 1, 1)
end

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    if Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local data = GetData(player)

    TempSelectionRenderer(player)

    if data.FrameSprites[1].Color.A > 0.0005 then
        local playerPos = Isaac.WorldToScreen(player.Position) + SPELL_UI_Y_OFFSET + SPELL_UI_OFFSET_SPRITESCALE * (player.SpriteScale.Y - 1)

        for i, sprite in ipairs(data.FrameSprites) do
            local adjustedPos = playerPos + SPELL_SLOT_SPREAD * i - SPELL_SLOT_SPREAD * (NUM_SPELL_SLOTS + 1) / 2

            sprite:Render(adjustedPos)
        end
    end
end)