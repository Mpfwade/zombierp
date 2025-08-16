local PLUGIN = PLUGIN
util.AddNetworkString("TriggerScreenShake")
util.AddNetworkString("MoodlesIcons")
local function TriggerClientScreenShake(player, duration, intensity, radius, viewpunch) -- Function to trigger screenshake
    net.Start("TriggerScreenShake")
    net.WriteFloat(duration)
    net.WriteFloat(intensity)
    net.WriteFloat(radius)
    net.WriteVector(viewpunch or Vector(0, 0, 0))
    net.Send(player)
end

function PLUGIN:EntityTakeDamage(target, dmginfo)
    if target:IsPlayer() and target:Health() < 15 and (dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_BULLET) or dmginfo:IsDamageType(DMG_SHOCK)) and not target:GetNWBool("Ragdolled", false) then
        local tarchar = target:GetCharacter()
        local team = target:Team()
        target:ShouldSetRagdolled(true)
        target:SetNWBool("Ragdolled", true)
        target:SetNWBool("Healed", false)
        target:Freeze(true)
        ix.chat.Send(target, "me", "'s body crumbles to the ground.")
        target:SetAction("You Are Unconscious...", 35, function()
            target:SetNWBool("Ragdolled", false)
            target:ShouldSetRagdolled(false)
            target:SetHealth(15)
            target:Freeze(false)
            if not target:GetNWBool("Dying") then
                target:ChatNotify("I'm dying... I need medical, now.")
                target:SetNWBool("Dying", true)
            end

            timer.Simple(0.95, function() if target:GetWeapon("gmod_tool") then target:SelectWeapon("ix_hands") end end)
            timer.Simple(120, function()
                target:StopSound("player/heartbeat1.wav")
                if not target:GetNWBool("Healed", true) == true and target:GetNWBool("Dying", true) == true then
                    target:Kill()
                    tarchar:SetData("tied", false)
                    target:SetRestricted(false)
                end
            end)
        end)
    end
end

function PLUGIN:SetupTimer(client, character)
    local steamID = client:SteamID64()
    timer.Create("ixWarmth" .. steamID, ix.config.Get("warmthTickTime", 5), 0, function()
        if IsValid(client) and character then
            self:WarmthTick(client, character, ix.config.Get("warmthTickTime", 5))
        else
            timer.Remove("ixWarmth" .. steamID)
        end
    end)
end

function PLUGIN:SetupAllTimers()
    for _, v in ipairs(player.GetAll()) do
        local character = v:GetCharacter()
        if character then self:SetupTimer(v, character) end
    end
end

function PLUGIN:RemoveAllTimers()
    for _, v in ipairs(player.GetAll()) do
        timer.Remove("ixWarmth" .. v:SteamID64())
    end
end

function PLUGIN:WarmthEnabled()
    self:SetupAllTimers()
end

function PLUGIN:WarmthDisabled()
    self:RemoveAllTimers()
end

function PLUGIN:ApplyImmunity(char)
    local immunityTimer = "Immunity_" .. char:GetID() -- Assuming each character has a unique ID
    if timer.Exists(immunityTimer) then timer.Remove(immunityTimer) end
    timer.Create(immunityTimer, 600, 1, function() if IsValid(char) then char:SetData("sickness_immunity", nil) end end)
    char:SetData("immunityTimer", immunityTimer) -- Store the timer name for later reference
end

function PLUGIN:PlayerLoadedCharacter(client, character, lastCharacter)
    if client:IsCombine() or client:Team() == FACTION_VORTIGAUNT then
        character:SetData("sickness", 0)
        character:SetData("sicknessType", "none")
    end

    if client:IsCombine() then
        self:StartHungerIncreaseTimer(client)
    else
        self:StopHungerIncreaseTimer(client)
    end

    if ix.config.Get("warmthEnabled", false) then self:SetupTimer(client, character) end
    if lastCharacter and lastCharacter:GetData("immunityTimer") then
        local timerName = lastCharacter:GetData("immunityTimer")
        if timer.Exists(timerName) then timer.Remove(timerName) end
    end

    if character and character:GetData("sickness_immunity") then -- Optionally re-apply immunity if switching back to a character who should still be immune
        self:ApplyImmunity(character)
    end
end

function PLUGIN:PlayerDeath(client)
    local character = client:GetCharacter()
    if timer.Exists("shiver") then timer.Remove("shiver") end
    if character then character:SetWarmth(100) end
end

