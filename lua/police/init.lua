MsgC(Color(0, 255, 0), "Initialize Police Module...\n")
include("shared.lua")

// 굳이 주석을 안 달아도 다 아는 초기화 부분
HPolice.Init = function()
	-- util.AddNetworkString("HPoliceAlert")
	HPolice.StartChecker()
	concommand.Add("hpolice_cancel", HPolice.CancelPolice)
end
hook.Add("Initialize", "HPoliceInit", HPolice.Init)

// 신고가 접수된지 24시간이 지났다면, 처리 유무에 관계없이 해당 신고 삭제
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

// 신고 관련 채팅 후킹
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
				// 스팀 아이디 형식일 경우 처리
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
				// 닉네임 형식일 경우 처리
				else
					local targets = {}
					for _, v in pairs(player.GetAll()) do
						if string.find(string.lower(v:Nick()), string.lower(exploded[2])) then
							table.insert(targets, v)
						end
					end
					// 예외처리
					if table.Count(targets) > 1 then
						sender:PrintMessage(HUD_PRINTTALK, "해당 문자열을 포함한 닉네임의 유저가 두 명 이상입니다.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호를 통해 신고해주세요.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호는 !고번 혹은 !고유번호라고 치면 출력됩니다.")
					elseif table.Count(targets) <= 0 then
						sender:PrintMessage(HUD_PRINTTALK, "해당 문자열을 포함한 닉네임의 유저가 없습니다.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호를 통해 신고해주세요.")
						sender:PrintMessage(HUD_PRINTTALK, "고유번호는 !고번 혹은 !고유번호라고 치면 출력됩니다.")
					// 플레이어 추출에 성공할 경우 사유를 보기 좋게 가공
					else
						target = targets[1]
						local reasonTable = {}
						for i = 3, table.Count(exploded) do
							table.insert(reasonTable, exploded[i])
						end
						reason = table.concat(reasonTable, " ")
					end
				end
				
				// 신고 대상이 확실하고 사유도 있을 경우 처리
				if target != NULL and reason != "" then
					string.Replace(string.Replace(reason, "{", ""), "}", "")
					// 봇 신고 방지
					if target:SteamID() == "BOT" then
						sender:PrintMessage(HUD_PRINTTALK, target:Nick() .. "은(는) 플레이어가 아닌 봇이므로 신고할 수 없습니다.")
						return
					end
					// 신고 접수
					if string.len(reason) <= 110 then // 사유 짤림 방지
						local filename = HPolice.ReplaceSteamID("polices/" .. os.date("%Y%m%d%H%M%S", os.time()) .. "_" .. sender:SteamID() .. ".txt")
						
						local policer = HPolice.ReplaceSpaceChar(sender:Nick())
						
						// 신고 대상이 문자열이 아닐 경우 SID 추출
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
						f:Write("신고 시각: " .. os.date("%Y/%m/%d %H:%M:%S", os.time()) .. "\n")
						f:Write("ID: " .. tostring(0x100000000 + tonumber(string.Replace(tostring(os.clock()), ".", ""))))
						f:Close()
						
						// 성공적으로 접수됐는지 알림
						HPolice.CheckIfSuccess(filename, sender, target, reason)
					else
						PrintMessage(HUD_PRINTTALK, "신고 사유는 영어 110자, 한글 55자(110 byte) 이내로 적어주세요.")
					end
				elseif reason == "" then
					sender:PrintMessage(HUD_PRINTTALK, "신고 사유를 제대로 적어주세요.")
				end
				return ""
			end
		// 고유번호 출력
		elseif exploded[1] == "!고번" or exploded[1] == "!고유번호" then
			for _, v in pairs(player.GetAll()) do
				sender:PrintMessage(HUD_PRINTTALK, v:Nick() .. "\t\t" .. v:SteamID())
			end
			return ""
		// 처리 현황 보기
		elseif exploded[1] == "!신고처리" or exploded[1] == "!처리현황" or exploded[1] == "!신고현황" then
			local allFiles = file.Find("polices/*.txt", "DATA")
			local listFiles = {}
			for i, v in pairs(allFiles) do
				// 어드민이 아닐 경우 자신의 신고 현황만 출력
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
							sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target)
							sender:PrintMessage(HUD_PRINTTALK, "\t\t\t처리됨")
							file.Delete("polices/" .. v)
						else
							local reason = ""
							for v in string.gfind(data, "신고 사유: ([^\r]+)\r\n") do
								reason = v
							end
							sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target)
							sender:PrintMessage(HUD_PRINTTALK, "\t\t\t사유: " .. reason)
							sender:PrintMessage(HUD_PRINTTALK, "\t\t\t처리 안 됨")
						end
					end
				// 어드민일 경우 모두의 신고 현황 출력
				else
					local data = file.Read("polices/" .. v)
					local processed = string.find(data, "processed")
					local target = ""
					local id = ""
					for v in string.gfind(data, "신고 대상자: ([^\n]+)\n") do
						target = v
					end
					for v in string.gfind(data, "ID: ([^\n]+)\n?") do
						id = v
					end
					if processed then
						sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target)
						sender:PrintMessage(HUD_PRINTTALK, "\t\t\t처리됨")
						if string.find(v, HPolice.ReplaceSteamID(sender:SteamID())) then
							file.Delete("polices/" .. v)
						end
					else
						local reason = ""
						for v in string.gfind(data, "신고 사유: ([^\r]+)\r\n") do
							reason = v
						end
						sender:PrintMessage(HUD_PRINTTALK, tostring(i) .. "\t\t신고 대상: " .. target)
						sender:PrintMessage(HUD_PRINTTALK, "\t\t\t사유: " .. reason)
						sender:PrintMessage(HUD_PRINTTALK, "\t\t\tID: " .. id)
						sender:PrintMessage(HUD_PRINTTALK, "\t\t\t처리 안 됨")
					end
				end
			end
		elseif (exploded[1] == "!신고기각" or exploded[1] == "!신고각하") and (sender == NULL or sender:IsAdmin()) then
			if sender:IsPlayer() then
				sender:ConCommand("hpolice_cancel " .. exploded[2])
			else
				HPolice.CancelPolice(NULL, "hpolice_cancel", {exploded[2]}, "hpolice_cancel " .. exploded[2])
			end
			return ""
		end
	end
	return nil
