HPolice = {}

HPolice.ReplaceSteamID = function(steamid)
	return string.Replace(string.Replace(steamid, "\"", "-"), ":", "_")
end

HPolice.ReplaceSpaceChar = function(str)
	return string.Replace(str, "%s", "")
end