local PLUGIN = PLUGIN or {}
local moodleSize = 64 -- Add more moodles here as needed
local screenMargin = 10
local math_random = math.random
local client = LocalPlayer()
function PLUGIN:UpdateMoodlePositions()
    local activeCount = 0
    for _, moodle in pairs(self.moodles) do
        if moodle.isActive then
            moodle.targetPosition = ScrW() - screenMargin - (moodleSize + screenMargin) * (activeCount + 1)
            activeCount = activeCount + 1
        else
            moodle.targetPosition = ScrW() + moodleSize -- Off-screen
        end
    end
end

function PLUGIN:HUDPaint()
    self:UpdateMoodlePositions()
    for _, moodle in pairs(self.moodles) do
        moodle.position = Lerp(0.05, moodle.position, moodle.targetPosition) -- Animate moodle position
        if moodle.isActive then -- Draw moodle if active
            surface.SetMaterial(moodle.material)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(moodle.position, screenMargin, moodleSize, moodleSize)
        end
    end
end

hook.Add("HUDPaint", "MoodleHUDPaint", function() PLUGIN:HUDPaint() end)
function PLUGIN:RenderScreenspaceEffects()
    local client = LocalPlayer()
    if client:IsCombine() then return end

    local character = client:GetCharacter()
    if not character then return end

    local drunkEffect = character:GetDrunkEffect()
    local sicknessLevel = character:GetData("sickness", 0)
    local hungerLevel = character:GetHunger() or 100
    local stressLevel = character:GetStress() or 0
    local sanity = character:GetSanity() / 100

    -- Drunk effects
    if drunkEffect and drunkEffect > 0 then
        DrawMotionBlur(0.075, drunkEffect, 0.025)
    end

    -- Water effect
    if character:GetData("Water", false) then
        DrawSharpen(5, 5)
    end

    -- Blur for sickness
    local blurStrength = 0
    if sicknessLevel >= 89 then
        blurStrength = blurStrength + 0.4
        DrawColorModify({
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = 0,
            ["$pp_colour_contrast"] = 1,
            ["$pp_colour_colour"] = 0,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0
        })
    elseif sicknessLevel > 49 then
        blurStrength = blurStrength + 0.3
    elseif sicknessLevel > 14 then
        blurStrength = blurStrength + 0.1
    end

    -- Blur for hunger
    if hungerLevel < 40 then
        local hungerBlur = Lerp(1 - (hungerLevel / 40), 0.1, 0.5)
        blurStrength = blurStrength + hungerBlur
    end

    -- Apply saturation changes based on sanity AND stress
    local colMod = {}
    colMod["$pp_colour_colour"] = 0.8

    if sanity < 20 then
        colMod["$pp_colour_colour"] = 0.45
    elseif sanity < 40 then
        colMod["$pp_colour_colour"] = 0.6
    elseif sanity < 60 then
        colMod["$pp_colour_colour"] = 0.7
    end

if stressLevel > 50 then
    local stressAmount = math.Clamp((stressLevel - 50) / 50, 0, 1) -- Scale from 0 to 1 between 50-100
    local stressBlur = Lerp(stressAmount, 0.5, 5.2) -- Increased blur range: 0.3 to 1.2
    blurStrength = blurStrength + stressBlur
end

    -- Stress effect: screen shake
    if stressLevel > 74 then
        
    -- Screen shake cooldown (every 0.5 seconds)
    self.nextStressShake = self.nextStressShake or 0
    if self.nextStressShake < CurTime() then
        util.ScreenShake(client:GetPos(), 1, 5, 0.75, 200)
        self.nextStressShake = CurTime() + 0.2
    end

    -- Play heartbeat loop
    if not self.heartbeatSound then
        self.heartbeatSound = CreateSound(client, "player/heartbeat1.wav")
        self.heartbeatSound:SetSoundLevel(0)
        self.heartbeatSound:Play()
    elseif not self.heartbeatSound:IsPlaying() then
        self.heartbeatSound:Play()
    end
else
    -- Stop heartbeat when stress drops
    if self.heartbeatSound and self.heartbeatSound:IsPlaying() then
        self.heartbeatSound:Stop()
    end
end

    if blurStrength > 0 then
        DrawMotionBlur(0.1, blurStrength, 0.01)
    else
        DrawMotionBlur(0, 0, 0)
    end

    DrawColorModify(colMod)
