ITEM.name = "Antibiotics"
ITEM.model = "models/willardnetworks/skills/pill_bottle.mdl"
ITEM.description = "A small bottle of broad-spectrum antibiotics, used to fight off infection over time."
ITEM.category = "Medical"
ITEM.width = 1
ITEM.height = 1

-- Custom Variables
ITEM.sicknessReduction = 50
ITEM.duration = 60
ITEM.tickInterval = 5
ITEM.reductionPerTick = 5
ITEM.maxUses = 4

function ITEM:GetDescription()
    local usesLeft = self:GetData("uses", self.maxUses)
    return self.description .. " Pills left: " .. usesLeft
end

ITEM.functions.Swallow = {
    name = "Swallow",
    sound = "items/medshot4.wav",
    OnRun = function(itemTable)
        local client = itemTable.player
        local char = client:GetCharacter()
        if not char then return false end

        local curSick = char:GetData("sickness", 0)
        if curSick <= 0 then
            client:ChatNotify("You aren’t sick enough to need antibiotics.")
            return false
        end

        local effectMultiplier = 1
        local doubleUsed = client:GetNWBool("AntibioticStacked", false)

        if doubleUsed then
            -- Second use: chance for boost or damage
            local roll = math.random(1, 100)
            if roll <= 25 then
                effectMultiplier = 2
                client:ChatNotify("The stacked antibiotics work unusually well!")
            elseif roll >= 86 then
                local dmg = 10
                client:SetHealth(math.max(1, client:Health() - dmg))
                client:ChatNotify("Stacking the antibiotics made you feel worse...")
            else
                client:ChatNotify("You stacked the antibiotics without any noticeable change.")
            end
            -- Reset stack flag
            client:SetNWBool("AntibioticStacked", false)
        else
            -- First use: set flag for next use
            client:SetNWBool("AntibioticStacked", true)

            -- Automatically clear the flag after a short window (e.g., 30 seconds)
            timer.Simple(30, function()
                if IsValid(client) then
                    client:SetNWBool("AntibioticStacked", false)
                end
            end)
        end

        client:ChatNotify("You swallow a pill...")

        local totalTicks = math.floor(itemTable.duration / itemTable.tickInterval)
        if totalTicks < 1 then totalTicks = 1 end

        local timerName = "AntibioticEffect_" .. client:SteamID64() .. "_" .. os.time()
        timer.Create(timerName, itemTable.tickInterval, totalTicks, function()
            if not (IsValid(client) and client:Alive()) then
                timer.Remove(timerName)
                return
            end

            local sickness = char:GetData("sickness", 0)
            local newSick = math.max(0, sickness - (itemTable.reductionPerTick * effectMultiplier))
            char:SetData("sickness", newSick)

            if newSick == 0 then
                timer.Remove(timerName)
                client:ChatNotify("The antibiotics have cleared the infection.")
                if itemTable.GetPlugin and itemTable:GetPlugin().ApplyImmunity then
                    itemTable:GetPlugin():ApplyImmunity(char)
                end
            end
        end)

        -- Handle multiple uses
        local uses = itemTable:GetData("uses", itemTable.maxUses)
        uses = uses - 1

        if uses <= 0 then
            client:ChatNotify("You’ve finished the antibiotics.")
            return true
        else
            itemTable:SetData("uses", uses)
            client:ChatNotify("Antibiotics used. Remaining pills: " .. uses)
            return false
        end
    end
}