function PLUGIN:WarmthTick(client, character, delta)
    if not client:Alive() or client:GetMoveType() == MOVETYPE_NOCLIP or hook.Run("ShouldTickWarmth", client) == false then return end
    if client:IsCombine() or client:Team() == FACTION_VORTIGAUNT or client:Team() == FACTION_CCA then -- Handle factions that are not affected by cold
        character:SetWarmth(100)
        if timer.Exists("shiver_" .. client:SteamID()) then timer.Remove("shiver_" .. client:SteamID()) end
        return
    end

    local scale = 1 -- Initialize scale to default value
    if self:PlayerIsInside(client) then scale = -ix.config.Get("warmthRecoverScale", 0.5) end
    local entities = ents.FindInSphere(client:GetPos(), self.warmthEntityDistance) -- Check for warmth-generating entities
    for _, v in ipairs(entities) do
        if self.warmthEntities[v:GetClass()] then
            scale = -ix.config.Get("warmthFireScale", 2)
            break -- Exit the loop once a warmth entity is found
        end
    end

    local equippedItems = {
        ["coat"] = 1.95, -- Calculate warmth impact from equipped items
        ["bluebeanie"] = 0.55,
        ["greenbeanie"] = 0.55,
        ["gloves"] = 0.50,
    }

    for itemID, itemScale in pairs(equippedItems) do
        local item = character:GetInventory():GetItemsByUniqueID(itemID)[1]
        if item and item:GetData("equip") == true then scale = scale - itemScale end
    end

    local newWarmth = math.Clamp(character:GetWarmth() - scale * (delta / ix.config.Get("warmthLossTime", 5)), 0, 100) -- Update character warmth
    local currentWarmth = character:GetWarmth()
    character:SetWarmth(newWarmth)
    local isWarmingUp = newWarmth > currentWarmth
    local isCoolingDown = newWarmth < currentWarmth
    local hasWarmedUpMsgShown = character:GetData("hasWarmedUpMsgShown", false)
    local hasBeenWarmedUp = character:GetData("hasBeenWarmedUp", false)
    local warmingUpCooldown = 20 -- Cooldown in seconds
    local lastWarmUpTime = character:GetData("lastWarmUpTime", 0)
    local currentTime = CurTime()
    if isWarmingUp and not hasBeenWarmedUp and (currentTime - lastWarmUpTime > warmingUpCooldown) then -- Notify the player if they are warming up and cooldown has passed
        client:ChatNotify("You are warming up.")
        character:SetData("lastWarmUpTime", currentTime)
        character:SetData("hasBeenWarmedUp", true) -- Set the flag indicating notification has been shown
    end

    if isCoolingDown then -- Reset the flags when the player starts cooling down
        character:SetData("hasWarmedUpMsgShown", false)
        character:SetData("hasBeenWarmedUp", false) -- Reset the flag as the player is starting to cool down
    end

    if newWarmth <= 45 then -- Shivering logic
        if not timer.Exists("shiver_" .. client:SteamID()) or character:GetData("hasWarmedUpMsgShown") then
            timer.Create("shiver_" .. client:SteamID(), 35, 0, function()
                if IsValid(client) then
                    ix.chat.Send(client, "me", "starts to shiver aggressively")
                    TriggerClientScreenShake(client, 5, 5, 500, Vector(0, 5, 0))
                end
            end)
        end
    elseif timer.Exists("shiver_" .. client:SteamID()) then
        timer.Remove("shiver_" .. client:SteamID())
    end

    if newWarmth == 0 then -- Damage logic for low warmth
        local damage = ix.config.Get("warmthDamage", 2)
        if damage > 0 and client:Health() > 5 then
            client:SetHealth(math.max(5, client:Health() - damage))
        elseif ix.config.Get("warmthKill", false) then
            client:Kill()
        end
    end
end

function PLUGIN:OnCharacterCreated(client, char) --- HUNGER SYSTEM
    if IsValid(client) then
        local hunger = char:GetData("hunger", 100) -- Default to 100 if not set
        local sicknessLevel = char:GetData("sickness", 0)
        char:SetData("sickness", sicknessLevel)
        char:SetHunger(hunger)
        player.ixHungerTick = CurTime() + ix.config.Get("hungerTime", 120)
        player.ixSickTick = CurTime() + ix.config.Get("sickTime", 120)
        if client:IsCombine() or client:Team() == FACTION_VORTIGAUNT then
            char:SetData("sickness", 0)
            char:SetData("sickness", 0)
        else
            char:SetData("sickness", char:GetData("sickness", 0)) -- Set default values for non-Combine factions
        end
    end
