local PLUGIN = PLUGIN
PLUGIN.name = "Player Gestures"
PLUGIN.description = "Adds gestures that can be used for certain supported animations. Major thanks to Wicked Rabbit for showing me how it works!"
PLUGIN.author = "Riggs Mackay (Edited by Wade)"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright 2022 Riggs Mackay

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
PLUGIN.gestures = {
    {
        gesture = "g_salute", -- Mainly for the citizen_male models, or models that include the citizen male gestures -- citizen rp go brrrr...
        command = "Salute",
        id = 1444
    },
    {
        gesture = "g_antman_dontmove",
        command = "DontMove",
        id = 1445
    },
    {
        gesture = "g_antman_stayback",
        command = "StayBack",
        id = 1446
    },
    {
        gesture = "g_armsout",
        command = "ArmSout",
        id = 1447
    },
    {
        gesture = "g_armsout_high",
        command = "ArmSoutHigh",
        id = 1448
    },
    {
        gesture = "g_chestup",
        command = "ChestUp",
        id = 1449
    },
    {
        gesture = "g_clap",
        command = "Clap",
        id = 1450
    },
    {
        gesture = "g_fist_L",
        command = "FistLeft",
        id = 1451
    },
    {
        gesture = "g_fist_r",
        command = "FistRight",
        id = 1452
    },
    {
        gesture = "g_fist_swing_across",
        command = "FistSwing",
        id = 1453
    },
    {
        gesture = "g_fistshake",
        command = "FistShake",
        id = 1454
    },
    {
        gesture = "g_frustrated_point_l",
        command = "PointFrustrated",
        id = 1455
    },
    {
        gesture = "G_noway_big",
        command = "No",
        id = 1456
    },
    {
        gesture = "G_noway_small",
        command = "NoSmall",
        id = 1457
    },
    {
        gesture = "g_plead_01",
        command = "Plead",
        id = 1458
    },
    {
        gesture = "g_point",
        command = "Point",
        id = 1459
    },
    {
        gesture = "g_point_swing",
        command = "PointSwing",
        id = 1460
    },
    {
        gesture = "g_pointleft_l",
        command = "PointLeft",
        id = 1461
    },
    {
        gesture = "g_pointright_l",
        command = "PointRight",
        id = 1462
    },
    {
        gesture = "g_present",
        command = "Present",
        id = 1463
    },
    {
        gesture = "G_shrug",
        command = "Shrug",
        id = 1464
    },
    {
        gesture = "g_thumbsup",
        command = "ThumbsUp",
        id = 1465
    },
    {
        gesture = "g_wave",
        command = "Wave",
        id = 1466
    },
    {
        gesture = "G_what",
        command = "What",
        id = 1467
    },
    {
        gesture = "hg_headshake",
        command = "HeadShake",
        id = 1468
    },
    {
        gesture = "hg_nod_no",
        command = "HeadNo",
        id = 1469
    },
    {
        gesture = "hg_nod_yes",
        command = "HeadYes",
        id = 1470
    },
    {
        gesture = "hg_nod_left",
        command = "HeadLeft",
        id = 1471
    },
    {
        gesture = "hg_nod_right",
        command = "HeadRight",
        id = 1472
    },
    {
        gesture = "GestureButton",
        command = "Button",
        id = 1473
    },
}

