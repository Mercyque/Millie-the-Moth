local BASE_DISTANCE = Vector(0, 0)
local KNIFE_RANGE_SCALER = 0.01
local KNOCKBACK_STRENGTH_DEFAULT = 1
local KNOCKBACK_STRENGTH_LARGE = 7.5
local KNOCKBACK_FALLOFF = 0.33
local SIZE_MULT_DEFAULT = 1
local SIZE_MULT_LARGE = 1.5
local BASE_SPRITESCALE = Vector(1, 1)
local DMG_MULT_DEFAULT = 1 / 3 / 2
local DMG_MULT_LARGE = 1 / 3 * 1.5
local DAMAGE_COOLDOWN = 30
local DAMAGE_FLASH = 20
local CHARGEBAR_OFFSET = Vector(0, 12.5)
local SWING_PLAYBACK_SPEED = 1.3
local CHARGEBAR_LERP = 0.2

---@param entity Entity
local function SharedUpdate(entity)
    local cantripData = MothsAflame:GetData(entity, "Cantrip")

    if cantripData.Knockback then
        entity.Velocity = entity.Velocity + cantripData.Knockback
        cantripData.Knockback = cantripData.Knockback * KNOCKBACK_FALLOFF
    end
end

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function (_, player)
    local save = MothsAflame:GetMittleSave(player)
    local cantripData = MothsAflame:GetData(player, "Cantrip")

    cantripData.DamageCooldown = math.max(0, (cantripData.DamageCooldown or 0) - 1)

    if save.SelectedSpell == MothsAflame.Spell.CANTRIP then
        if not cantripData.ChargeBar then
            cantripData.ChargeBar = MothsAflame.ChargeBar()
            cantripData.ChargeBar:TryLoad("gfx_ma/ui_cantripchargebar.anm2")
        end

        local targCharge = 0

        if cantripData.NumSwings then
            if (cantripData.NumSwings + 1) % 3 == 0 then
                targCharge = 105
            elseif (cantripData.NumSwings - 1) % 3 == 0 then
                targCharge = 50
            else
                cantripData.ChargeBar:SetCharge(0, 100)
            end
        end

        cantripData.ChargeBar:SetCharge(math.ceil(math.min(MothsAflame:Lerp(cantripData.ChargeBar.Charge, targCharge, CHARGEBAR_LERP), 100)))

        local primary = player:GetWeapon(1)

        if primary then
            if primary:GetWeaponType() ~= WeaponType.WEAPON_BONE then
                player:SetWeapon(Isaac.CreateWeapon(WeaponType.WEAPON_BONE, player), 1)

                local secondary = player:GetWeapon(2)

                if secondary and secondary:GetWeaponType() == WeaponType.WEAPON_BONE then
                    Isaac.DestroyWeapon(secondary)
                end
            end

            primary:SetCharge(0)
        end
    elseif cantripData.ChargeBar then
        cantripData.NumSwings = 0
        cantripData.ChargeBar:SetCharge(0)
    end

    SharedUpdate(player)
end, MothsAflame.Character.MITTLE)

---@param familiar EntityFamiliar
MothsAflame:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, function (_, familiar)
    if not (familiar.Player:GetPlayerType() == MothsAflame.Character.MITTLE and MothsAflame:GetMittleSave(familiar.Player).SelectedSpell == MothsAflame.Spell.CANTRIP) then return end
    local weapon = familiar:GetWeapon() if not weapon then return end
    weapon:SetCharge(0)
    -- SharedUpdate(familiar)
end)

---@param player EntityPlayer
---@param flag CacheFlag
MothsAflame:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function (_, player, flag)
    if flag == CacheFlag.CACHE_WEAPON then
        if player:GetPlayerType() ~= MothsAflame.Character.MITTLE then return end
        local save = MothsAflame:GetMittleSave(player) if save.SelectedSpell ~= MothsAflame.Spell.CANTRIP then return end
        player:EnableWeaponType(WeaponType.WEAPON_BONE, true)
    elseif flag == CacheFlag.CACHE_FIREDELAY then
        if player:GetPlayerType() ~= MothsAflame.Character.MITTLE then return end
        local save = MothsAflame:GetMittleSave(player) if save.SelectedSpell ~= MothsAflame.Spell.CANTRIP then return end
        player.MaxFireDelay = MothsAflame:ToMaxFireDelay(MothsAflame:ToTearsPerSecond(player.MaxFireDelay) * 2)
    end
end)