end

function PLUGIN:GetWarmthText(amount)
    if amount > 75 then
        return L("warmthWarm")
    elseif amount > 50 then
        return L("warmthChilly")
    elseif amount > 25 then
        return L("warmthCold")
    else
        return L("warmthFreezing")
    end
end

function PLUGIN:WarmthEnabled()
    ix.bar.Add(function()
        local character = LocalPlayer():GetCharacter()
        if character then
            local warmth = character:GetWarmth()
            return warmth / 100, self:GetWarmthText(warmth)
        end
        return false
    end, Color(200, 50, 40), nil, "warmth")
end

function PLUGIN:WarmthDisabled()
    ix.bar.Remove("warmth")
end

function PLUGIN:StopEffects()
    DrawMotionBlur(0, 0, 0) -- Reset motion blur to none
    DrawColorModify({
        ["$pp_colour_addr"] = 0, -- Reset color modifications if any
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    })

    if PLUGIN.SetMoodleActive then -- Reset all moodles
        PLUGIN:SetMoodleActive("sick", false)
        PLUGIN:SetMoodleActive("moresick", false)
        PLUGIN:SetMoodleActive("bored", false)
        PLUGIN:SetMoodleActive("unhappy", false)
        PLUGIN:SetMoodleActive("panic", false)
        PLUGIN:SetMoodleActive("weak", false)
        PLUGIN:SetMoodleActive("moreweak", false)
        PLUGIN:SetMoodleActive("stam", false)
        PLUGIN:SetMoodleActive("stressed", false)
        PLUGIN:SetMoodleActive("hungry", false)
        PLUGIN:SetMoodleActive("terrified", false)
    end

    local char = LocalPlayer():GetCharacter() -- Reset specific data on the character if needed
    if char and IsValid(char) then
        char:SetData("sickness", 0)
        char:SetData("sicknessType", "none")
        char:SetData("IsPanicked", false)
        char:SetData("sickness_immunity", nil) -- Reset immunity if applicable
    end
end

hook.Add("PlayerDeath", "StopEffects", function(ply) if ply == LocalPlayer() then PLUGIN:StopEffects() end end)
net.Receive("TriggerScreenShake", function()
    local duration = net.ReadFloat()
    local intensity = net.ReadFloat()
    local radius = net.ReadFloat()
    local viewpunchVec = net.ReadVector()
    local viewpunchAng = Angle(viewpunchVec.x, viewpunchVec.y, viewpunchVec.z) -- Convert the Vector to an Angle
    LocalPlayer():SetViewPunchAngles(viewpunchAng)
    util.ScreenShake(LocalPlayer():GetPos(), intensity, 5, duration, radius)
end)

local wasStamActive = false -- Track if stamina moodle was previously active
net.Receive("MoodlesIcons", function()
    local char = LocalPlayer():GetCharacter()
    if not char then return end
    if char:GetHunger() <= 49 then
        PLUGIN:SetMoodleActive("hungry", true)
    else
        PLUGIN:SetMoodleActive("hungry", false)
    end

    local sicknessLevel = char:GetData("sickness", 0)
    if sicknessLevel > 49 then
        PLUGIN:SetMoodleActive("moresick", true)
        PLUGIN:SetMoodleActive("sick", false)
    elseif sicknessLevel > 14 then
        PLUGIN:SetMoodleActive("sick", true)
        PLUGIN:SetMoodleActive("moresick", false)
    else
        PLUGIN:SetMoodleActive("sick", false)
        PLUGIN:SetMoodleActive("moresick", false)
    end

    local currentSanity = char:GetSanity()
    PLUGIN:SetMoodleActive("bored", false) -- Reset all moodles first
    PLUGIN:SetMoodleActive("unhappy", false)
    PLUGIN:SetMoodleActive("panic", false)
    if currentSanity <= 14 then -- Check conditions and set the highest priority moodle active
        PLUGIN:SetMoodleActive("panic", true) -- Most severe condition
    elseif currentSanity <= 44 then
        PLUGIN:SetMoodleActive("unhappy", true) -- Moderate condition
    elseif currentSanity <= 64 then
        PLUGIN:SetMoodleActive("bored", true) -- Least severe condition
    end

    local currentStress = char:GetStress()
    PLUGIN:SetMoodleActive("stressed", false) -- Reset all moodles first
    PLUGIN:SetMoodleActive("terrified", false)
    if currentStress > 50 then -- Check conditions and set the highest priority moodle active
        PLUGIN:SetMoodleActive("terrified", true)
    elseif currentStress > 25 then
        PLUGIN:SetMoodleActive("stressed", true)
    end

    local weakness = char:GetData("weakness", 0)
    PLUGIN:SetMoodleActive("weak", false)
    PLUGIN:SetMoodleActive("moreweak", false)
    if weakness > 50 then
        PLUGIN:SetMoodleActive("moreweak", true)
    elseif weakness > 25 then
        PLUGIN:SetMoodleActive("weak", true)
    end

    local stamina = LocalPlayer():GetLocalVar("stm", 100) -- Track stamina
    PLUGIN:SetMoodleActive("stam", false)
    if stamina < 25 then
        PLUGIN:SetMoodleActive("stam", true)
        if not wasStamActive then -- **Play sound if stamina just dropped below threshold**
            surface.PlaySound("citizensounds/outofbreath.wav")
            wasStamActive = true -- Mark as active
        end
    else
        wasStamActive = false -- Reset when stamina recovers
    end
end)

