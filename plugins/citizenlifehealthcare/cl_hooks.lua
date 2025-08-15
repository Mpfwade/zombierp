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

    if not IsValid(client) then client = LocalPlayer() end
    local character = client:GetCharacter()
    if not character then return end
    local sanity = character:GetSanity() / 100

    if sanity >= 100 and self.messages and #self.messages > 0 then
    table.Empty(self.messages)
end
    self.nextMessage = self.nextMessage or 0
self.messages = self.messages or {}

if self.nextMessage < CurTime() then
    local chance = math_random(90, 100)
    local nextMessage = math_random(500, 600)

    if sanity < 0.2 and chance > 40 then
        for i = 1, math_random(2, 4) do
            self.messages[#self.messages + 1] = {
                table.Random(self.randomMessages),
                CurTime() + math_random(12, 45)
            }
        end
        nextMessage = math_random(20, 40)
    elseif sanity < 0.4 and chance > 60 then
        self.messages[#self.messages + 1] = {
            table.Random(self.randomMessages),
            CurTime() + math_random(12, 45)
        }
        nextMessage = math_random(150, 300)
    elseif sanity < 0.6 and chance > 80 then
        self.messages[#self.messages + 1] = {
            table.Random(self.randomMessages),
            CurTime() + math_random(12, 45)
        }
    end

    self.nextMessage = CurTime() + nextMessage
