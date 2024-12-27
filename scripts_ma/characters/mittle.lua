local NUM_SPELL_SLOTS = 4
local SPELL_UI_FADE_AMT = 0.5
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

---@param player EntityPlayer
---@return MittleData
local function GetData(player)
    return MothsAflame:GetData(player, "Mittle", nil, {
        FrameSprites = CreateFrameSprites(),
        HoldingTab = false
    })
end

local emptySprite = Sprite()

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local data = GetData(player)

    local holdingTab = Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex)

    if holdingTab then
        for _, sprite in ipairs(data.FrameSprites) do
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 1, SPELL_UI_FADE_AMT)
        end

        if player:IsExtraAnimationFinished() then
            player:AnimatePickup(emptySprite, true, "LiftItem")
        end
    else
        for _, sprite in ipairs(data.FrameSprites) do
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 0, SPELL_UI_FADE_AMT)
        end
    end

    if not holdingTab and data.HoldingTab then
        player:AnimatePickup(emptySprite, true, "HideItem")
    end

    data.HoldingTab = holdingTab
end)

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    if Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local data = GetData(player)

    if data.FrameSprites[1].Color.A > 0.1 then
        local playerPos = Isaac.WorldToScreen(player.Position) + SPELL_UI_Y_OFFSET + SPELL_UI_OFFSET_SPRITESCALE * (player.SpriteScale.Y - 1)

        for i, sprite in ipairs(data.FrameSprites) do
            local adjustedPos = playerPos + SPELL_SLOT_SPREAD * i - SPELL_SLOT_SPREAD * (NUM_SPELL_SLOTS + 1) / 2

            sprite:Render(adjustedPos)
        end
    end
end)