net.Receive("TriggerPukeEffect", function()
    local ply = net.ReadEntity()
    if IsValid(ply) then
        local mouthAttachment = ply:LookupAttachment("mouth")
        if mouthAttachment then
            local attachmentInfo = ply:GetAttachment(mouthAttachment)
            if attachmentInfo then
                local pos = attachmentInfo.Pos
                local ang = attachmentInfo.Ang
                local effectData = EffectData()
                effectData:SetOrigin(pos)
                effectData:SetAngles(ang)
                effectData:SetScale(5)
                effectData:SetColor(0)
                effectData:SetFlags(3)
                util.Effect("bloodspray", effectData)
            end
        end
    end
end)

local currentSanityound = nil
net.Receive("PlayClientSound", function()
    local soundFile = net.ReadString()
    print("Received request to play sound:", soundFile) -- Debug output
    if currentSanityound then
        currentSanityound:Stop()
        print("Stopping current sound") -- Debug output
    end

    currentSanityound = CreateSound(LocalPlayer(), soundFile)
    if currentSanityound then
        currentSanityound:Play()
        print("Playing new sound") -- Debug output
    else
        print("Failed to create sound with file:", soundFile) -- Debug output
    end
end)

net.Receive("StopClientSound", function()
    if currentSanityound then
        currentSanityound:Stop()
        currentSanityound = nil
        print("Stopped sound via network message") -- Debug output
    end
end)

hook.Add("PlayerDeath", "StopSoundOnDeath", function(ply)
    if ply == LocalPlayer() and currentSanityound then
        currentSanityound:Stop()
        currentSanityound = nil
        print("Sound stopped on death") -- Debug output
    end
end)


-- Enhanced Helix Sanity System with Begotten-style Visual Effects
-- Bonemerged clones with proper animations; parent player is hard-hidden to prevent overlap

------------------------------------------------------------
-- Tuning
------------------------------------------------------------
local sanity_threshold   = 40
local max_range_sqr      = 900 * 900
local only_others        = true

local SANITY_VERY_LOW    = 20
local SANITY_LOW         = 40
local SANITY_MEDIUM      = 50

-- Debug toggle: 0 = off, 1 = on
CreateClientConVar("ix_sanity_debug", "0", true, false, "Enable debug prints for sanity system")

------------------------------------------------------------
-- State
------------------------------------------------------------
local hall               = hall or {}               -- [ply] = { cs=ClientsideModel }
local insanitySkeletons  = insanitySkeletons or {}  -- [entindex] = skeleton CS entity
local nextSanitySound    = 0
local frameTime          = 0
local contrastAdd        = 0

local medSanitySounds = {
    "physics/wood/wood_strain2.wav",
    "physics/wood/wood_strain3.wav",
    "physics/wood/wood_strain4.wav",
    "physics/wood/wood_strain5.wav"
}

local lowSanitySounds = {
    "ambient/wind/wind_snippet1.wav",
    "ambient/wind/wind_snippet2.wav",
    "ambient/wind/wind_snippet3.wav"
}


-- sprite for eye glow
local matEyeGlow = Material("sprites/light_ignorez")