end

local coughSounds = {"ambient/voices/cough1.wav", "ambient/voices/cough2.wav", "ambient/voices/cough3.wav", "ambient/voices/cough4.wav"}
local coughRadius = 200 -- Define the radius within which coughs affect other players
util.AddNetworkString("TriggerPukeEffect")
function PLUGIN:HandleSicknessEffects(ply, char)
    if char:GetData("sickness_immunity") then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
    if ply.ixSickTick and ply.ixSickTick > CurTime() then return end
    local sicknessLevel = char:GetData("sickness", 0)
    local shouldGetSick = char:GetWarmth() < 40 or ply:GetNWBool("recentDeathNearby", false) -- Trigger sickness if exposed to bad conditions
    if shouldGetSick then
        sicknessLevel = math.Clamp(sicknessLevel + 1, 0, 100)
    elseif sicknessLevel > 0 then
        sicknessLevel = math.Clamp(sicknessLevel - 1, 0, 100)
    end

    char:SetData("sickness", sicknessLevel)
    if sicknessLevel > 15 then self:HandleCoughing(ply, sicknessLevel) end
    if sicknessLevel > 50 then self:HandleVomiting(ply, sicknessLevel) end
    if sicknessLevel >= 65 and ply.ConsumeStamina then
        local drain = math.Clamp((sicknessLevel - 60) * 0.1, 0, 2) -- 0 to 2 stamina per tick
        ply:ConsumeStamina(drain)
    end

    ply.ixSickTick = CurTime() + ix.config.Get("sickTime", 60)
end