PLUGIN.femalegestures = {
    {
        gesture = "b_accent_back", --{gesture = "hg_nod_right", command = "HeadRight", id = 1473}, -- citizen rp go brrrr...
        command = "Accentback",
        id = 2444
    },
    {
        gesture = "b_accent_fwd",
        command = "Accentfoward",
        id = 2445
    },
    {
        gesture = "b_accent_fwd2",
        command = "Accentfoward2",
        id = 2446
    },
    {
        gesture = "b_accent_fwd_UpperBody",
        command = "Accentfoward3",
        id = 2447
    },
    {
        gesture = "b_head_back",
        command = "headback",
        id = 2448
    },
    {
        gesture = "b_head_forward",
        command = "headforward",
        id = 2449
    },
    {
        gesture = "b_OverHere_Left",
        command = "overhereleft",
        id = 2450
    },
    {
        gesture = "b_OverHere_Right",
        command = "overhereright",
        id = 2451
    },
    {
        gesture = "broadsweepdown",
        command = "sweepdown",
        id = 2452
    },
    {
        gesture = "g_arrest_clench",
        command = "arrestclench",
        id = 2453
    },
    {
        gesture = "g_display_left",
        command = "displayleft",
        id = 2454
    },
    {
        gesture = "g_left_openhand",
        command = "openhandleft",
        id = 2455
    },
    {
        gesture = "G_puncuate",
        command = "puncuate",
        id = 2456
    },
    {
        gesture = "g_right_openhand",
        command = "openhandright",
        id = 2457
    },
    {
        gesture = "g_wave",
        command = "femWave",
        id = 2458
    },
    {
        gesture = "hg_headshake",
        command = "femHeadShake",
        id = 2459
    },
    {
        gesture = "hg_nod_no",
        command = "femHeadNo",
        id = 2460
    },
    {
        gesture = "hg_nod_yes",
        command = "femHeadYes",
        id = 2461
    },
    {
        gesture = "hg_nod_left",
        command = "femHeadLeft",
        id = 2462
    },
    {
        gesture = "hg_nod_right",
        command = "femHeadRight",
        id = 2463
    },
    {
        gesture = "urgenthandsweep",
        command = "urgentsweep",
        id = 2467
    },
}

if SERVER then
    function PLUGIN:DoAnimationEvent(player, event, data)
        if event == PLAYERANIMEVENT_CUSTOM_GESTURE then
            local gestureTable = player:IsFemale() and self.femalegestures or self.gestures
            for _, gesture in pairs(gestureTable) do
                if data == gesture.id then
                    if player.isAnimating then return end
                    net.Start("PlayerGesture")
                    net.WriteEntity(player)
                    net.WriteUInt(gesture.id, 16) -- Use 16 bits to send the gesture ID
                    net.Broadcast()
                    player:AddVCDSequenceToGestureSlot(GESTURE_SLOT_CUSTOM, player:LookupSequence(gesture.gesture), 0, true) -- Apply the gesture to the initiating player
                    player.isAnimating = true
                    timer.Simple(player:SequenceDuration(), function()
                        if IsValid(player) then -- Reset the animation state after the duration of the animation
                            player.isAnimating = false
                        end
                    end)
                    return ACT_INVALID
                end
            end
        end
    end

    for _, v in pairs(PLUGIN.gestures) do -- Register male gestures
        local commandname = string.Replace(v.gesture, "hg_", "")
        commandname = string.Replace(commandname, "g_", "")
        commandname = string.Replace(commandname, "antman_", "")
        commandname = string.Replace(commandname, "_", " ")
        concommand.Add("ix_act_" .. v.command, function(ply, cmd, args)
            if ply.isAnimating then -- Prevent playing a new animation if one is already active
                return
            end

            local gestureTable = ply:IsFemale() and PLUGIN.femalegestures or PLUGIN.gestures
            for _, gesture in pairs(gestureTable) do
                if gesture.command == v.command then
                    ply:DoAnimationEvent(gesture.id)
                    break
                end
            end
        end)

        ix.command.Add("Gesture" .. v.command, {
            description = "Play the " .. commandname .. " gesture.",
            OnCanRun = function(_, ply) if not ply:IsSuperAdmin() and not ply:IsAdmin() then return "You need to be an admin!" end end,
            OnRun = function(_, ply) ply:ConCommand("ix_act_" .. v.command) end
        })
    end

    for _, v in pairs(PLUGIN.femalegestures) do -- Register female gestures
        local commandname = string.Replace(v.gesture, "hg_", "")
        commandname = string.Replace(commandname, "b_", "")
        commandname = string.Replace(commandname, "_", " ")
        concommand.Add("ix_act_" .. v.command, function(ply, cmd, args)
            if ply.isAnimating then -- Prevent playing a new animation if one is already active
                return
            end

            local gestureTable = ply:IsFemale() and PLUGIN.femalegestures or PLUGIN.gestures
            for _, gesture in pairs(gestureTable) do
                if gesture.command == v.command then
                    ply:DoAnimationEvent(gesture.id)
                    break
                end
            end
        end)

        ix.command.Add("Gesture" .. v.command, {
            description = "Play the " .. commandname .. " gesture.",
            OnCanRun = function(_, ply) if not ply:IsSuperAdmin() and not ply:IsAdmin() then return "You need to be an admin!" end end,
            OnRun = function(_, ply) ply:ConCommand("ix_act_" .. v.command) end
        })
    end

    util.AddNetworkString("PlayerGesture")
    local allowedChatTypes = {
        ["ic"] = true,
        ["w"] = true,
        ["y"] = true,
    }

    local MaleRandomAnims = {"ix_act_armsout", "ix_act_no", "ix_act_nosmall", "ix_act_plead", "ix_act_point", "ix_act_chestup", "ix_act_fistleft", "ix_act_present", "ix_act_headleft", "ix_act_headright"}
    local MaleWhatAnims = {"ix_act_what", "ix_act_shrug"}
    local FemaleRandomAnims = {"ix_act_accentback", "ix_act_accentfoward", "ix_act_accentfoward2", "ix_act_accentfoward3", "ix_act_headback", "ix_act_headforward", "ix_act_overhereleft", "ix_act_overhereright", "ix_act_puncuate", "ix_act_urgentsweep"}
    local FemaleWhatAnims = {"ix_act_puncuate", "ix_act_accentback"}
    function PLUGIN:PrePlayerMessageSend(ply, chatType, message, bAnonymous)
        if allowedChatTypes[chatType] then
            local isFemale = ply:IsFemale()
            local RandomAnims = isFemale and FemaleRandomAnims or MaleRandomAnims
            local WhatAnims = isFemale and FemaleWhatAnims or MaleWhatAnims
            if message:find("!") then
                ply:ConCommand("ix_act_fistswing")
            elseif message:find("?") then
                ply:ConCommand(table.Random(WhatAnims))
            elseif message:find("Nice") then
                ply:ConCommand("ix_act_thumbsup")
            elseif message:find("YAY") or message:find("Hooray") or message:find("Bravo") or message:find("cheer") or message:find("cheer2") or message:find("cheer3") then
                ply:ConCommand("ix_act_clap")
            elseif message:find("Mhm") then
                ply:ConCommand("ix_act_headyes")
            elseif message:find("Stay down") or message:find("Get down!") or message:find("Get down") or message:find("Take cover!") or message:find("Take cover") then
                ply:ConCommand("ix_act_dontmove")
            elseif message:find(".") then
                ply:ConCommand(table.Random(RandomAnims))
            end
        end
    end