---@param knife EntityKnife
MothsAflame:AddCallback(ModCallbacks.MC_PRE_KNIFE_UPDATE, function (_, knife)
    if knife.Variant ~= KnifeVariant.BONE_CLUB then return end

    local player = MothsAflame:GetPlayerFromEntity(knife, ksil.PlayerSearchType.ALL) if not (player and player:GetPlayerType() == MothsAflame.Character.MITTLE and MothsAflame:GetMittleSave(player).SelectedSpell == MothsAflame.Spell.CANTRIP) then return end
    local sprite = knife:GetSprite()
    local parentData = MothsAflame:GetData(knife.Parent, "Cantrip")
    local swinging = knife:GetIsSwinging()
    local swing = sprite:GetLayer(1)

    if knife.SubType == KnifeSubType.CLUB_HITBOX then
        local knifeData = MothsAflame:GetData(knife, "Cantrip")

        if swinging and not knifeData.Swinging then
            parentData.NumSwings = (parentData.NumSwings or 0) + 1

            if parentData.NumSwings % 3 == 0 then
                parentData.Knockback = MothsAflame:GetLastDynamicAimVect(player):Resized(KNOCKBACK_STRENGTH_LARGE)

                if knife.Parent.Type == EntityType.ENTITY_PLAYER then
                    parentData.DamageCooldown = DAMAGE_COOLDOWN
                    player:SetMinDamageCooldown(DAMAGE_FLASH)
                end

                SFXManager():Stop(SoundEffect.SOUND_SHELLGAME)
                SFXManager():Play(SoundEffect.SOUND_SWORD_SPIN, nil, nil, nil, 1.1)
            else
                parentData.Knockback = MothsAflame:GetLastDynamicAimVect(player):Resized(KNOCKBACK_STRENGTH_DEFAULT)
            end
        end

        knifeData.Swinging = swinging
    end

    local thirdSwing = swinging and parentData.NumSwings and (parentData.NumSwings) % 3 == 0
    local scale = (1 + knife.TargetPosition.X * KNIFE_RANGE_SCALER) * (thirdSwing and SIZE_MULT_LARGE or SIZE_MULT_DEFAULT)

    sprite:GetLayer(0):SetColor(MothsAflame.Color.WHITE_ZERO_ALPHA)
    sprite.PlaybackSpeed = SWING_PLAYBACK_SPEED

    if swing and swing:GetSpritesheetPath() ~= "gfx_ma/knives/cantrip.png" then
        sprite:ReplaceSpritesheet(1, "gfx_ma/knives/cantrip.png", true)
    end

    knife.TargetPosition = ksil.Vector.ZERO
    knife.Scale = scale
    knife.SpriteScale = BASE_SPRITESCALE * scale
    knife.Velocity = knife.Parent.Position + BASE_DISTANCE:Rotated(knife.Rotation) - knife.Position
end)

---@param entity Entity
---@param amt number
---@param source EntityRef
MothsAflame:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, amt, _, source)
    local player = source and source.Entity and source.Entity:ToPlayer() if not (player and player:GetPlayerType() == MothsAflame.Character.MITTLE and MothsAflame:GetMittleSave(player).SelectedSpell == MothsAflame.Spell.CANTRIP) then return end
    local hitIndex = entity:GetHitListIndex()
    local pHash

    ---@param a Entity
    for _, v in ipairs(MothsAflame:Filter(Isaac.FindByType(EntityType.ENTITY_KNIFE, KnifeVariant.BONE_CLUB), function (a)
        local aPlayer = MothsAflame:GetPlayerFromEntity(a, ksil.PlayerSearchType.ALL) if aPlayer then
            pHash = pHash or GetPtrHash(player)
            return pHash == GetPtrHash(aPlayer)
        end
    end)) do
        ---@type EntityKnife
        local knife = v:ToKnife()

        if knife:GetIsSwinging() then
            for _, i in ipairs(knife:GetHitList()) do
                if i == hitIndex then

                    local parentData = MothsAflame:GetData(knife.Parent, "Cantrip")

                    if parentData.NumSwings and parentData.NumSwings % 3 == 0 then
                        amt = amt * DMG_MULT_LARGE

                        if entity.HitPoints - amt <= 0 then
                            entity:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
                        end

                        return {Damage = amt}
                    else
                        return {Damage = amt * DMG_MULT_DEFAULT}
                    end
                end
            end
        end
    end
end)

---@param player EntityPlayer
---@param flags DamageFlag | integer
MothsAflame:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, function (_, player, _, flags)
    local data = MothsAflame:GetData(player, "Cantrip") if not data.DamageCooldown or data.DamageCooldown == 0 then return end
    return false
end)

---@param player EntityPlayer
MothsAflame:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, function (_, player)
    local data = MothsAflame:GetData(player, "Cantrip") if not data.ChargeBar then return end
    data.ChargeBar:Render(Isaac.WorldToScreen(player.Position) + CHARGEBAR_OFFSET)
end)