function PLUGIN:HandleCoughing(ply, sicknessLevel)
    local coughTimerName = "Cough_" .. ply:SteamID()
    if not timer.Exists(coughTimerName) then
        if math.random(1, 100) <= 85 then -- Simulating a chance to cough
            local coughSound = coughSounds[math.random(#coughSounds)]
            ply:EmitSound(coughSound)
            self:SpreadSickness(ply, 200) -- Spread the sickness when coughing -- Assuming 200 is the radius in which the sickness can spread
            ply:ConsumeStamina(15)
        end

        timer.Create(coughTimerName, math.random(10, 20), 1, function() if IsValid(ply) then self:HandleCoughing(ply, sicknessLevel) end end)
    end
end

function PLUGIN:HandleVomiting(ply, sicknessLevel)
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
    local pukeChance = 80
    local damageAmount = sicknessLevel > 65 and 35 or 15
    local hungerLoss = sicknessLevel > 65 and 10 or 5
    local char = ply:GetCharacter()
    if not char then return end
    if not ply:GetNWFloat("nextPukeTime") or ply:GetNWFloat("nextPukeTime") <= CurTime() then
        if math.random(1, 100) <= pukeChance then
            ply:TakeDamage(damageAmount, ply, ply)
            char:SetHunger(math.max(0, char:GetHunger() - hungerLoss))
            local pos = ply:GetPos() -- Determine the position and direction to place the decal
            local dir = -ply:GetUp() -- The decal will be projected downward
            util.Decal("decals/antlion/shot2", pos, pos + dir * 10, ply) -- Add a decal under the player's position
            if sicknessLevel > 65 then
                ply:EmitSound("citizensounds/puking.wav")
                ix.chat.Send(ply, "me", "violently projectile vomits.")
                TriggerClientScreenShake(ply, 7, 7, 500, Vector(0, 7, 0))
                ply:ConsumeStamina(90)
            else
                ply:EmitSound("citizensounds/puking.wav")
                ix.chat.Send(ply, "me", "vomits.")
                TriggerClientScreenShake(ply, 5, 5, 500, Vector(0, 5, 0))
                if not ply:GetNWBool("IsActing") then ply:ForceSequence("d2_coast03_postbattle_idle02_entry", nil, 2, false) end
                ply:ConsumeStamina(35) -- Vomiting costs 5 stamina
            end

            net.Start("TriggerPukeEffect")
            net.WriteEntity(ply)
            net.Broadcast()
            ply:SetNWFloat("nextPukeTime", CurTime() + math.random(20, 150))
            if sicknessLevel > 89 then
                ply:TakeDamage(45, ply, ply) -- Apply additional damage to the player
                ply:ShouldSetRagdolled(true)
                ply:SetNWBool("Ragdolled", true)
                ply:EmitSound("npc/vort/foot_hit.wav")
                ix.chat.Send(ply, "me", "'s body crumbles to the ground.")
                ply:SetAction("You Are Unconscious...", 35, function()
                    ply:SetNWBool("Ragdolled", false)
                    ply:ShouldSetRagdolled(false)
                end)
            end
        end
    end
end

function PLUGIN:SpreadSickness(ply, radius)
    local char = ply:GetCharacter()
    if not char or char:GetData("sickness", 0) < 20 then return end
    for _, otherPly in ipairs(player.GetAll()) do
        if otherPly ~= ply and otherPly:GetPos():Distance(ply:GetPos()) <= radius then
            local otherChar = otherPly:GetCharacter()
            if otherChar then
                local currentSickness = otherChar:GetData("sickness", 0)
                local newSickness = math.Clamp(currentSickness + 1, 0, 100) -- Increase sickness level
                otherChar:SetData("sickness", newSickness)
                print("Sickness spread from " .. ply:Nick() .. " to " .. otherPly:Nick() .. " | New sickness: " .. newSickness)
            end
        end
    end
end

function PLUGIN:PlayerTick(ply)
    if not IsValid(ply) or not ply:GetCharacter() then return end
    net.Start("MoodlesIcons")
    net.WriteEntity(ply)
    net.Send(ply)
    local char = ply:GetCharacter()
    local hungerLevel = char:GetHunger()
    local sicknessLevel = char:GetData("sickness", 0)
    self:UpdateHunger(ply, char, hungerLevel)
    self:UpdateSanity(ply)
    self:UpdateStress(ply)
    self:UpdateWeakness(ply, char)
    self:HandleSicknessEffects(ply, char, sicknessLevel)
end

function PLUGIN:UpdateHunger(ply, char, hungerLevel)
    if ply.ixHungerTick and ply.ixHungerTick > CurTime() then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end
    if hungerLevel > 0 then
        local newHunger = math.Clamp(hungerLevel - 1, 0, 100)
        char:SetHunger(newHunger)
    end

    ply.ixHungerTick = CurTime() + ix.config.Get("hungerTime", 120)
    if not ply.lastHungerNotification or CurTime() >= ply.lastHungerNotification + 180 then -- Hunger notification logic
        if hungerLevel <= 15 then
            ply:ChatNotify("I'm extremely hungry.")
        elseif hungerLevel <= 35 then
            ply:ChatNotify("I'm getting quite hungry, I should find something to eat.")
        elseif hungerLevel <= 50 then
            ply:ChatNotify("I'm getting pretty hungry")
        elseif hungerLevel <= 75 then
            ply:ChatNotify("I'm a little hungry.")
        end

        ply.lastHungerNotification = CurTime()
    end
end

hook.Add("PlayerDeath", "HungerSystem", function(ply, inf, attacker)
    local char = ply:GetCharacter()
    char:SetData("sickness", 0)
    char:SetData("weakness", 0)
    ply:RemoveDrunkEffect()
    char:SetData("sickness", 0)
    char:SetData("sickness_immunity", nil)
end)

hook.Add("PlayerDeath", "WarmthSystem", function(ply, inf, attacker)
    local character = ply:GetCharacter()
    if not character then return end
    if timer.Exists("shiver_" .. ply:SteamID()) then timer.Remove("shiver_" .. ply:SteamID()) end
    if character then character:SetWarmth(100) end
    character:SetData("hypothermiaNotified", false) -- Reset hypothermia related data
    character:SetData("increasedHeartbeat", false)
    local heartbeatTimerName = "Heartbeat_" .. ply:SteamID() -- Stop the heartbeat sound timer if it exists
    if timer.Exists(heartbeatTimerName) then timer.Remove(heartbeatTimerName) end
end)

hook.Add("PlayerDeath", "SanitySysteem", function(ply, inf, attacker)
    local character = ply:GetCharacter()
    if not character then return end
    character:SetSanity(100)
    character:SetData("stress", 0)
end)

function PLUGIN:Think()
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetCharacter() ~= nil and CurTime() >= ply:GetCharacter():GetDrunkEffectTime() and ply:GetCharacter():GetDrunkEffect() > 0 then ply:RemoveDrunkEffect() end
    end
end

util.AddNetworkString("PlayClientSound")
util.AddNetworkString("StopClientSound")
local stressImpactFactor = 0.2 -- The impact factor determines how much stress affects sanity decay
function PLUGIN:UpdateSanity(ply)
    if ply.ixSanityTick and ply.ixSanityTick > CurTime() then return end

    local char = ply:GetCharacter()
    if not char then return end

    local currentSanity = char:GetSanity()
    local stress = char:GetData("stress", 0)
    local decayRate = ix.config.Get("sanityDecayRate", 0.5) + (stress * stressImpactFactor)

    if ply:GetNWBool("InStressZone") then
        decayRate = decayRate + ix.config.Get("sanityZoneDecayRate", 1.0)
    end

    -- Nearby influences
    local pos = ply:GetPos()
    local entities = ents.FindInSphere(pos, 450)
    local isNearPositiveEntity = false
    local teamSanityBonus = 0

    for _, ent in ipairs(entities) do
        if ent:IsPlayer() and ent:Team() == ply:Team() and ent ~= ply then
            teamSanityBonus = teamSanityBonus + 0.9
        end

        if (ent:GetClass() == "ix_tv" and ent.IsActivated) or (ent:GetClass() == "ww2_radio" and ent.On) then
            isNearPositiveEntity = true
        end
    end

    -- Boost sanity from positive environment
    if isNearPositiveEntity then
        currentSanity = math.min(100, currentSanity + ix.config.Get("sanityRecoveryRate", 0.3))
    end

    -- Boost sanity if stress is zero
    if stress == 0 then
        currentSanity = math.min(100, currentSanity + 0.5) -- Adjust gain rate here
    end

    currentSanity = math.min(100, currentSanity + teamSanityBonus)
    currentSanity = math.max(0, currentSanity - decayRate)

    char:SetSanity(currentSanity)
    ply.ixSanityTick = CurTime() + ix.config.Get("sanityTime", 120)
end

function PLUGIN:UpdateStress(ply)
    local char = ply:GetCharacter()
    if not char then return end
    local stressLevel = char:GetData("stress", 0)
    local baseDecay = 1
    local stressDecayRate = 0.3
    local updateInterval = 2
    local nearbyEntities = ents.FindInSphere(ply:GetPos(), 1000) -- Detect nearby VJ Base zombies once per update to share between increase and decay logic
    local zombieCount = 0
    for _, ent in ipairs(nearbyEntities) do
        if IsValid(ent) and ent:IsNPC() then
            local class = ent:GetClass()
            if string.find(class, "npc_vj_") and (string.find(class, "lnre") or string.find(class, "lnrhl2")) then zombieCount = zombieCount + 1 end
        end
    end

    if not ply.nextStressIncrease or ply.nextStressIncrease <= CurTime() then -- Track the next time to update stress increase
        ply.nextStressIncrease = CurTime() + updateInterval
        local newStress = stressLevel
        if ply:GetNWBool("recentDeathNearby") then -- Increase stress if a recent death was nearby
            newStress = math.min(100, newStress + 10)
            print("nearby death")
        end

        if zombieCount > 5 then
            newStress = math.min(100, newStress + 0.3 * zombieCount)
            print("nearby zombies: " .. zombieCount)
        end

        char:SetData("stress", newStress)
    end

    if zombieCount < 10 then -- Stress decay ONLY if fewer than 10 zombies
        if not ply.nextStressDecay or ply.nextStressDecay <= CurTime() then
            ply.nextStressDecay = CurTime() + updateInterval
            local decay = stressDecayRate -- Increase decay rate if player is smoking
            if char:IsSmoking() then
                decay = decay + 0.5 -- You can adjust this value as needed
                print("Player is smoking - faster stress decay")
            end

            if stressLevel > 0 then
                local newStress = math.max(0, stressLevel - decay)
                char:SetData("stress", newStress)
            end
        end
    end

    local stressImpactFactor = 0.02 -- Adjust sanity decay based on current stress
    local stressFactor = stressLevel * stressImpactFactor
    local decayRate = baseDecay + stressFactor
    self:UpdateSanity(ply, decayRate)
    if ply:GetNWBool("recentDeathNearby") then -- Reset recent death flag after 30 seconds
        timer.Simple(30, function() if IsValid(ply) then ply:SetNWBool("recentDeathNearby", false) end end)
    end
end

hook.Add("DoPlayerDeath", "SanityOnDeath", function(victim, attacker, dmginfo)
    local radius = 500 -- Radius to check for nearby players
    for _, ply in ipairs(player.GetAll()) do -- Check all players to see who is within the radius of the victim
        if ply ~= victim and ply:GetPos():Distance(victim:GetPos()) <= radius then
            if attacker:IsPlayer() and ply == attacker then -- Exclude the attacker from stress increase
                continue
            end

            ply:SetNWBool("recentDeathNearby", true) -- Set a flag on players near the death to indicate a recent death was nearby
            timer.Simple(60, function()
                if IsValid(ply) then -- Reset this flag after a brief period to simulate stress response duration -- Reset after 60 seconds
                    ply:SetNWBool("recentDeathNearby", false)
                end
            end)
        end
    end
end)

function PLUGIN:UpdateWeakness(ply, char)
    if ply.ixWeakTick and ply.ixWeakTick > CurTime() then return end

    local hunger = char:GetHunger()
    local weakness = char:GetData("weakness", 0)
    local sickness = char:GetData("sickness", 0)

    -- Increase weakness based on hunger
    if hunger < 20 then
        weakness = math.min(weakness + 3, 100)
    elseif hunger < 40 then
        weakness = math.min(weakness + 1, 100)
    elseif hunger > 65 then
        weakness = math.max(0, weakness - 2)
    end

    -- Apply weakness
    char:SetData("weakness", weakness)

    -- Recover from sickness if weakness is low
    if weakness < 35 and sickness > 0 then
        char:SetData("sickness", math.max(0, sickness - 10))
    end

    -- Chance to become sick if weakness is high
    if weakness > 45 and sickness <= 0 then
        local chance = weakness - 25
        if math.random(100) < chance then
            char:SetData("sickness", 1)
        end
    end

    -- Progress sickness if already sick
    if sickness > 0 then
        char:SetData("sickness", math.min(sickness + 1, 100))
    end

    -- Stamina drain based on weakness (progressive)
    if ply.ConsumeStamina and ply:Alive() then
        local drain = math.Clamp(weakness * 0.02, 0, 3) -- Max 3 stamina drained per 10s
        if drain > 0 then
            ply:ConsumeStamina(drain)
        end
    end

    -- Scale bones
    local scale = 1 - (weakness / 750)
    local bones = ply:GetBoneCount() or 0
    for i = 0, bones - 1 do
        local boneName = ply:GetBoneName(i)
        if boneName and boneName ~= "ValveBiped.Bip01_Head" then
            ply:ManipulateBoneScale(i, Vector(scale, scale, scale))
        else
            ply:ManipulateBoneScale(i, Vector(1, 1, 1))
        end
    end

    -- Resting reduces weakness faster
    if ply:GetNWBool("IsActing") then
        char:SetData("weakness", math.max(0, weakness - 5))
    end

    ply.ixWeakTick = CurTime() + 10
end

local meleeStaminaDrain = {
    ["tfa_nmrih_bat"] = 5,      -- was 10
    ["tfa_nmrih_bcd"] = 4,      -- was 8
    ["tfa_nmrih_cleaver"] = 3,  -- was 6
    ["tfa_nmrih_crowbar"] = 4,  -- was 8
    ["tfa_nmrih_etool"] = 4.5,  -- was 9
    ["tfa_nmrih_fireaxe"] = 6,  -- was 12
    ["tfa_nmrih_fubar"] = 6.5,  -- was 13
    ["tfa_nmrih_hatchet"] = 3.5,-- was 7
    ["tfa_nmrih_kknife"] = 2,   -- was 4
    ["tfa_nmrih_lpipe"] = 5,    -- was 10
    ["tfa_nmrih_machete"] = 4.5,-- was 9
    ["tfa_nmrih_pickaxe"] = 6,  -- was 12
    ["tfa_nmrih_sledge"] = 7.5, -- was 15
    ["tfa_nmrih_spade"] = 4,    -- was 8
    ["tfa_nmrih_wrench"] = 3.5, -- was 7
}

hook.Add("KeyPress", "StaminaDrainMeleeAttack", function(ply, key)
    if not IsValid(ply) or not ply:Alive() then return end
    if key ~= IN_ATTACK then return end

    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) then return end

    local class = weapon:GetClass()
    local drain = meleeStaminaDrain[class]
    if not drain then return end

    -- Check if stamina is at least 20 before swinging
    if ply.GetStamina and ply:GetStamina() < 20 then
        -- Optionally, notify the player here
        return
    end

    -- Prevent spamming by adding cooldown
    if ply.lastMeleeDrain and ply.lastMeleeDrain > CurTime() then return end
    ply.lastMeleeDrain = CurTime() + 0.6 -- Adjust depending on weapon swing speed

    if ply.ConsumeStamina then
        ply:ConsumeStamina(drain)
    end
end)