end

if CLIENT then
    net.Receive("PlayerGesture", function()
        local player = net.ReadEntity()
        local gestureId = net.ReadUInt(16)
        if IsValid(player) then
            player.activeGestures = player.activeGestures or {}
            local gestureTable = player:IsFemale() and PLUGIN.femalegestures or PLUGIN.gestures
            local gestureData
            for _, gesture in pairs(gestureTable) do
                if gesture.id == gestureId then
                    gestureData = gesture
                    break
                end
            end

            if not gestureData then return end
            local slots = {
                GESTURE_SLOT_ATTACK_AND_RELOAD, -- Try to find an available gesture slot (besides CUSTOM)
                GESTURE_SLOT_FLINCH,
                GESTURE_SLOT_JUMP,
                GESTURE_SLOT_VCD,
                GESTURE_SLOT_CUSTOM -- fallback
            }

            local usedSlots = player.activeGestureSlots or {}
            local availableSlot
            for _, slot in ipairs(slots) do
                if not usedSlots[slot] then
                    availableSlot = slot
                    break
                end
            end

            if not availableSlot then
                availableSlot = GESTURE_SLOT_CUSTOM -- fallback if all are used
            end

            local sequence = player:LookupSequence(gestureData.gesture)
            if sequence and sequence ~= -1 then
                player:AddVCDSequenceToGestureSlot(availableSlot, sequence, 0, true)
                player.activeGestures[gestureId] = true -- Track active gestures and their slots
                player.activeGestureSlots = player.activeGestureSlots or {}
                player.activeGestureSlots[availableSlot] = true
                timer.Simple(player:SequenceDuration(sequence), function()
                    if IsValid(player) then -- Cleanup when gesture ends
                        player.activeGestures[gestureId] = nil
                        player.activeGestureSlots[availableSlot] = nil
                    end
                end)
            end
        end
    end)
end