MsgC(Color(0, 255, 0), "Initialize Police Module...\n")
include("shared.lua")

POLICE_URL = "http://kkulkkule.dyndns.info:8282/hlds/admin/police"
GAME_NAME = "zs"

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
				-- if string.find(string.upper(exploded[2]), "STEAM_%d:%d:%d+$") then
					-- local steamid = exploded[2]
					-- for _, v in pairs(player.GetAll()) do
						-- if string.upper(v:SteamID()) == string.upper(steamid) then
							-- target = v
							-- break
						-- end
					-- end
					
					-- if target == NULL then
						-- target = steamid
					-- end
					
					-- local reasonTable = {}
					-- for i = 3, table.Count(exploded) do
						-- table.insert(reasonTable, exploded[i])
					-- end
					-- reason = table.concat(reasonTable, " ")
				-- // 닉네임 형식일 경우 처리
				-- else
					-- local targets = {}
					-- for _, v in pairs(player.GetAll()) do
						-- if string.find(string.lower(v:Nick()), string.lower(exploded[2])) then
							-- table.insert(targets, v)
						-- end
					-- end
					-- // 예외처리
					-- if table.Count(targets) > 1 then
						-- sender:PrintMessage(HUD_PRINTTALK, "해당 문자열을 포함한 닉네임의 유저가 두 명 이상입니다.")
						-- sender:PrintMessage(HUD_PRINTTALK, "고유번호를 통해 신고해주세요.")
						-- sender:PrintMessage(HUD_PRINTTALK, "고유번호는 !고번 혹은 !고유번호라고 치면 출력됩니다.")
					-- elseif table.Count(targets) <= 0 then
						-- sender:PrintMessage(HUD_PRINTTALK, "해당 문자열을 포함한 닉네임의 유저가 없습니다.")
						-- sender:PrintMessage(HUD_PRINTTALK, "고유번호를 통해 신고해주세요.")
						-- sender:PrintMessage(HUD_PRINTTALK, "고유번호는 !고번 혹은 !고유번호라고 치면 출력됩니다.")
					-- // 플레이어 추출에 성공할 경우 사유를 보기 좋게 가공
					-- else
						-- target = targets[1]
						-- local reasonTable = {}
						-- for i = 3, table.Count(exploded) do
							-- table.insert(reasonTable, exploded[i])
						-- end
						-- reason = table.concat(reasonTable, " ")
					-- end
				local reason = ""
				if exploded[3] then
					for i, v in pairs(exploded) do
						if i < 3 then
							continue
						end
						reason = reason .. " " .. v
					end
				end
				http.Post(POLICE_URL, {game = GAME_NAME, action = "receive", reporter = sender:SteamID(), reported = exploded[2], reason = reason}, function(body, len, headers, status) 
					sender:PrintMessage(HUD_PRINTTALK, "신고 접수됨.")
				end, function(body, len, headers, status)
					sender:PrintMessage(HUD_PRINTTALK, "신고 서버가 꺼져 있어 신고를 접수할 수 없습니다. 어드민에게 문의하세요.")
				end)
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
			http.Post(POLICE_URL, {game = GAME_NAME, action = "viewPolices", isAdmin = tostring(sender:IsAdmin()), requester = sender:SteamID()}, function(body, len, headers, status)
				local eachPolices = string.Explode("\n\n", body)
				if #eachPolices > 0 then
					sender:PrintMessage(HUD_PRINTTALK, "//////////////////////////////////////////")
					sender:PrintMessage(HUD_PRINTTALK, "//////////////////////////////////////////")
				end
				for _, v in pairs(eachPolices) do
					local eachLines = string.Explode("\n", v)
					for _, w in pairs(eachLines) do
						sender:PrintMessage(HUD_PRINTTALK, w)
					end
					sender:PrintMessage(HUD_PRINTTALK, "//////////////////////////////////////////")
				end
			end, function()
				sender:PrintMessage(HUD_PRINTTALK, "신고할 수 없습니다. 어드민에게 문의하세요.")
			end)
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
		string.Replace(id, "\r", "")
		string.Replace(id, "\n", "")
		string.Replace(id, " ", "")
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