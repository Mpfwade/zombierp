local PLUGIN = PLUGIN
function PLUGIN:PlayerInteractItem(client, action, item) --             ix.command.Send("ExitAct")  -- if open  door with weapon  i  can shoot  the weapon even  though its  not raised
    local dropAnim = "ThrowItem"
    local hands = {
        ["ix_keys"] = true,
        ["ix_hands"] = true
    }

    if action == "drop" and hands[client:GetActiveWeapon():GetClass()] then
        if client:GetNWBool("IsActing") then ix.command.Run(client, "ExitAct") end
        client:ForceSequence(dropAnim, nil, 1, true)
    end

    local itemEntity = item.entity
    if itemEntity then
        local trace = util.TraceLine({
            start = client:EyePos(),
            endpos = client:EyePos() + client:EyeAngles():Forward() * 100,
            filter = {client, itemEntity}
        })

        local pickupAnim = "Pickup"
        local pickupreachAnim = "gunrack"
        if action == "take" then
            if client:GetNWBool("IsActing") then ix.command.Run(client, "ExitAct") end
            if trace.HitWorld and not client:IsWepRaised() then
                client:ForceSequence(pickupAnim, nil, 1, true)
                ix.chat.Send(client, "me", "bends over to pick up an item.")
            elseif not trace.HitWorld then
                client:ForceSequence(pickupreachAnim, nil, 1, true)
                ix.chat.Send(client, "me", "reaches out their arm to pick up an item.")
            end
        end
    end
end

function PLUGIN:Equip(client, bNoSelect, bNoSound)
    if not client:IsCombine() then
        local strapAnim = "gunrack"
        if itemTable:GetData("equip") then
            client:ForceSequence(strapAnim, nil, 1, true)
            if client:GetNWBool("IsActing") then ix.command.Run(client, "ExitAct") end
        end
    end
end

local doorLockedNotified = {} -- Table to track door locked notifications
local doorOpen = false
hook.Add("PlayerUse", "DoorOpenCheck", function(client, entity)
    local hands = {
        ["ix_keys"] = true, -- Register the hook on the server-side
        ["ix_hands"] = true
    }

    if IsValid(entity) and entity:IsDoor() then -- Check if the entity being used is a door
        if entity:IsLocked() then
            if not doorLockedNotified[entity] then -- Check if the door locked notification has already been sent to the player
                client:ChatPrint("This door is locked")
                doorLockedNotified[entity] = true -- Set the notification flag for this door
                timer.Simple(5, function()
                    doorLockedNotified[entity] = false -- Start a timer to reset the flag after 5 seconds -- Reset the notification flag for this door
                end)
            end
        else
            if not client:IsWepRaised() or not client:IsRestricted() and client:IsPlayer() and hands[client:GetActiveWeapon():GetClass()] and client:Alive() then
                doorOpen = true
                if client:GetNWBool("IsActing") then ix.command.Run(client, "ExitAct") end
                if client:Team() == FACTION_CITIZEN then
                    client:ForceSequence("Open_door_towards_right", nil, 0.5, true)
                elseif client:Team() == FACTION_CCA then
                    client:ForceSequence("buttonfront", nil, 0.5, true)
                end

                timer.Simple(0.4, function()
                    client:LeaveSequence()
                    doorOpen = false
                    if not client:IsWepRaised() then
                        local weapon = client:GetActiveWeapon() -- Explicitly set the weapon to a non-active state
                        if IsValid(weapon) and weapon.SetWeaponRaised then weapon:SetWeaponRaised(false) end
                    end
                end)
            end
        end
    end
end)


function Schema:CanPlayerThrowPunch(ply)
    if ply:IsWepRaised() then
        if (SERVER) then
        ply:ForceSequence("MeleeAttack01", nil, 0.5, true)
        timer.Simple(0.5, function()  
            ply:LeaveSequence()
        end)
    end
end

    if not doorOpen and ply:IsWepRaised() then
        return true
    else
        return false
    end
end

local support = {
	metrocop = true,
	overwatch = true,
	citizen_male = true,
	citizen_female = true
}

local whitelist = {
	[ACT_MP_STAND_IDLE] = true,
	[ACT_MP_CROUCH_IDLE] = true
}

function PLUGIN:TranslateActivity(client, act)
	local modelClass = client.ixAnimModelClass or "player"

	if not support[modelClass] or not whitelist[act] then
		return
	end

	client.NextTurn = client.NextTurn or 0

	local diff = math.NormalizeAngle(client:GetRenderAngles().y - client:EyeAngles().y)

	if math.abs(diff) >= 45 and client.NextTurn <= CurTime() then
		local gesture = diff > 0 and ACT_GESTURE_TURN_RIGHT90 or ACT_GESTURE_TURN_LEFT90

		if client:IsWepRaised() and gesture == ACT_GESTURE_TURN_LEFT90 then
			gesture = ACT_GESTURE_TURN_LEFT45
		end

		client:AnimRestartGesture(GESTURE_SLOT_CUSTOM, gesture, true)
		client.NextTurn = CurTime() + client:SequenceDuration(client:SelectWeightedSequence(gesture))
	end
end