end
-- hook.Remove("PlayerSay", "HookPoliceSay", HPolice.HookPoliceSay)
hook.Add("PlayerSay", "HookPoliceSay", HPolice.HookPoliceSay)

// 신고 접수가 성공적으로 이뤄졌는지 확인하는 함수
HPolice.CheckIfSuccess = function(filename, sender, target, reason, delay)
	if !delay then
		delay = 0.5
	end
	
	sender:PrintMessage(HUD_PRINTTALK, "신고 접수중입니다...")
	
	timer.Create("CheckIfPoliceWasSuccess#" .. filename, delay, 1, function()
		if file.Exists(filename, "DATA") then
			sender:PrintMessage(HUD_PRINTTALK, "신고가 정상적으로 접수되었습니다.")
			ulx.logString(sender:Nick() .. "(" .. sender:SteamID() .. ")" .. "님께서 성공적으로 신고를 접수하였습니다. [대상: " .. tostring(target) .. ", 사유: " .. reason .. "]")
		else
			sender:PrintMessage(HUD_PRINTTALK, "신고 접수 중 오류가 발생했습니다. 다시 신고해주세요.")
			sender:PrintMessage(HUD_PRINTTALK, "이와 같은 일이 반복된다면 홈페이지에 버그 리포팅을 해주시기 바랍니다.")
		end
	end)
end

// 잘못된 신고 캔슬
HPolice.CancelPolice = function(pl, cmd, args, fulltext)
	if pl == NULL or pl:IsAdmin() or pl:IsSuperAdmin() then
		local id = tostring(args[1])
		
		if string.match(id, "^%d+$") == nil then
			if pl:IsPlayer() then
				pl:PrintMessage(HUD_PRINTTALK, "ID는 숫자로만 구성돼야 합니다.")
				return false
			else
				MsgC(Color(255, 0, 0), "ID must be consisted by digits!\n")
				return false
			end
		end
		
		local policeFile = HPolice.MatchedPoliceFile(id)
		if policeFile then
			file.Delete("polices/" .. policeFile)
			if pl:IsPlayer() then
				pl:PrintMessage(HUD_PRINTTALK, "신고 파일 [" .. policeFile .. "], 제거됨.")
			else
				MsgC(Color(0, 255, 0), "File was deleted. [" .. policeFile .. "]")
			end
			return true
		end
		if pl:IsPlayer() then
			pl:PrintMessage(HUD_PRINTTALK, "해당 ID와 매치되는 신고 파일을 찾을 수 없음.")
		else
			MsgC(Color(255, 0, 0), "Couldn't find matched file.\n")
		end
		return false
	end
end

// 신고 ID 가져오기
HPolice.MatchedPoliceFile = function(id)
	local files = file.Find("polices/*.txt", "DATA")
	local returnFile = false
	
	for _, f in pairs(files) do
		local data = file.Read("polices/" .. f)
		local exploded = string.Explode("\n", data)
		for i, w in pairs(exploded) do
			if string.find(w, "ID:%s+%d+") then
				if string.Explode("ID:%s", w, true)[2] == tostring(id) then
					returnFile = f
					break
				end
			end
		end
		if isstring(returnFile) then
			break
		end
	end
	return returnFile
end

MsgC(Color(0, 255, 0), "Complete!\n")