end

    for i, v in ipairs(self.messages) do
        if v[2] < CurTime() then table.remove(self.messages, i) end
        if v.reverse == nil then
            local rand = math_random(-5, 5)
            if rand > 0 then
                v.reverse = true
            else
                v.reverse = false
            end
        end

        v.x = v.x or math_random(1, ScrW())
        v.y = v.y or math_random(1, ScrH())
        v.projX = v.projX or math_random(1, ScrW())
        v.projY = v.projY or math_random(1, ScrH())
        v.x = Lerp(0.005, v.x, v.projX)
        v.y = Lerp(0.005, v.y, v.projY)
        local dist = math.Distance(v.x, v.y, v.projX, v.projY)
        if dist < 5 then
            v.projX = math_random(1, ScrW())
            v.projY = math_random(1, ScrH())
        end

        local m = Matrix()
        local pos = Vector(v.x, v.y)
        m:Translate(pos)
        m:Scale(Vector(1, 1, 1) * TimedSin(0.25, 3, 6, v[2]))
        m:Rotate(Angle(0, v[2] + CurTime() * 50 * (v.reverse and 1 or -1), 0))
        m:Translate(-pos)
        cam.PushModelMatrix(m)
        draw.SimpleText(v[1], "BudgetLabel", v.x + math_random(-3, 3), v.y + math_random(-3, 3), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        cam.PopModelMatrix()
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

    if sanity >= 15 then
    DrawColorModify({
        ["$pp_colour_addr"] = 0.1,  -- Red additive
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.05,
        ["$pp_colour_contrast"] = 1.2,
        ["$pp_colour_colour"] = 0.5,
        ["$pp_colour_mulr"] = 0.2,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    })

    surface.SetDrawColor(255, 0, 0, 40) -- Light red screen overlay
    surface.DrawRect(0, 0, ScrW(), ScrH())
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

PLUGIN.randomMessages = {"Damn the world is so meh...", "The world sucks so much, why can't it just be better...?", "I wonder if things will get better...", "How much longer do I have to live like this..."}
PLUGIN.events = {
    [1] = function(client)
        surface.PlaySound("ambient/voices/squeal1.wav")
        client:ChatNotify("What was that sound...?")
    end,
    [2] = function(client)
        local sound = CreateSound(client, "music/radio1.mp3")
        sound:SetDSP(5)
        sound:Play()
        timer.Simple(20, function() sound:FadeOut(3) end)
        client:ChatNotify("Why... why can I hear music...?")
    end,
    [3] = function(client)
        surface.PlaySound("ambient/voices/playground_memory.wav")
        client:ChatNotify("What are those sounds...? Children...?")
    end,
    [4] = function(client)
        local sound = CreateSound(client, "player/heartbeat1.wav")
        sound:SetDSP(5)
        sound:Play()
        timer.Simple(6, function() sound:FadeOut(3) end)
    end,
    [5] = function(client)
        local sound = CreateSound(client, "citizensounds/insanity_outside.mp3")
        sound:SetDSP(5)
        sound:Play()
        timer.Simple(12, function() sound:FadeOut(120) end)
        client:ChatNotify("What is that noise...?")
    end,
    [6] = function(client)
        local sound = CreateSound(client, "npc/stalker/breathing3.wav")
        sound:SetDSP(5)
        sound:Play()
        timer.Simple(5, function() sound:FadeOut(3) end)
        client:ChatNotify("Who is breathing...?")
    end,
    [7] = function(client)
        local sound = CreateSound(client, "buttons/combine_button_locked.wav")
        sound:SetDSP(38)
        sound:Play()
        sound:FadeOut(3)
        ErrorNoHalt("Get trolled noob :^)\n")
        system.FlashWindow()
    end,
    [8] = function(client)
        local sound = CreateSound(client, "vo/episode_1/intro/vortchorus.wav")
        sound:SetDSP(38)
        sound:Play()
        client:ScreenFade(SCREENFADE.OUT, Color(255, 0, 0, 220), 2, 12)
        timer.Simple(9, function()
            sound:FadeOut(7)
            timer.Simple(4, function() client:ScreenFade(SCREENFADE.IN, Color(255, 0, 0, 220), 2, 2) end)
        end)
    end
}

function PLUGIN:Think()
    if not IsValid(client) then client = LocalPlayer() end
    local character = client:GetCharacter()
    if not character then return end
    local sanity = character:GetSanity() / 100
    if sanity < 60 then
        self.nextEvent = CurTime() + 120
        return
    end

    self.nextEvent = self.nextEvent or CurTime() + math_random(300, 600)
    if self.nextEvent < CurTime() then
        local rand = math_random(1, #self.events)
        if self.events[rand] then self.events[rand](client) end
        self.nextEvent = CurTime() + math_random(300, 1800)
    end
end

PLUGIN.dist = 64 ^ 2
local function GetPos(client)
    local tr = {}
    tr.start = client:GetPos()
    tr.endpos = client:GetPos() + Angle(0, EyeAngles().y, 0):Forward() * -224
    tr.filter = client
    return util.TraceLine(tr).HitPos
end

function PLUGIN:PostDrawOpaqueRenderables()
    self.monsters = self.monsters or {}
    self.nextMonster = self.nextMonster or 0
    if not IsValid(client) then client = LocalPlayer() end
    local character = client:GetCharacter()
    if not character then return end
    local sanity = character:GetSanity() / 100
    if sanity >= 20 then self.nextMonster = CurTime() + 120 end
    if self.nextMonster < CurTime() then
        self.monsters[#self.monsters + 1] = {"models/Humans/Group01/Male_01.mdl", CurTime() + 24}
        self.nextMonster = CurTime() + 300
        client:ChatNotify("You feel as if something is watching you...")
    end

    for i, v in ipairs(self.monsters) do
        if v[2] < CurTime() then
            if IsValid(v.ent) then v.ent:Remove() end
            table.remove(self.monsters, i)
        end

        v.ent = v.ent or ClientsideModel(v[1], RENDERGROUP_BOTH)
        if v.ent then
            v.pos = v.pos or GetPos(client)
            if not v.pos then continue end
            local trace = {}
            trace.start = EyePos()
            trace.endpos = EyePos() + EyeAngles():Forward() * EyePos():Distance(v.pos)
            trace.filter = client
            trace = util.TraceLine(trace)
            if trace.HitPos:Distance(v.pos) < 72 then
                v.startLook = v.startLook or CurTime() + 1.5
                if v.startLook < CurTime() then v.pos = LerpVector(0.09, v.pos, LocalPlayer():GetPos()) end
            end

            if client:GetPos():DistToSqr(v.pos) < self.dist then
                v.ent:Remove()
                table.remove(self.monsters, i)
                client:SetDSP(39)
                surface.PlaySound("npc/stalker/go_alert2a.wav")
                client:ScreenFade(SCREENFADE.MODULATE, Color(0, 0, 0), 1, 0)
                timer.Simple(1, function()
                    client:SetDSP(38) -- Could improve this but I'm lazy
                    client:ScreenFade(SCREENFADE.PURGE, Color(0, 0, 0, 240), 4, 0)
                    timer.Simple(4, function()
                        client:SetDSP(39)
                        client:ScreenFade(SCREENFADE.MODULATE, Color(0, 0, 0), 1, 0)
                        timer.Simple(1, function() client:SetDSP(0) end)
                    end)
                end)
            end

            v.ang = Angle(0, EyeAngles().y - 180, 0)
            v.ent:SetPos(v.pos)
            v.ent:SetAngles(v.ang)
            v.ent:SetSequence(ACT_IDLE)
            v.ent:SetColor(Color(0, 0, 0))
        end
    end
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