------------------------------------------------------------
-- Utils
------------------------------------------------------------
local function dprint(...)
    if GetConVar("ix_sanity_debug"):GetBool() then
        print("[SANITY]", ...)
    end
end

local function GetPlayerSanity()
    local lp = LocalPlayer()
    if not IsValid(lp) then return 100 end
    local character = lp.GetCharacter and lp:GetCharacter()
    if not character or not character.GetSanity then return 100 end
    local s = character:GetSanity()
    if s == nil then return 100 end
    return s
end

local function apply_headless(cs)
    if not IsValid(cs) then return end
    local b = cs:LookupBone("ValveBiped.Bip01_Head1") or cs:LookupBone("head") or cs:LookupBone("Head")
    if b then
        cs:ManipulateBoneScale(b, Vector(0, 0, 0))
    end
end

local function make_cs(p)
    if not IsValid(p) then return nil end

    local model_path = p:GetModel()
    if not util.IsValidModel(model_path) then
        dprint("Model not valid:", model_path)
        return nil
    end

    local cs = ClientsideModel(model_path, RENDERGROUP_OPAQUE)
    if not IsValid(cs) then
        dprint("Failed to create clientside model for:", p:Name())
        return nil
    end

    cs:SetNoDraw(false)
    -- Zombie stylization
    apply_headless(cs)
    cs:SetMaterial("models/flesh")               -- swap to your material if desired
    cs:SetColor(Color(100, 0, 0, 200))           -- reddish/transparent

    dprint("Created zombie model for:", p:Name())
    return cs
end

local function should_swap(p, lp, sanity)
    if not IsValid(p) then return false end
    if only_others and p == lp then return false end
    if not p:Alive() then return false end
    if lp:GetPos():DistToSqr(p:GetPos()) > max_range_sqr then return false end
    if (sanity or 100) > sanity_threshold then return false end
    return true
end

------------------------------------------------------------
-- Parent hide/show (hard, overlap-proof)
------------------------------------------------------------
local function hide_parent_player(p)
    if not IsValid(p) then return end
    if p._ixInsanityHidden then return end
    p._ixInsanityHidden = true
    p._ixInsanityOldMat = p:GetMaterial()
    p._ixInsanityOldRM  = p:GetRenderMode()

    -- make parent invisible but still "drawn" so bonemerged child renders
    p:SetRenderMode(RENDERMODE_NORMAL)
    p:SetMaterial("engine/occlusionproxy")
end

local function restore_parent_player(p)
    if not IsValid(p) then return end
    if not p._ixInsanityHidden then return end

    p:SetMaterial(p._ixInsanityOldMat or "")
    p:SetRenderMode(p._ixInsanityOldRM or RENDERMODE_NORMAL)

    p._ixInsanityHidden = nil
    p._ixInsanityOldMat = nil
    p._ixInsanityOldRM  = nil
end

------------------------------------------------------------
-- Add/remove zombie (BONEMERGED so animations follow Helix)
------------------------------------------------------------
local function add_zombie(p)
    if not IsValid(p) then return end
    local rec = hall[p]
    if rec and IsValid(rec.cs) then
        hide_parent_player(p) -- ensure hidden if something restored it
        return
    end

    local cs = make_cs(p)
    if not IsValid(cs) then return end

    -- Let the engine/Helix drive animations through the parent
    cs:SetParent(p)
    cs:AddEffects(EF_BONEMERGE)
    cs:AddEffects(EF_BONEMERGE_FASTCULL)
    cs:SetNoDraw(false)

    -- Mirror skin/bodygroups so clothing/state from Helix lines up
    cs:SetSkin(p:GetSkin() or 0)
    local bgs = p.GetBodyGroups and p:GetBodyGroups() or {}
    for _, bg in ipairs(bgs) do
        cs:SetBodygroup(bg.id, p:GetBodygroup(bg.id))
    end

    hall[p] = { cs = cs }

    -- hide the real player to prevent overlap; child will render
    hide_parent_player(p)
end

local function remove_zombie(p)
    local rec = hall[p]
    if not rec then
        -- still ensure parent is visible if no skeleton effect is active
        if not insanitySkeletons[p:EntIndex()] then
            restore_parent_player(p)
        end
        return
    end

    if IsValid(rec.cs) then rec.cs:Remove() end
    hall[p] = nil

    -- restore parent unless skeleton overlay is still active (which may fade alpha)
    if not insanitySkeletons[p:EntIndex()] then
        restore_parent_player(p)
    end
