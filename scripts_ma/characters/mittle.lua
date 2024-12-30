local NUM_SPELL_SLOTS = 4
local UI_FADE_IN = 0.4
local UI_FADE_OUT = 0.5
local SPELL_UI_Y_OFFSET = Vector(0, -17.5)
local SPELL_SELECT_MOUSE_RANGE = math.huge
local DEFAULT_SPELL = NUM_SPELL_SLOTS + 1
local SLOT_OFFSETS = {
    Vector(35, 0),
    Vector(0, 35),
    Vector(-35, 0),
    Vector(0, -35)
}
local RENDER_ALPHA_THRESHOLD = 0.0005
local SPELL_NAME_OFFSET = 45
local SPELL_NAME_LINE_SPACING = 10
local MANA_BAR_OFFSET = Vector(0, -40)
local MANA_BAR_NUM_FRAMES = 26
local SPRITESCALE_Y_OFFSET = Vector(0, -34)
MothsAflame.SpellSlot = {
    RIGHT = 1,
    DOWN = 2,
    LEFT = 3,
    UP = 4,
}
MothsAflame.Spell = {
    WATER = 1,
    AIR = 2,
    FIRE = 3,
    EARTH = 4,
    CANTRIP = 5,
}
MothsAflame.SPELL_TO_NAME = {
    [MothsAflame.Spell.WATER] = {"CREEPING TIDALPILLARS"},
    [MothsAflame.Spell.AIR] = {"SURGING WINDS"},
    [MothsAflame.Spell.FIRE] = {"MOTHS TO THE FLAME"},
    [MothsAflame.Spell.EARTH] = {"CLAY WEAVERS"},
    [MothsAflame.Spell.CANTRIP] = {"CANTRIP!"},
}
MothsAflame.SPELL_TO_GFX = {
    [MothsAflame.Spell.WATER] = "gfx_ma/ui/spell_tidalpillars.png",
    [MothsAflame.Spell.AIR] = "gfx_ma/ui/spell_surgingwinds.png",
    [MothsAflame.Spell.FIRE] = "gfx_ma/ui/spell_mothstotheflame.png",
    [MothsAflame.Spell.EARTH] = "gfx_ma/ui/spell_clayweavers.png",
    [MothsAflame.Spell.CANTRIP] = "",
}
MothsAflame.ACTION_TO_SPELL_SLOT  = {
    [ButtonAction.ACTION_SHOOTRIGHT] = MothsAflame.SpellSlot.RIGHT,
    [ButtonAction.ACTION_SHOOTDOWN] = MothsAflame.SpellSlot.DOWN,
    [ButtonAction.ACTION_SHOOTLEFT] = MothsAflame.SpellSlot.LEFT,
    [ButtonAction.ACTION_SHOOTUP] = MothsAflame.SpellSlot.UP,
}
local spellFont = Font() spellFont:Load("font/luaminioutlined.fnt")

---@param index integer
---@return Sprite
local function FrameSprite(index)
    local sprite = Sprite()

    sprite:Load("gfx_ma/ui_spell.anm2", true)
    sprite:Play("Idle", true)
    sprite:ReplaceSpritesheet(0, MothsAflame.SPELL_TO_GFX[index])
    sprite:LoadGraphics()
    sprite.Color = MothsAflame.Color.WHITE_ZERO_ALPHA

    return sprite
end

---@return Sprite
local function ManaBarSprite()
    local sprite = Sprite()

    sprite:Load("gfx_ma/ui_manabar.anm2", true)
    sprite:Play("Idle", true)

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
function MothsAflame:GetMittleData(player)
    ---@class MittleData
    ---@field SlotSprites Sprite[]
    ---@field HoldingTab boolean
    ---@field ManaBar Sprite
    return MothsAflame:GetData(player, "Mittle", nil, {
        SlotSprites = CreateSlotSprites(),
        HoldingTab = false,
        ManaBar = ManaBarSprite()
    })
end

---@param player EntityPlayer
function MothsAflame:GetMittleSave(player)
    ---@class MittleSave
    ---@field SelectedSpell integer
    ---@field Mana number
    return MothsAflame:GetData(player, "Mittle", ksil.DataPersistenceMode.RUN, {
        SelectedSpell = DEFAULT_SPELL,
        Mana = 50
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
    local save = MothsAflame:GetMittleSave(player)
    local data = MothsAflame:GetMittleData(player)

    if save.SelectedSpell ~= index and not noSFX then
        SFXManager():Play(SoundEffect.SOUND_CHARACTER_SELECT_RIGHT)
    end

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
---@param amt number
local function SetMana(player, amt)
    amt = MothsAflame:Clamp(amt, 0, 100)

    local save = MothsAflame:GetMittleSave(player)
    local data = MothsAflame:GetMittleData(player)

    save.Mana = amt

    data.ManaBar:SetFrame(math.floor((1 - amt / 100) * (MANA_BAR_NUM_FRAMES - 1)))
end

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, function (_, player)
    if player:GetPlayerType() ~= MothsAflame.Character.MITTLE then return end

    local data = MothsAflame:GetMittleData(player)
    local holdingTab = Input.IsActionPressed(ButtonAction.ACTION_MAP, player.ControllerIndex)

    if holdingTab then
        for _, sprite in ipairs(data.SlotSprites) do
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 1, UI_FADE_IN)
        end

        data.ManaBar.Color.A = MothsAflame:Lerp(data.ManaBar.Color.A, 0, UI_FADE_OUT)

        for k, v in pairs(MothsAflame.ACTION_TO_SPELL_SLOT) do
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
            sprite.Color.A = MothsAflame:Lerp(sprite.Color.A, 0, UI_FADE_OUT)
        end

        data.ManaBar.Color.A = MothsAflame:Lerp(data.ManaBar.Color.A, 1, UI_FADE_IN)
    end

    if not holdingTab and data.HoldingTab then
        player:AnimatePickup(MothsAflame.Sprite.EMPTY, true, "HideItem")
    end

    if holdingTab and not data.HoldingTab then
        SelectSpell(player, DEFAULT_SPELL, true)
    end

    data.HoldingTab = holdingTab

    local save = MothsAflame:GetMittleSave(player)
end)

---@param player EntityPlayer
local function OnRender(player)
    local data = MothsAflame:GetMittleData(player)

    if data.SlotSprites[1].Color.A > RENDER_ALPHA_THRESHOLD then
        local playerPos = GetSlotAnchor(player)

        for i, sprite in ipairs(data.SlotSprites) do
            local adjustedPos = playerPos + GetSlotOffset(i)

            sprite:Render(adjustedPos)
        end

        for i, v in pairs(MothsAflame.SPELL_TO_NAME[MothsAflame:GetMittleSave(player).SelectedSpell]) do
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
    MothsAflame:AddCallback(ModCallbacks.MC_POST_RENDER, function ()
        for _, player in ipairs(MothsAflame:GetPlayers()) do
            OnRender(player)
        end
    end)
end

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    if player:GetPlayerType() ~= MothsAflame.Character.MITTLE or Game():GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then return end

    local data = MothsAflame:GetMittleData(player)

    if data.ManaBar.Color.A > RENDER_ALPHA_THRESHOLD then
        data.ManaBar:Render(Isaac.WorldToScreen(player.Position) + MANA_BAR_OFFSET + SPRITESCALE_Y_OFFSET * (player.SpriteScale.Y - 1))
    end
end)

---Testing
---@param str string
---@param arg string
MothsAflame:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function (_, str, arg)
    if str ~= "mana" then return end
    SetMana(Isaac.GetPlayer(), tonumber(arg) or 0)
end)