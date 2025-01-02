local game = Game()

---@return ChargeBar
local function ChargeBar()
    local sprite = Sprite()

    sprite:Load("gfx/chargebar.anm2", true)

    ---@class ChargeBar
    local chargeBar = {
        Sprite = sprite,
        Charge = 0,
        State = "Init",
        Max = 100,
        Charged = false,
    }

    ---@param path string
    function chargeBar:TryLoad(path)
        if chargeBar.Sprite:GetFilename() ~= path then
            local frame = chargeBar.Sprite:GetFrame()
            local anim = chargeBar.Sprite:GetAnimation()

            sprite:Load(path, true)
            sprite:SetFrame(anim, frame)
        end
    end

    ---@param charge number
    ---@param max? number Default = 100
    function chargeBar:SetCharge(charge, max)
        max = max or 100

        local prev = chargeBar.Charge

        chargeBar.Charge = charge
        chargeBar.Max = max

        if charge <= 0 then
            if prev > 0 then
                chargeBar.State = "Disappear"
            end

            chargeBar.Charged = false
        elseif charge < max then
            chargeBar.State = "Charging"
        elseif charge >= max and not chargeBar.Charged then
            chargeBar.Charged = true
            chargeBar.State = "StartCharged"
        end
    end

    ---@param pos Vector
    function chargeBar:Render(pos)
        if game:GetRoom():GetRenderMode() ~= RenderMode.RENDER_WATER_REFLECT then
            if chargeBar.State == "Charging" then -- handle charging state differently
                chargeBar.Sprite:SetFrame(chargeBar.State, math.floor((chargeBar.Charge / chargeBar.Max) * 100))
            elseif chargeBar.State ~= "None" then
                if chargeBar.Sprite:IsFinished(chargeBar.State) then -- transition to next state
                    if chargeBar.State == "StartCharged" then
                        chargeBar.State = "Charged"
                    elseif chargeBar.State == "Disappear" then
                        chargeBar.State = "None"
                    end
                end

                if not chargeBar.Sprite:IsPlaying(chargeBar.State) then -- start playing current state if not playing already
                    chargeBar.Sprite:Play(chargeBar.State, true)
                else
                    if Isaac.GetFrameCount() % 2 == 0 then -- has to be played at half speed for some reason
                        chargeBar.Sprite:Update() -- update state :)
                    end
                end
            elseif chargeBar.State == "None" then
                return
            end

            if Options.ChargeBars then --check added by somebody
                chargeBar.Sprite:Render(pos)
            end
        end
    end

    return chargeBar
end

return ChargeBar
--[[
    Adapted from Freakman
    Kerkel was here
]]