end

------------------------------------------------------------
-- Insanity skeletons (Begotten-style)
------------------------------------------------------------
local function CreateInsanitySkeleton(player)
    if not IsValid(player) then return nil end
    local idx = player:EntIndex()

    if IsValid(insanitySkeletons[idx]) then
        return insanitySkeletons[idx]
    end

    local skeletonEnt = ClientsideModel("models/skeleton/skeleton_whole.mdl", RENDERGROUP_OPAQUE)
    if not IsValid(skeletonEnt) then
        skeletonEnt = ClientsideModel("models/player/skeleton.mdl", RENDERGROUP_OPAQUE)
    end
    if not IsValid(skeletonEnt) then
        dprint("Could not create skeleton model for", player:Name())
        return nil
    end

    skeletonEnt:SetParent(player)
    skeletonEnt:SetRenderMode(RENDERMODE_TRANSALPHA)
    skeletonEnt:SetColor(Color(255, 255, 255, 0))
    skeletonEnt:AddEffects(EF_BONEMERGE)

    -- Ensure parent is hidden while skeleton fades in (also good with our hard hide)
    hide_parent_player(player)

    -- Also fade the parent alpha down (visual belt-and-suspenders)
    player:SetRenderMode(RENDERMODE_TRANSALPHA)
    player:SetColor(Color(255, 255, 255, 255))

    local reps = 0
    local tname = tostring(idx) .. "_skeletonDecay"
    timer.Create(tname, 0.01, 255, function()
        if not (IsValid(skeletonEnt) and IsValid(player)) then return end
        reps = reps + 1
        local aPlayer   = math.max(0, 255 - reps)
        local aSkeleton = math.min(255, reps)

        player:SetColor(Color(255, 255, 255, aPlayer))
        skeletonEnt:SetColor(Color(255, 255, 255, aSkeleton))
    end)

    insanitySkeletons[idx] = skeletonEnt
    return skeletonEnt
end

local function RemoveInsanitySkeleton(player)
    if not IsValid(player) then return end
    local idx = player:EntIndex()
    local skeleton = insanitySkeletons[idx]

    if IsValid(skeleton) then
        skeleton:Remove()
    end
    insanitySkeletons[idx] = nil

    -- restore parent material/alpha if no zombie clone remains
    if not (hall[player] and hall[player].cs and IsValid(hall[player].cs)) then
        restore_parent_player(player)
    end

    timer.Remove(tostring(idx) .. "_skeletonDecay")
    player:SetRenderMode(RENDERMODE_TRANSALPHA)
    player:SetColor(Color(255, 255, 255, 255))
end

------------------------------------------------------------
-- Frame & timing
------------------------------------------------------------
hook.Add("Think", "ix_insanity_framecount", function()
    frameTime = FrameTime()
end)

------------------------------------------------------------
-- Screenspace (color) effects
------------------------------------------------------------
hook.Add("RenderScreenspaceEffects", "ix_sanity_visual_effects", function()
    local sanity = GetPlayerSanity()

    if sanity <= SANITY_MEDIUM then
        contrastAdd = contrastAdd or 0

        local cm = {}
        cm["$pp_colour_addr"] = 0
        cm["$pp_colour_addg"] = 0 - contrastAdd
        cm["$pp_colour_addb"] = 0 - contrastAdd
        cm["$pp_colour_brightness"] = 0 + (contrastAdd * 0.1)
        cm["$pp_colour_contrast"]   = 1 + contrastAdd
        cm["$pp_colour_colour"]     = 1
        cm["$pp_colour_mulr"]       = 0
        cm["$pp_colour_mulg"]       = 0
        cm["$pp_colour_mulb"]       = 0

        DrawColorModify(cm)
        contrastAdd = math.Approach(contrastAdd, math.Remap(sanity, 0, SANITY_MEDIUM, 0.1, 0), frameTime * 0.25)
    else
        contrastAdd = math.Approach(contrastAdd, 0, frameTime * 0.5)
    end
end)

