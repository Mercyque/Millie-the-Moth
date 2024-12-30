---@param pos Vector
---@param frame? integer
---@return EntityEffect
function MothsAflame:SpawnSparkle(pos, frame)
    local sparkle = MothsAflame:SpawnEffect(16, pos, nil, nil, 10)
    local sprite = sparkle:GetSprite()
    local rng = MothsAflame:NewRNG(sparkle.InitSeed)

    sprite:SetFrame(frame or 2)
    sprite.FlipX = rng:RandomFloat() < 0.5
    -- sprite.FlipY = rng:RandomFloat() < 0.5

    return sparkle
end