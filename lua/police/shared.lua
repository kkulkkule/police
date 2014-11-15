HPolice = {}

HPolice.ReplaceSteamID = function(steamid)
	return string.Replace(string.Replace(steamid, "\"", "-"), ":", "_")
end