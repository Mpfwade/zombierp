local playerMeta = FindMetaTable("Player")

function playerMeta:IsCombine()
	local faction = self:Team()
	return faction == FACTION_MPF or faction == FACTION_OTA
end

function playerMeta:IsCitizen()
    return self:Team() == FACTION_CITIZEN
end

function playerMeta:IsDispatch()
	local name = self:Name()
	local faction = self:Team()
	local bStatus = faction == FACTION_OTA

	if (!bStatus) then
		for k, v in ipairs({ "SCN", "DvL", "SeC" }) do
			if (Schema:IsCombineRank(name, v)) then
				bStatus = true

				break
			end
		end
	end

	return bStatus
end

function playerMeta:ShouldSetRagdolled(bState)
    if not self:Alive() then return end

    if bState then
        if IsValid(self.ixRagdoll) then
            self.ixRagdoll:Remove()
        end

        local entity = self:CreateServerRagdoll()

        entity:CallOnRemove("fixer", function()
            if IsValid(self) then
                self:SetLocalVar("ragdoll", nil)

                if not entity.ixNoReset then
                    self:SetPos(entity:GetPos())
                end

                self:SetNoDraw(false)
                self:SetNotSolid(false)
                self:SetMoveType(MOVETYPE_WALK)
                self:SetLocalVelocity(IsValid(entity) and entity.ixLastVelocity or vector_origin)
            end

            if IsValid(self) and not entity.ixIgnoreDelete then
                if entity.ixWeapons then
                    for _, v in ipairs(entity.ixWeapons) do
                        if v.class then
                            local weapon = self:Give(v.class, true)

                            if v.item then
                                weapon.ixItem = v.item
                            end

                            self:SetAmmo(v.ammo, weapon:GetPrimaryAmmoType())
                            weapon:SetClip1(v.clip)
                        elseif v.item and v.invID == v.item.invID then
                            v.item:Equip(self, true, true)
                            self:SetAmmo(v.ammo, self.carryWeapons[v.item.weaponCategory]:GetPrimaryAmmoType())
                        end
                    end
                end

                if entity.ixActiveWeapon then
                    if self:HasWeapon(entity.ixActiveWeapon) then
                        self:SetActiveWeapon(self:GetWeapon(entity.ixActiveWeapon))
                    else
                        local weapons = self:GetWeapons()

                        if #weapons > 0 then
                            self:SetActiveWeapon(weapons[1])
                        end
                    end
                end

                if self:IsStuck() then
                    entity:DropToFloor()
                    self:SetPos(entity:GetPos() + Vector(0, 0, 16))

                    local positions = ix.util.FindEmptySpace(self, {entity, self})

                    for _, v in ipairs(positions) do
                        self:SetPos(v)
                        if not self:IsStuck() then return end
                    end
                end
            end
        end)

        self.ixRagdoll = entity
        entity.ixWeapons = {}
        entity.ixPlayer = self

        if IsValid(self:GetActiveWeapon()) then
            entity.ixActiveWeapon = self:GetActiveWeapon():GetClass()
        end

        for _, v in ipairs(self:GetWeapons()) do
            if v.ixItem and v.ixItem.Equip and v.ixItem.Unequip then
                entity.ixWeapons[#entity.ixWeapons + 1] = {
                    item = v.ixItem,
                    invID = v.ixItem.invID,
                    ammo = self:GetAmmoCount(v:GetPrimaryAmmoType())
                }

                v.ixItem:Unequip(self, false)
            else
                local clip = v:Clip1()
                local reserve = self:GetAmmoCount(v:GetPrimaryAmmoType())

                entity.ixWeapons[#entity.ixWeapons + 1] = {
                    class = v:GetClass(),
                    item = v.ixItem,
                    clip = clip,
                    ammo = reserve
                }
            end
        end

        self:GodDisable()
        self:StripWeapons()
        self:SetMoveType(MOVETYPE_OBSERVER)
        self:SetNoDraw(true)
        self:SetNotSolid(true)
        self:SetLocalVar("ragdolled", entity:EntIndex())
        hook.Run("PlayerRagdolled", self, entity, true)
    elseif IsValid(self.ixRagdoll) then
        self.ixRagdoll:Remove()
        hook.Run("PlayerRagdolled", self, nil, false)
    end
end