------------------------------------------------------------
-- World overlays (eyes, skeletons)
------------------------------------------------------------
hook.Add("PostDrawOpaqueRenderables", "ix_sanity_postdraw_effects", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end

    local sanity = GetPlayerSanity()

    -- Very low sanity: red eyes + skeleton + dynamic light on nearby humans
    if sanity <= SANITY_VERY_LOW then
        for _, v in ipairs(player.GetAll()) do
            if v == lp then continue end
            if not (IsValid(v) and v:IsPlayer() and v:Alive()) then continue end

            local mt = v:GetMoveType()
            if not (mt == MOVETYPE_WALK or mt == MOVETYPE_LADDER) then continue end

            local model = v:GetModel() or ""
            if not (string.find(model, "models/player", 1, true) or string.find(model, "humans", 1, true)) then continue end

            if lp:GetPos():DistToSqr(v:GetPos()) > (512 * 512) then continue end

            -- Eyes glow
            local headBone = v:LookupBone("ValveBiped.Bip01_Head1")
            if headBone then
                local eyesIndex = v:LookupAttachment("eyes")
                local eyesAttachment = eyesIndex and v:GetAttachment(eyesIndex)

                if eyesAttachment then
                    local forward   = eyesAttachment.Ang:Forward()
                    local right     = eyesAttachment.Ang:Right()
                    local eyePos    = eyesAttachment.Pos
                    local viewerDir = (EyePos() - eyePos):Angle():Forward()

                    local firstEye  = eyePos + (forward * 0.6) + (right * -1.25) + (viewerDir * 1)
                    local secondEye = eyePos + (forward * 0.6) + (right *  1.25) + (viewerDir * 1)

                    render.SetMaterial(matEyeGlow)
                    render.DrawSprite(firstEye, 2, 1.8, Color(200, 0, 0, 255))
                    render.DrawSprite(secondEye, 2, 1.8, Color(200, 0, 0, 255))
                end
            end

            -- Skeleton overlay (bonemerged)
            CreateInsanitySkeleton(v)

            -- Dynamic red-ish light from the eyes
            local dl = DynamicLight(v:EntIndex())
            if dl then
                dl.pos        = v:EyePos()
                dl.r          = 255
                dl.g          = 200
                dl.b          = 200
                dl.brightness = 0.5
                dl.Decay      = 1000
                dl.Size       = 128
                dl.DieTime    = CurTime() + 1
            end
        end
    else
        -- Sanity improved: clean up all skeleton overlays
        for idx, skeleton in pairs(insanitySkeletons) do
            local ply = Entity(idx)
            if IsValid(ply) then
                RemoveInsanitySkeleton(ply)
            elseif IsValid(skeleton) then
                skeleton:Remove()
                insanitySkeletons[idx] = nil
            else
                insanitySkeletons[idx] = nil
            end
        end
    end
end)

------------------------------------------------------------
-- Audio stingers by sanity
------------------------------------------------------------

local function StartInsanityLoop()
    if not insanityLoopSound then
        local lp = LocalPlayer()
        if IsValid(lp) then
            insanityLoopSound = CreateSound(lp, "citizensounds/insanity_outside.mp3")
            insanityLoopSound:SetSoundLevel(0) -- ambient, no attenuation dropoff
            insanityLoopSound:PlayEx(1, 100)   -- volume 1, pitch 100
        end
    elseif not insanityLoopSound:IsPlaying() then
        insanityLoopSound:PlayEx(1, 100)
    end
end

local function StopInsanityLoop()
    if insanityLoopSound then
        insanityLoopSound:Stop()
        insanityLoopSound = nil
    end
end

hook.Add("Think", "ix_sanity_audio_effects", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then
        StopInsanityLoop()
        return
    end

    local sanity = GetPlayerSanity()

    -- start/stop the continuous insanity ambience
    -- (use the same threshold that drives your hallucinations)
    if sanity <= sanity_threshold then
        StartInsanityLoop()
    else
        StopInsanityLoop()
    end

    -- ... keep your existing stinger logic below this line ...
    local now = CurTime()
    if sanity <= SANITY_LOW and (not nextSanitySound or nextSanitySound < now) then
        if sanity <= SANITY_VERY_LOW then
            nextSanitySound = now + math.random(40, 60)
            if #lowSanitySounds > 0 then
                lp:EmitSound(table.Random(lowSanitySounds), 60)
            end
        else
            nextSanitySound = now + math.random(20, 60)
            if #medSanitySounds > 0 then
                lp:EmitSound(table.Random(medSanitySounds), 60, math.random(75, 100))
            end
        end
    end
end)

