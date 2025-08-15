local PLUGIN = PLUGIN
PLUGIN.name = "Citizen's life healthcare"
PLUGIN.description = "Make a citizen's life a real citizen's life"
PLUGIN.author = "Wade"
PLUGIN.warmthEntityDistance = 128 -- how close you need to be to the entity to start gaining warmth
PLUGIN.warmthEntities = { -- list of entities that provide warmth
    ["stormfox_campfire"] = true,
    ["env_fire"] = true
}

ix.util.Include("cl_hooks.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("sh_meta.lua")

ix.util.IncludeDir(PLUGIN.folder .. "/meta", true)
ix.util.IncludeDir(PLUGIN.folder .. "/hooks", true)
if (!pace) then return end

PLUGIN.moodles = {
    bored = {
        material = Material("citizenlifestuff/moodles/moodle_icon_bored.png"),
        isActive = false,
        position = -64,
        targetPosition = 0 -- 
    },
    unhappy = {
        material = Material("citizenlifestuff/moodles/moodle_icon_unhappy.png"),
        isActive = false,
        position = -64,
        targetPosition = 0 -- 
    },
    panic = { -- its not really panicing just really low sanity btw - wadestun citizenlifer
        material = Material("citizenlifestuff/moodles/moodle_icon_tired.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    sick = {
        material = Material("citizenlifestuff/moodles/moodle_icon_sick1.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    moresick = {
        material = Material("citizenlifestuff/moodles/moodle_icon_sick2.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    hungry = {
        material = Material("citizenlifestuff/moodles/moodle_icon_hungry.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    stressed = {
        material = Material("citizenlifestuff/moodles/moodle_icon_stressed.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    terrified = {
        material = Material("citizenlifestuff/moodles/moodle_icon_panic.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    weak = {
        material = Material("citizenlifestuff/moodles/moodle_icon_hungover.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    moreweak = {
        material = Material("citizenlifestuff/moodles/moodle_icon_pain.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
    stam = {
        material = Material("citizenlifestuff/moodles/moodle_icon_endurance.png"),
        isActive = false,
        position = -64,
        targetPosition = 0
    },
}

function PLUGIN:SetMoodleActive(moodleName, isActive)
    if self.moodles[moodleName] then
        self.moodles[moodleName].isActive = isActive
    end
end

ix.config.Add("warmthEnabled", false, "Whether or not the warmth system is enabled.", function(oldValue, newValue)
    if (newValue) then
        hook.Run("WarmthEnabled")
    else
        hook.Run("WarmthDisabled")
    end
end, {category = "warmth"})


ix.config.Add("warmthDamage", 2, "How much damage to take per tick when at 0 warmth.", nil, {
    data = {min = 0, max = 100},
    category = "warmth"
})

ix.config.Add("warmthRecoverScale", 0.25, "How much warmth you regain by being indoors. This is a multiplier of warmthLossTime.", nil, {
    data = {min = 0.01, max = 2, decimals = 2},
    category = "warmth"
})

ix.config.Add("warmthFireScale", 2, "How much warmth you regain by being near an entity that produces warmth (i.e a fire).", nil, {
    data = {min = 0.01, max = 10, decimals = 2},
    category = "warmth"
})

ix.config.Add("warmthLossTime", 5, "How many minutes it takes for a player to lose all their warmth.", nil, {
    data = {min = 0.1, max = 1440, decimals = 1},
    category = "warmth"
})

ix.config.Add("warmthTickTime", 5, "How many seconds to wait before calculating each player's warmth. You should usually leave this as the default.", function(oldValue, newValue)
    if (SERVER) then
        PLUGIN:SetupAllTimers()
    end
end, {data = {min = 1, max = 60}, category = "warmth"})

ix.config.Add("warmthKill", false, "Whether or not to kill characters if they reach zero warmth.", nil, {
    category = "warmth"
})

ix.config.Add("warmthRainScale", 5, "The scale at which warmth decreases when it's raining.", nil, {
    data = {min = 0.01, max = 10, decimals = 2},
    category = "warmth"
})

ix.config.Add("sanityDecayRate", 0.5, "Rate at which sanity decays over time.", nil, {
    data = {min = 0.1, max = 5, decimals = 1},
    category = "sanity"
})

ix.config.Add("sanityRecoveryRate", 0.3, "Rate at which sanity is recovered near positive entities like TVs or radios.", nil, {
    data = {min = 0.1, max = 5, decimals = 1},
    category = "sanity"
})

ix.config.Add("sanityZoneDecayRate", 1.0, "Additional decay rate when in high-stress zones.", nil, {
    data = {min = 0.1, max = 5, decimals = 1},
    category = "sanity"
})

ix.config.Add("staminaDrain", 1, "How much stamina to drain per tick (every quarter second). This is calculated before attribute reduction.", nil, {
    data = {min = 0, max = 10, decimals = 2},
    category = "characters"
})

ix.config.Add("staminaRegeneration", 1.75, "How much stamina to regain per tick (every quarter second).", nil, {
    data = {min = 0, max = 10, decimals = 2},
    category = "characters"
})

ix.config.Add("staminaCrouchRegeneration", 2, "How much stamina to regain per tick (every quarter second) while crouching.", nil, {
    data = {min = 0, max = 10, decimals = 2},
    category = "characters"
})

ix.config.Add("punchStamina", 10, "How much stamina punches use up.", nil, {
    data = {min = 0, max = 100},
    category = "characters"
})

ix.command.Add("CheckSanity", {
    description = "Displays your current sanity level.",
    adminOnly = false,  -- Set to true if you want only admins to use this command.
    OnRun = function(self, client)
        local char = client:GetCharacter()
        if char then
            local sanity = char:GetSanity()
            client:ChatPrint("Current Sanity Level: " .. sanity)
        else
            client:ChatPrint("You do not have a character currently loaded.")
        end
    end
})

ix.command.Add("CheckSickness", {
    description = "Displays your current sickness level.",
    adminOnly = false,  -- Set to true if you want only admins to use this command.
    OnRun = function(self, client)
        local char = client:GetCharacter()
        if char then
            local sickness = char:GetData("sickness", 0)
            client:ChatPrint("Current Sickness Level: " .. sickness)
        else
            client:ChatPrint("You do not have a character currently loaded.")
        end
    end
})

ix.command.Add("CheckHunger", {
    description = "Displays your current Hunger level.",
    adminOnly = false,  -- Set to true if you want only admins to use this command.
    OnRun = function(self, client)
        local char = client:GetCharacter()
        if char then
            local hunger = char:GetHunger()
            client:ChatPrint("Current Hunger Level: " .. hunger)
        else
            client:ChatPrint("You do not have a character currently loaded.")
        end
    end
})

ix.command.Add("CheckStress", {
    description = "Displays your current Stress meter.",
    adminOnly = false,  -- Set to true if you want only admins to use this command.
    OnRun = function(self, client)
        local char = client:GetCharacter()
        if char then
            local stress = char:GetStress()
            client:ChatPrint("Current Stress Level: " .. stress)
        else
            client:ChatPrint("You do not have a character currently loaded.")
        end
    end
})

ix.char.RegisterVar("warmth", {
    field = "warmth",
    fieldType = ix.type.number,
    default = 100,
    isLocal = true,
    bNoDisplay = true
})

function PLUGIN:InitializedConfig()
    if (ix.config.Get("warmthEnabled")) then
        hook.Run("WarmthEnabled")
    else
        hook.Run("WarmthDisabled")
    end
end

function PLUGIN:GetTemperature()
    return StormFox and StormFox.GetTemperature() or ix.config.Get("warmthTemp", 20)
end

function PLUGIN:PlayerIsInside(client)
    if (StormFox) then
        return !StormFox.IsEntityOutside(client)
    end

    local trace = {
        start = client:GetPos(),
        endpos = client:GetPos() + Vector(0, 0, 524288),
        mask = MASK_SHOT,
        filter = client
    }

    trace = util.TraceLine(trace)
    return !trace.HitSky
end

local HumanMalePainSounds = {} -- all pain sounds for each limb
HumanMalePainSounds[HITGROUP_GENERIC] = {Sound("vo/npc/male01/pain01.wav"), Sound("vo/npc/male01/pain02.wav"), Sound("vo/npc/male01/pain03.wav"), Sound("vo/npc/male01/pain04.wav"), Sound("vo/npc/male01/pain05.wav"), Sound("vo/npc/male01/pain06.wav"), Sound("vo/episode_1/npc/male01/cit_pain06.wav"), Sound("vo/episode_1/npc/male01/cit_pain07.wav")}
HumanMalePainSounds[HITGROUP_HEAD] = {Sound("vo/npc/male01/moan02.wav"), Sound("vo/npc/male01/moan04.wav"), Sound("vo/npc/male01/pain07.wav")}
HumanMalePainSounds[HITGROUP_CHEST] = {Sound("vo/npc/male01/imhurt01.wav"), Sound("vo/npc/male01/imhurt02.wav"), Sound("vo/episode_1/npc/male01/cit_pain06.wav"), Sound("vo/episode_1/npc/male01/cit_pain07.wav")}
HumanMalePainSounds[HITGROUP_STOMACH] = {Sound("vo/npc/male01/hitingut01.wav"), Sound("vo/npc/male01/hitingut02.wav"), Sound("vo/npc/male01/mygut02.wav"), Sound("vo/episode_1/npc/male01/cit_pain06.wav"), Sound("vo/episode_1/npc/male01/cit_pain07.wav")}
HumanMalePainSounds[HITGROUP_LEFTARM] = {Sound("vo/npc/male01/myarm01.wav"), Sound("vo/npc/male01/myarm02.wav")}
HumanMalePainSounds[HITGROUP_RIGHTARM] = {Sound("vo/npc/male01/myarm01.wav"), Sound("vo/npc/male01/myarm02.wav")}
HumanMalePainSounds[HITGROUP_LEFTLEG] = {Sound("vo/npc/male01/myleg01.wav"), Sound("vo/npc/male01/myleg02.wav")}
HumanMalePainSounds[HITGROUP_RIGHTLEG] = {Sound("vo/npc/male01/myleg01.wav"), Sound("vo/npc/male01/myleg02.wav")}
local HumanFemalePainSounds = {}
HumanFemalePainSounds[HITGROUP_GENERIC] = {Sound("vo/npc/female01/pain01.wav"), Sound("vo/npc/female01/pain02.wav"), Sound("vo/npc/female01/pain03.wav"), Sound("vo/npc/female01/pain04.wav"), Sound("vo/npc/female01/pain05.wav"), Sound("vo/npc/female01/pain06.wav")}
HumanFemalePainSounds[HITGROUP_HEAD] = {Sound("vo/npc/female01/moan02.wav"), Sound("vo/npc/female01/moan04.wav"), Sound("vo/npc/female01/pain07.wav")}
HumanFemalePainSounds[HITGROUP_CHEST] = {Sound("vo/npc/female01/imhurt01.wav"), Sound("vo/npc/female01/imhurt02.wav")}
HumanFemalePainSounds[HITGROUP_STOMACH] = {Sound("vo/npc/female01/hitingut01.wav"), Sound("vo/npc/female01/hitingut02.wav"), Sound("vo/npc/female01/mygut02.wav")}
HumanFemalePainSounds[HITGROUP_LEFTARM] = {Sound("vo/npc/female01/myarm01.wav"), Sound("vo/npc/female01/myarm02.wav")}
HumanFemalePainSounds[HITGROUP_RIGHTARM] = {Sound("vo/npc/female01/myarm01.wav"), Sound("vo/npc/female01/myarm02.wav")}
HumanFemalePainSounds[HITGROUP_LEFTLEG] = {Sound("vo/npc/female01/myleg01.wav"), Sound("vo/npc/female01/myleg02.wav")}
HumanFemalePainSounds[HITGROUP_RIGHTLEG] = {Sound("vo/npc/female01/myleg01.wav"), Sound("vo/npc/female01/myleg02.wav")}
local CPPainSounds = {}
CPPainSounds[HITGROUP_GENERIC] = {Sound("npc/metropolice/pain1.wav"), Sound("npc/metropolice/pain2.wav"), Sound("npc/metropolice/pain3.wav"), Sound("npc/metropolice/pain4.wav")}
CPPainSounds[HITGROUP_GEAR] = {Sound("npc/metropolice/pain1.wav"), Sound("npc/metropolice/pain2.wav"), Sound("npc/metropolice/pain3.wav"), Sound("npc/metropolice/pain4.wav")}

function PLUGIN:ScalePlayerDamage(ply, hitgroup, dmginfo)
    if SERVER and ply:Armor() <= 10 then
        local char = ply:GetCharacter()
        if not char then return end
        local lastSoundTime = ply:GetNWFloat("LastPainSoundTime", 0) -- Sound cooldown handling
        local soundCooldown = 1.5
        local function playPainSound()
            if CurTime() >= lastSoundTime + soundCooldown then
                local soundTable = ply:IsFemale() and HumanFemalePainSounds[hitgroup] or HumanMalePainSounds[hitgroup]
                local sound = table.Random(soundTable)
                ply:EmitSound(sound, 80)
                ply:SetNWFloat("LastPainSoundTime", CurTime())
            end
        end

        local hitgroupActions = {
            [HITGROUP_HEAD] = function(ply, char, dmginfo)
                local fadeDuration = 5
                local fadeColor = Color(255, 0, 0, 255)
        
                if ply.ixHelmetEquipped == true then
                    -- Helmet equipped: apply the preexisting stats
                    dmginfo:ScaleDamage(2.5)
                else
                    -- Helmet not equipped: apply the new damage scale
                    dmginfo:ScaleDamage(5)
                end
        
                ply:ScreenFade(SCREENFADE.IN, fadeColor, fadeDuration, 0)
        
                -- Play pain sound if the player is not Combine
                if not ply:IsCombine() then
                    playPainSound()
                end
            end,
            [HITGROUP_CHEST] = function(ply, char)
                if char:GetData("ixChestHit", false) == false then
                    if not ply:IsCombine() then playPainSound() end
                    char:SetData("ixChestHit", true)
                    timer.Simple(1, function() char:SetData("ixChestHit", false) end)
                end
            end,
            [HITGROUP_STOMACH] = function(ply, char)
                if char:GetData("ixGutHit", false) == false then
                    if not ply:IsCombine() then playPainSound() end
                    char:SetData("ixGutHit", true)
                    timer.Simple(1, function() char:SetData("ixGutHit", false) end)
                end
            end,
            [HITGROUP_LEFTLEG] = function(ply, char)
                if char:GetData("ixBrokenLegs", false) == false then
                    ply:ChatNotify("I've been shot in my left leg!")
                    if not ply:IsCombine() then playPainSound() end
                    char:SetData("ixBrokenLegs", true)
                    timer.Simple(65, function() char:SetData("ixBrokenLegs", false) end)
                end
            end,
            [HITGROUP_RIGHTLEG] = function(ply, char)
                if char:GetData("ixBrokenLegs", false) == false then
                    ply:ChatNotify("I've been shot in my right leg!")
                    if not ply:IsCombine() then playPainSound() end
                    char:SetData("ixBrokenLegs", true)
                    timer.Simple(65, function() char:SetData("ixBrokenLegs", false) end)
                end
            end,
            [HITGROUP_LEFTARM] = function(ply, char)
                if char:GetData("ixBrokenLeftArm", false) == false then
                    if not ply:IsCombine() then playPainSound() end
                    char:SetData("ixBrokenLeftArm", true)
                    if char:GetData("ixBrokenLeftArm", true) then ply:ViewPunch(Angle(math.Rand(-10, -5), math.Rand(-10, -5), math.Rand(-10, -5))) end
                    timer.Simple(10, function() char:SetData("ixBrokenLeftArm", false) end)
                end
            end,
            [HITGROUP_RIGHTARM] = function(ply, char)
                if char:GetData("ixBrokenRightArm", false) == false then
                    if not ply:IsCombine() then playPainSound() end
                    char:SetData("ixBrokenRightArm", true)
                    if char:GetData("ixBrokenRightArm", true) then ply:ViewPunch(Angle(math.Rand(10, 5), math.Rand(10, 5), math.Rand(10, 5))) end
                    timer.Simple(10, function() char:SetData("ixBrokenRightArm", false) end)
                end
            end,
        }
        
        local action = hitgroupActions[hitgroup]
        if action then
            action(ply, char, dmginfo)
        end
    end
end

local humanmaledeathSounds = {Sound("vo/npc/male01/pain07.wav"), Sound("vo/npc/male01/pain08.wav"), Sound("vo/npc/male01/pain09.wav")}
local humanfemaledeathSounds = {Sound("vo/npc/female01/pain07.wav"), Sound("vo/npc/female01/pain08.wav"), Sound("vo/npc/female01/pain09.wav")}
local CPdeathSounds = {Sound("npc/metropolice/die" .. math.random(1, 4) .. ".wav"), Sound("npc/metropolice/fire_scream" .. math.random(1, 3) .. ".wav")}

function PLUGIN:PlayerDeath(ply, inf, attacker)
    if ply:IsPlayer() and (ply:Team() == FACTION_CITIZEN) or (ply:Team() == FACTION_CA) or (ply:Team() == FACTION_VORTIGAUNT) then
        local char = ply:GetCharacter()
        if not ply:IsFemale() then
            ply:EmitSound(humanmaledeathSounds[math.random(1, #humanmaledeathSounds)])
        elseif ply:IsFemale() then
            ply:EmitSound(humanfemaledeathSounds[math.random(1, #humanfemaledeathSounds)])
        end

        ix.chat.Send(ply, "me", "'s body goes limp and looks to be dead.")
        ply:SetAction(false)
        ply:ShouldSetRagdolled(false)
        ply:SetNWBool("Healed", false)
        ply:SetNWBool("Ragdolled", false)
        char:SetData("ixBrokenLegs", false)
        ply:SetNWBool("Dying", false)
        ply:StopSound("player/heartbeat1.wav")
        ply:Freeze(false)
        ply.ixJailState = nil
    elseif ply:IsPlayer() and ply:Team() == FACTION_CCA then
        local char = ply:GetCharacter()
        ply:EmitSound(CPdeathSounds[math.random(1, #CPdeathSounds)])
        ix.chat.Send(ply, "me", "'s body goes limp and looks to be dead.")
        ply:SetAction(false)
        ply:ShouldSetRagdolled(false)
        ply:SetNWBool("Healed", false)
        ply:SetNWBool("Ragdolled", false)
        char:SetData("ixBrokenLegs", false)
        ply:SetNWBool("Dying", false)
        ply:StopSound("player/heartbeat1.wav")
        ply:Freeze(false)
        ply.ixJailState = nil
    end
end

ix.command.Add("draw", {
    description = 'Pull a playing card from the deck.',
    OnRun = function(self, client)
        local inventory = client:GetCharacter():GetInventory()
        if (!inventory:HasItem("playingcards")) then
            client:Notify("You do not have a playing cards deck.")
            client:EmitSound("physics/cardboard/cardboard_box_impact_bullet1.wav")
            return
        end

        local family = {"Ace", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Jack", "Queen", "King",}
        local fam2 = {"Hearts", "Diamonds", "Clubs", "Spades",}
        
        local msg = "draws " ..table.Random(family).. " of " ..table.Random(fam2)
        
        ix.chat.Send(client, "me", msg)
    end
})

--- HUNGER SYSTEM


ix.config.Add("hungerTime", 120, "How many seconds between each time a player's needs are calculated", nil, {
    data = {
        min = 1,
        max = 600
    },
    category = "Hunger System"
})


ix.config.Add("sickTime", 120, "How many seconds between each time a player's sickness are calculated", nil, {
    data = {
        min = 1,
        max = 600
    },
    category = "Sickness System"
})

ix.config.Add("sanityTime", 120, "How many seconds between each time a player's sanity is calculated", nil, {
    data = {
        min = 1,
        max = 600
    },
    category = "Sanity System"
})

ix.char.RegisterVar("hunger", {
    field = "hunger",
    fieldType = ix.type.number,
    default = 0,
    isLocal = true,
    bNoDisplay = true
})

ix.char.RegisterVar("sickness", {
    fieldType = ix.type.number,
    default = 0,
    isLocal = true,
    bNoDisplay = true
})

ix.command.Add("CharSetHunger", {
    description = "Set character's hunger",
    privilege = "Manage Hunger System",
    arguments = {ix.type.character, bit.bor(ix.type.number, ix.type.optional)},
    OnRun = function(self, ply, char, level)
        if not ply:IsAdmin() then
            ply:Notify("Nice try.")

            return false
        end

        char:SetHunger(level or 0)
        ply:Notify(char:GetName() .. "'s hunger was set to " .. (level or 0))
    end
})

ix.command.Add("CharSetSickness", {
    description = "Set character's sickness",
    privilege = "Manage Sickness System",
    arguments = {ix.type.character, bit.bor(ix.type.number, ix.type.optional)},
    OnRun = function(self, ply, char, level)
        if not ply:IsAdmin() then
            return false
        end

        char:SetData("sickness", level or 0)
        ply:Notify(char:GetName() .. "'s sickness was set to " .. (level or 0))
    end
})

ix.command.Add("CharSetSanity", {
    description = "Set character's sanity",
    privilege = "Manage Sanity System",
    arguments = {ix.type.character, bit.bor(ix.type.number, ix.type.optional)},
    OnRun = function(self, ply, char, level)
        if not ply:IsAdmin() then
            return false
        end

        char:SetData("sanity", level or 0)
        ply:Notify(char:GetName() .. "'s sanity was set to " .. (level or 0))
    end
})

ix.config.Add("enableAlcoholFallover", true, "Enable fall to the ground on the certain level of intoxication.", nil, {
    category = "Alcohol"
})

ix.config.Add("alcoholFallover", 5, "The level of intoxication on which player fall to the ground.", nil, {
    data = {min = 1, max = 50},
    category = "Alcohol"
})

do
    ix.char.RegisterVar("DrunkEffect", {
        field = "DrunkEffect",
        fieldType = ix.type.number,
        default = 0,
        bNoDisplay = true
    })

    ix.char.RegisterVar("DrunkEffectTime", {
        field = "DrunkEffectTime",
        fieldType = ix.type.number,
        default = 0,
        bNoDisplay = true
    })
end

ix.command.Add("AddDrunkEffect", {
    description = "Adds a drunk effect to character.",
    adminOnly = true,
    arguments = {
        ix.type.character,
        ix.type.number,
        ix.type.number,
    },
    OnRun = function(self, client, target, amount, duration)
        target:GetPlayer():AddDrunkEffect(amount, duration)
    end
})

ix.command.Add("RemoveDrunkEffect", {
    description = "Removes drunk effect from character.",
    adminOnly = true,
    arguments = {
        ix.type.character,
    },
    OnRun = function(self, client, target)
        target:GetPlayer():RemoveDrunkEffect()
    end
})

--- HUNGER SYSTEM ENDS HERE

local function CalcStaminaChange(client)
    local character = client:GetCharacter()

    if (!character or client:GetMoveType() == MOVETYPE_NOCLIP) then
        return 0
    end

    local runSpeed

    if (SERVER) then
        runSpeed = ix.config.Get("runSpeed") + character:GetAttribute("stm", 0)

        if (client:WaterLevel() > 1) then
            runSpeed = runSpeed * 0.775
        end
    end

    local walkSpeed = ix.config.Get("walkSpeed")
    local maxAttributes = ix.config.Get("maxAttributes", 100)
    local offset

    if (client:KeyDown(IN_SPEED) and client:GetVelocity():LengthSqr() >= (walkSpeed * walkSpeed)) then
        offset = -ix.config.Get("staminaDrain", 1) + math.min(character:GetAttribute("end", 0), maxAttributes) / 100
    else
        offset = client:Crouching() and ix.config.Get("staminaCrouchRegeneration", 2) or ix.config.Get("staminaRegeneration", 1.75)

        -- Increase stamina recovery if IsActing is true
        if client:GetNWBool("IsActing", false) then
            offset = offset * 1.5  -- 50% better recovery when acting
        end
    end

    -- Adjust stamina based on weakness
    local weakness = character:GetData("weakness", 0)
    local weaknessFactor = 1

    if weakness >= 50 then
        weaknessFactor = 0.5 -- 50% stamina when weakness is 50 or higher
    elseif weakness >= 25 then
        weaknessFactor = 0.75 -- 75% stamina when weakness is 25 or higher
    end

    offset = offset * weaknessFactor

    offset = hook.Run("AdjustStaminaOffset", client, offset) or offset

    if (CLIENT) then
        return offset -- for the client we need to return the estimated stamina change
    else
        local current = client:GetLocalVar("stm", 0)
        local value = math.Clamp(current + offset, 0, 100)

        if (current != value) then
            client:SetLocalVar("stm", value)

            if (value == 0 and !client:GetNetVar("brth", false)) then
                client:SetRunSpeed(walkSpeed)
                client:SetNetVar("brth", true)

                character:UpdateAttrib("end", 0.1)
                character:UpdateAttrib("stm", 0.01)

                hook.Run("PlayerStaminaLost", client)
            elseif (value >= 50 and client:GetNetVar("brth", false)) then
                client:SetRunSpeed(runSpeed)
                client:SetNetVar("brth", nil)

                hook.Run("PlayerStaminaGained", client)
            end
        end
    end
end

if (SERVER) then
    function PLUGIN:PostPlayerLoadout(client)
        local uniqueID = "ixStam" .. client:SteamID()

        timer.Create(uniqueID, 0.25, 0, function()
            if (!IsValid(client)) then
                timer.Remove(uniqueID)
                return
            end

            CalcStaminaChange(client)
        end)
    end

    function PLUGIN:CharacterPreSave(character)
        local client = character:GetPlayer()

        if (IsValid(client)) then
            character:SetData("stamina", client:GetLocalVar("stm", 0))
        end
    end

    function PLUGIN:PlayerLoadedCharacter(client, character)
        timer.Simple(0.25, function()
            client:SetLocalVar("stm", character:GetData("stamina", 100))
        end)
    end

else

    local predictedStamina = 100

    function PLUGIN:Think()
        local offset = CalcStaminaChange(LocalPlayer())
        -- the server check it every 0.25 sec, here we check it every [FrameTime()] seconds
        offset = math.Remap(FrameTime(), 0, 0.25, 0, offset)

        if (offset != 0) then
            predictedStamina = math.Clamp(predictedStamina + offset, 0, 100)
        end
    end

    function PLUGIN:OnLocalVarSet(key, var)
        if (key != "stm") then return end
        if (math.abs(predictedStamina - var) > 5) then
            predictedStamina = var
        end
    end
end