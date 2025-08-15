local PLUGIN = PLUGIN
local Schema = Schema

local chatTypes = {
    ['ic']                          = true,
    ['w']                           = true,
    ['y']                           = true,
    ['radio']                       = true,
    ['radio_yell']                  = true,
    ['radio_whisper']               = true,
    ['radio_eavesdrop']             = true,
    ['radio_eavesdrop_whisper']     = true,
    ['radio_eavesdrop_yell']        = true,
    ['dispatch']                    = true,
    ['dispatch_radio']              = true
}

local validEnds = {['.'] = true, ['?'] = true, ['!'] = true}
local real_table = Schema.PlayerMessageSend && Schema || PLUGIN
function real_table:PlayerMessageSend(speaker, chatType, text, anonymous, receivers, rawText)
	local function fixMarkup(a, b)
		return a..' '..string.upper(b)
	end

	if chatTypes[chatType] then
		local class = Schema.voices.GetClass(speaker)

		local textTable = string.Explode('; ?', rawText, true)
		local voiceList = {}

		for k, v in ipairs(textTable) do
			local bFound = false
			local text = string.upper(v)

			local info

			for _, c in ipairs(class) do
				info = Schema.voices.Get(c, text)
				if info then break end
			end

			if info then
				bFound = true

				if info.sound then
					voiceList[#voiceList + 1] = {
						global = info.global,
						sound = info.sound
					}
				end

				if k == 1 then
					textTable[k] = info.text
				else
					textTable[k] = string.lower(info.text)
				end

				if k != #textTable then
					local endText = string.sub(info.text, -1)

					if endText == '!' || endText == '?' then
						textTable[k] = string.gsub(textTable[k], '[!?]$', ',')
					end
				end
			end

			if bFound == false && k != #textTable then
				textTable[k] = v .. '; '
			end
		end

		local str
		str = table.concat(textTable, ' ')
		str = string.gsub(str, ' ?([.?!]) (%l?)', fixMarkup)

		if voiceList[1] then
			local volume = 80

			if chatType == 'w' then
				volume = 60
			elseif chatType == 'y' then
				volume = 150
			end

			local delay = 0

			for k, v in ipairs(voiceList) do
				local sound = v.sound

				if istable(sound) then
					sound = v.sound[1]
				end

				if delay == 0 then
					speaker:EmitSound(sound, volume)
				else
					timer.Simple(delay, function()
						speaker:EmitSound(sound, volume)
					end)
				end

				if v.global then
					if delay == 0 then
						for k1, v1 in ipairs(receivers) do
							if v1 != speaker then
                                net.Start('ixPlaySound')
                                    net.WriteString(sound)
                                net.Send(v1)
							end
						end
					else
						timer.Simple(delay, function()
							for k1, v1 in ipairs(receivers) do
								if v1 != speaker then
                                    net.Start('ixPlaySound')
                                        net.WriteString(sound)
                                    net.Send(v1)
								end
							end
						end)
					end
				end

				delay = delay + SoundDuration(sound) + 0.1
			end
		end

		str = str:sub(1, 1):upper() .. str:sub(2)
		if !validEnds[str:sub(-1)] then
			str = str .. '.'
		end

		if speaker:IsCombine() then
			return string.format('<:: %s ::>', str)
		else
			return str
		end
	end
end