------------------------------------------------------------
-- NO PrePlayerDraw hider anymore (we hard-hide via material)
-- This avoids double-render/overlap issues with other hooks.
------------------------------------------------------------

------------------------------------------------------------
-- Main logic timer
------------------------------------------------------------
timer.Create("ix_insanity_zombify_v4", 0.3, 0, function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local sanity = GetPlayerSanity()

    -- Add/remove zombies
    for _, p in ipairs(player.GetAll()) do
        if should_swap(p, lp, sanity) then
            add_zombie(p)
        else
            remove_zombie(p)
        end
    end

    -- Cleanup invalids or sanity restored
    for p, _ in pairs(hall) do
        if (not IsValid(p)) or sanity > sanity_threshold then
            remove_zombie(p)
        end
    end
end)

------------------------------------------------------------
-- Optional: keep bodygroups/skin mirrored if they change at runtime
------------------------------------------------------------
timer.Create("ix_insanity_sync_bgroups", 0.5, 0, function()
    for p, rec in pairs(hall) do
        if IsValid(p) and rec and IsValid(rec.cs) then
            rec.cs:SetSkin(p:GetSkin() or 0)
            local bgs = p.GetBodyGroups and p:GetBodyGroups() or {}
            for _, bg in ipairs(bgs) do
                rec.cs:SetBodygroup(bg.id, p:GetBodygroup(bg.id))
            end
        end
    end
end)

------------------------------------------------------------
-- Cleanup
------------------------------------------------------------
hook.Add("PlayerRemoved", "ix_insanity_zombify_cleanup_v4", function(p)
    remove_zombie(p)
    if IsValid(p) then RemoveInsanitySkeleton(p) end
end)

hook.Add("ShutDown", "ix_insanity_zombify_shutdown_v4", function()
    for p, _ in pairs(hall) do remove_zombie(p) end
    for idx, sk in pairs(insanitySkeletons) do
        if IsValid(sk) then sk:Remove() end
        insanitySkeletons[idx] = nil
    end
end)

------------------------------------------------------------
-- Debugging helpers
------------------------------------------------------------
concommand.Add("test_zombify", function()
    print("Testing zombify system...")
    print("Current sanity:", GetPlayerSanity())
    print("Sanity thresholds - Very Low:", SANITY_VERY_LOW, "Low:", SANITY_LOW, "Medium:", SANITY_MEDIUM)
    print("Zombie entries:", table.Count(hall))
    print("Skeleton entries:", table.Count(insanitySkeletons))
    print("Contrast add value:", contrastAdd)

    for p, rec in pairs(hall) do
        if IsValid(p) and rec and IsValid(rec.cs) then
            print("Zombie active for:", p:Name())
            print("  CS Model:", rec.cs:GetModel())
            print("  CS Valid:", IsValid(rec.cs))
            print("  Player Pos:", p:GetPos())
        end
    end

    for idx, skeleton in pairs(insanitySkeletons) do
        local player = Entity(idx)
        if IsValid(player) and IsValid(skeleton) then
            print("Skeleton active for:", player:Name())
            print("  Skeleton Model:", skeleton:GetModel())
            print("  Skeleton Color:", skeleton:GetColor())
        end
    end
end)

concommand.Add("force_zombify", function(_, _, args)
    local target_name = args[1]
    if not target_name then
        print("Usage: force_zombify <player_name>")
        return
    end
    for _, p in ipairs(player.GetAll()) do
        if string.find(string.lower(p:Name()), string.lower(target_name), 1, true) then
            add_zombie(p)
            print("Forced zombify on:", p:Name())
            return
        end
    end
    print("Player not found:", target_name)
end)

concommand.Add("test_sanity_effects", function()
    local current_sanity = GetPlayerSanity()
    print("Current sanity:", current_sanity)
    print("Contrast value:", contrastAdd)

    if current_sanity <= SANITY_VERY_LOW then
        print("Very low sanity effects active")
    elseif current_sanity <= SANITY_LOW then
        print("Low sanity effects active")
    elseif current_sanity <= SANITY_MEDIUM then
        print("Medium sanity effects active")
    else
        print("No sanity effects active")
    end
end)
