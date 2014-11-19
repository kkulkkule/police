MsgC(Color(0, 255, 0), "Initialize Police Module...\n")
include("shared.lua")

HPolice.Init = function()
	util.AddNetworkString("HPoliceAlert")
	HPolice.StartChecker()
end
hook.Add("Initialize", "HPoliceInit", HPolice.Init)

HPolice.StartChecker = function()
	local allFiles = file.Find("polices/*.txt", "DATA")
	for _, v in pairs(allFiles) do
		local data = file.Read("polices/" .. v, "DATA")
		local processed = string.find(data, "processed")
		if processed and file.Time("polices/" .. v, "DATA") + 86400 <= os.time() then
			file.Delete("polices/" .. v)
		end		
	end
end

HPolice.HookPoliceSay = function(sender, text, teamChat)
	if string.Left(text, 1) == "!" then
		local exploded = string.Explode(" ", text)
		if exploded[1] == "!신고" or exploded[1] == "!police" then
			local target = NULL
			local reason = ""
			if !exploded[2] then
				sender:PrintMessage(HUD_PRINTTALK, "사용법: !신고 {대상의 닉네임 혹은 STEAM ID} {사유}")
				sender:PrintMessage(HUD_PRINTTALK, "        고유번호를 알아내려면 !고번 혹은 !고유번호를 치세요.")
				return ""
			else
				if string.find(string.upper(exploded[2]), "STEAM_%d:%d:%d+$") then
					local steamid = exploded[2]
					for _, v in pairs(player.GetAll()) do
						if string.upper(v:SteamID()) == string.upper(steamid) then
							target = v
							break
						end
					end
					
					if target == NULL then
						target = steamid
					end
					
					local reasonTable = {}
					for i = 3, table.Count(exploded) do
						table.insert(reasonTable, exploded[i])
					end
					reason = table.concat(reasonTable, " ")
				else
					local targets = {}
					for _, v in pairs(player.GetAll()) do
						if string.find(string.lower(v:Nick()), string.lower(exploded[2])) then
							table.insert(targets, v)
						end
					end
					if table.Count(targets) > 1 then
						sender:PrintMessage(HUD_PRINTTALK, "해당 문자열을 포함한 닉네임의 유저가 두 명 이상입니다.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호를 통해 신고해주세요.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호는 !고번 혹은 !고유번호라고 치면 출력됩니다.")
					elseif table.Count(targets) <= 0 then
						sender:PrintMessage(HUD_PRINTTALK, "해당 문자열을 포함한 닉네임의 유저가 없습니다.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호를 통해 신고해주세요.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호는 !고번 혹은 !고유번호라고 치면 출력됩니다.")
					else
						target = targets[1]
						local reasonTable = {}
						for i = 3, table.Count(exploded) do
							table.insert(reasonTable, exploded[i])
						end
						reason = table.concat(reasonTable, " ")
					end
				end
				
				if target != NULL and reason != "" then
					string.Replace(string.Replace(reason, "{", ""), "}", "")
					if string.len(reason) <= 110 then
						local filename = HPolice.ReplaceSteamID("polices/" .. os.date("%Y%m%d%H%M%S", os.time()) .. "_" .. sender:SteamID() .. ".txt")
						
						local policer = HPolice.ReplaceSpaceChar(sender:Nick())
						if isentity(target) and target:IsPlayer() then
							sid = target:SteamID()
							-- target = string.Replace(string.Replace(HPolice.ReplaceSpaceChar(target:Nick()), " ", ""), "\t", "") .. "(" .. sid .. ")"
							target = target:Nick() .. "(" .. sid .. ")"
						end
						
						HPolice.ReplaceSpaceChar(target)
						
						-- file.Write(filename, 
							-- "신고자: " .. sender:Nick() .. "(" .. sender:SteamID() .. ")\r\n" ..
							-- "신고 사유: " .. reason .. "\r\n" ..
							-- "신고 대상자: " .. target .."\r\n" ..
							-- "신고 시각: " .. os.date("%Y/%m/%d %H:%M:%S", os.time())
						-- )
						local f = file.Open(filename, "w", "DATA")
						f:Write("신고자: " .. sender:Nick() .. "(" .. sender:SteamID() .. ")\n")
						f:Write("신고 사유: " .. reason .. "\n")
						f:Write("신고 대상자: " .. target .. "\n")
						f:Write("신고 시각: " .. os.date("%Y/%m/%d %H:%M:%S", os.time()))
						f:Close()
						HPolice.CheckIfSuccess(filename, sender)
					else
						PrintMessage(HUD_PRINTTALK, "신고 사유는 영어 110자, 한글 55자(110 byte) 이내로 적어주세요.")
					end
				elseif reason == "" then
					sender:PrintMessage(HUD_PRINTTALK, "신고 사유를 제대로 적어주세요.")
				end
				return ""
			end
		elseif exploded[1] == "!고번" or exploded[1] == "!고유번호" then
			for _, v in pairs(player.GetAll()) do
				sender:PrintMessage(HUD_PRINTTALK, v:Nick() .. "\t\t" .. v:SteamID())
			end
			return ""
		elseif exploded[1] == "!신고처리" or exploded[1] == "!처리현황" or exploded[1] == "!신고현황" then
			local allFiles = file.Find("polices/*.txt", "DATA")
			local listFiles = {}
			for i, v in pairs(allFiles) do
				if !sender:IsAdmin() then
					if string.find(string.upper(v), HPolice.ReplaceSteamID(sender:SteamID())) then
						table.insert(listFiles, v)
					end
					
					for _, v in pairs(listFiles) do
						local data = file.Read("polices/" .. v)
						local processed = string.find(data, "processed")
						local target = ""
						for v in string.gfind(data, "신고 대상자: ([^\r]+)\r\n") do
							target = v
						end
						if processed then
							sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target .. ", 처리됨")
							file.Delete("polices/" .. v)
						else
							local reason = ""
							for v in string.gfind(data, "신고 사유: ([^\r]+)\r\n") do
								reason = v
							end
							sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target .. ", 처리 안 됨")
							sender:PrintMessage(HUD_PRINTTALK, "\t\t\t사유: " .. reason)
						end
					end
				else
					local data = file.Read("polices/" .. v)
					local processed = string.find(data, "processed")
					local target = ""
					for v in string.gfind(data, "신고 대상자: ([^\r]+)\r\n") do
						target = v
					end
					if processed then
						sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target .. ", 처리됨")
						if string.find(v, HPolice.ReplaceSteamID(sender:SteamID())) then
							file.Delete("polices/" .. v)
						end
					else
						local reason = ""
						for v in string.gfind(data, "신고 사유: ([^\r]+)\r\n") do
							reason = v
						end
						sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target .. ", 처리 안 됨")
						sender:PrintMessage(HUD_PRINTTALK, "\t\t\t사유: " .. reason)
					end
				end
			end
		end
	end
	return nil
end
-- hook.Remove("PlayerSay", "HookPoliceSay", HPolice.HookPoliceSay)
hook.Add("PlayerSay", "HookPoliceSay", HPolice.HookPoliceSay)

HPolice.CheckIfSuccess = function(filename, sender, delay)
	if !delay then
		delay = 0.5
	end
	
	sender:PrintMessage(HUD_PRINTTALK, "신고 접수중입니다...")
	
	timer.Create("CheckIfPoliceWasSuccess#" .. filename, delay, 1, function()
		if file.Exists(filename, "DATA") then
			sender:PrintMessage(HUD_PRINTTALK, "신고가 정상적으로 접수되었습니다.")
		else
			sender:PrintMessage(HUD_PRINTTALK, "신고 접수 중 오류가 발생했습니다. 다시 신고해주세요.")
			sender:PrintMessage(HUD_PRINTTALK, "이와 같은 일이 반복된다면 홈페이지에 버그 리포팅을 해주시기 바랍니다.")
		end
	end)
end
MsgC(Color(0, 255, 0), "Complete!\n")