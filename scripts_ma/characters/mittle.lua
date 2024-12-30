local NUM_SPELL_SLOTS = 4
local SPELL_UI_FADE_IN = 0.4
local SPELL_UI_FADE_OUT = 0.5
local SPELL_UI_Y_OFFSET = Vector(0, -17.5)
local SPELL_SELECT_MOUSE_RANGE = math.huge
local DEFAULT_SPELL = NUM_SPELL_SLOTS + 1
local SLOT_OFFSETS = {
    Vector(40, 0),
    Vector(0, 35),
    Vector(-40, 0),
    Vector(0, -35)
}
local SPELL_NAME_OFFSET = 45
local SPELL_NAME_LINE_SPACING = 10
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
local SPELL_TO_NAME = {
    [Spell.WATER] = {"CREEPING TIDALPILLARS"},
    [Spell.AIR] = {"SURGING WINDS"},
    [Spell.FIRE] = {"MOTHS TO THE FLAME"},
    [Spell.EARTH] = {"CLAY WEAVERS"},
    [Spell.CANTRIP] = {"CANTRIP"},
}
local SPELL_TO_GFX = {
    [Spell.WATER] = "gfx_ma/ui/spell_tidalpillars.png",
    [Spell.AIR] = "gfx_ma/ui/spell_surgingwinds.png",
    [Spell.FIRE] = "gfx_ma/ui/spell_mothstotheflame.png",
    [Spell.EARTH] = "gfx_ma/ui/spell_clayweavers.png",
    [Spell.CANTRIP] = "",
}
local ACTION_TO_SPELL_SLOT  = {
    [ButtonAction.ACTION_SHOOTRIGHT] = SpellSlot.RIGHT,
    [ButtonAction.ACTION_SHOOTDOWN] = SpellSlot.DOWN,
    [ButtonAction.ACTION_SHOOTLEFT] = SpellSlot.LEFT,
    [ButtonAction.ACTION_SHOOTUP] = SpellSlot.UP,
}
local spellFont = Font() spellFont:Load("font/luaminioutlined.fnt")

---@param index integer
---@return Sprite
local function FrameSprite(index)
    local sprite = Sprite()

    sprite:Load("gfx_ma/ui_spell.anm2", true)
    sprite:Play("Idle", true)
    sprite:ReplaceSpritesheet(0, SPELL_TO_GFX[index])
    sprite:LoadGraphics()
    sprite.Color = MothsAflame.Color.WHITE_ZERO_ALPHA

    return sprite
end

---@return Sprite[]
local function CreateSlotSprites()
    ---@type Sprite[]
    local sprites = {}

    for i = 1, NUM_SPELL_SLOTS do
        sprites[i] = FrameSprite(i)
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
            sprite:Play("Selected", true)
        else
            sprite:Play("Idle", true)
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
local function OnRender(player)
    if Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local data = GetData(player)

    if data.SlotSprites[1].Color.A > 0.0005 then
        local playerPos = GetSlotAnchor(player)

        for i, sprite in ipairs(data.SlotSprites) do
            local adjustedPos = playerPos + GetSlotOffset(i)

            sprite:Render(adjustedPos)
        end

        for i, v in pairs(SPELL_TO_NAME[GetSave(player).SelectedSpell]) do
            spellFont:DrawString(v, playerPos.X, playerPos.Y + SPELL_NAME_LINE_SPACING * (i - 1) + SPELL_NAME_OFFSET, KColor(1, 1, 1, data.SlotSprites[1].Color.A), 1, true)
        end
    end
end

if REPENTOGON then
    ---@diagnostic disable-next-line: undefined-field
    MothsAflame:AddCallback(ModCallbacks.MC_HUD_RENDER, function ()
        for _, player in ipairs(MothsAflame:GetPlayers()) do
            OnRender(player)
        end
    end)
else
    ---@param str string
    MothsAflame:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, function (_, str)
        if str ~= MothsAflame.Shader.HUD then return end

        if not Game():IsPaused() then
            for _, player in ipairs(MothsAflame:GetPlayers()) do
                OnRender(player)
            end
        end
    end)
    MothsAflame:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
        if Game():IsPaused() then
            for _, player in ipairs(MothsAflame:GetPlayers()) do
                OnRender(player)
            end
        end
    end)
end