local currentResource = GetCurrentResourceName()
if currentResource ~= "Masked-Queue" then
    print("^1=============================================^0")
    print("^1[Masked-Queue ERROR]^0")
    print("^1Skripta mora biti u folderu nazvanom 'Masked-Queue'!^0")
    print("^1Trenutni naziv: " .. (currentResource or "Kuvarica nepoznato") .. "^0")
    print("^1Skripta se gasi...^0")
    print("^1=============================================^0")
    Citizen.Wait(1000)
    return 
end

local requiredVersion = "2.0"
local scriptVersion = "2.0"
if scriptVersion ~= requiredVersion then
    print("^1Nepodobna verzija skripte!^0")
    return
end

print("^3[Masked-Queue]^0: Provera foldera prosla ✓")
print("^3[Masked-Queue]^0: Ucitavanje...")

local emojis = {
    [1] = "\xF0\x9F\x95\x9C",
    [2] = "\xF0\x9F\x95\x9D",
    [3] = "\xF0\x9F\x95\x9E",
    [4] = "\xF0\x9F\x95\x9F",
    [5] = "\xF0\x9F\x95\xA0",
    [6] = "\xF0\x9F\x95\xA1",
    [7] = "\xF0\x9F\x95\xA2",
    [8] = "\xF0\x9F\x95\xA3",
    [9] = "\xF0\x9F\x95\xA4",
    [10] = "\xF0\x9F\x95\xA5",
    [11] = "\xF0\x9F\x95\xA6",
    [12] = "\xF0\x9F\x95\xA7",

}

local queueLista = {}
local PriorityRoles = {
    ["1450802898270425088"] = 500, -- veci broj veca pozicija u queue / tipa 1000 , 500, 250 , 50
}

local wlRole = "1450802866083332158" -- Role Whitelista
local CrashList = {}
local deferalLista = {}
local PlayersNumber = #GetPlayers()
local QueueLength = 0


local GuildID = "TU" -- ID od servera (discord)
local DiscToken = "ODJE" -- TOKEN OD BOT-A
local FormattedToken = "Bot " .. DiscToken



function DiscordRequest(method, endpoint, jsondata)
    local data = nil

    PerformHttpRequest("https://discordapp.com/api/"..endpoint, function(errorCode, resultData, resultHeaders)
        data = {data=resultData, code=errorCode, headers=resultHeaders}
    end, method, #jsondata > 0 and json.encode(jsondata) or "", {["Content-Type"] = "application/json", ["Authorization"] = FormattedToken})

    while data == nil do
        Citizen.Wait(0)
    end

    return data
end

function DiscordUserData(id)

	local id = string.gsub(id, "discord:", "")
    local member = DiscordRequest("GET", ("guilds/%s/members/%s"):format(GuildID, id), {})
    if member.code == 200 then
        local Userdata = json.decode(member.data)
        return Userdata
    else
    	return false
    end
end


function GetPriorityDiscord(data)
	for i = 1, #data.roles do
		if PriorityRoles[data.roles[i]] then
			return PriorityRoles[data.roles[i]]
		end
	end
	return 1
end


 

function GetDiscordWhitelist(data)
	for i = 1, #data.roles do
		if wlRole == data.roles[i] then
			return true
		end
	end
	return false
end

function ConsoleLog(text)
	print(string.format("\n----------------------------------------------------\n^3[ Masked-Queue ]:^7 %s\n----------------------------------------------------", text))
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(15000)

        for k,v in pairs(CrashList) do 
            if os.time() >= v.dropped then
                CrashList[k] = nil
                ConsoleLog(string.format("%s je obrisan iz crash prio", k))
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
    	PlayersNumber = #GetPlayers() + countTable()
        Citizen.Wait(5000)
    end
end)

function countTable()
    local count = 0
    for _, _ in pairs(CrashList) do
        count = count + 1
    end
    return count
end

function spairs(t, order)
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function AnIndexOf(val)
    local indexVal = 1
    for k,v in spairs(queueLista, function(t,a,b) return t[b].level < t[a].level end) do
        if k == val then
            return indexVal
        end
        indexVal = indexVal +1
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local qL = 0

        for _,_ in pairs(queueLista) do
            qL = qL + 1
        end

        QueueLength = qL
    end
end)


local function OnPlayerConnecting(name, setKickReason, deferrals)

	if QueueLength > 50 then
		deferrals.done("\n\nIzvinjavamo se, queue je popunjen ima maksimalan broj igraca, pokusaj te kasnije <3 :(")
		return
	end

    local player = source
    local steamIdentifier, discordidentifier
    local identifiers = GetPlayerIdentifiers(player)
    local setKickReason = setKickReason
    local deferrals = deferrals

    deferrals.defer() Wait(10) deferrals.update("Provera ID-A: ...")

    for _, v in pairs(identifiers) do
        if string.find(v, "steam") then
            steamIdentifier = v
        end

        if string.find(v, "discord") then
            discordidentifier = v
        end 
    end
   
    if not steamIdentifier then
        deferrals.done("\nNije moguce pronaci Steam\n\nNemas upaljen Steam klijent ili je trenutno steam down.\nProveri status -> https://steamstat.us")
        return
    end
    if not discordidentifier then
        deferrals.done("Nije moguce pronaci Discord\n\nProvjeri da li je Discord povezan sa FiveM-om i da je Aplikacija Discord upaljena!")
        return
    end

    Wait(500)
    deferrals.update("Provera ...") Wait(10)


    if BanStatus then
    	deferrals.done(message)
        return
    end

    local DiscordData = DiscordUserData(discordidentifier)

    if not DiscordData then   -- tu stavite vas invite
        deferrals.done("\n\nNisi na discordu: https://github.com/masked1337")
        return
    end 
                                               -- tu stavite vas invite
    if not GetDiscordWhitelist(DiscordData) then
        deferrals.done("\n\nNisi na Discordu: https://github.com/masked1337")
        return
    end

    Citizen.CreateThread(function()
    	local delayTime = os.time() + 5

        local function formatTime(seconds)
          local minutes = math.floor(seconds / 60) 
          seconds = seconds - minutes * 60
          
          return string.format("%02d : %02d", minutes, seconds)
        end

        local src = player
        local timer = 0
        local odbijanje = deferrals
        local emojiTimer = 1
        local mojSteam = steamIdentifier

        if not src or not mojSteam then
            deferrals.done("\n\nGreska: Konekcija Error.X00941")
            return
        end

        if not GetPlayerName(src) then
            deferrals.done("\n\nGreska: Konekcija Error.X00941")
            return
        end

        queueLista[mojSteam] = {level = WasPlayerDropped(mojSteam) or GetPriorityDiscord(DiscordData)}
        deferalLista[mojSteam] = odbijanje

        ConsoleLog("Igrac "..GetPlayerName(src).." je dodan u Queue list sa levelom " .. queueLista[mojSteam].level .. " na mjesto: " .. AnIndexOf(mojSteam))
  
        while true do
            Citizen.Wait(1000)

            if not GetPlayerName(player) then
                queueLista[mojSteam] = nil
                deferalLista[mojSteam] = nil
                deferrals.done("\n\nGreska: Konekcija Error.X00941")
                return
            end

            timer = timer + 1
            deferalLista[mojSteam].update(" Queue \xE2\x9C\x88\n\nQueue pozicija: ".. AnIndexOf(mojSteam) .."/".. QueueLength .." | Broj Igraca: ".. PlayersNumber .. " / " .. GetConvarInt('sv_maxclients', 5).. "\n\nVrijeme cekanja: "..formatTime(timer) .. " " .. emojis[emojiTimer])
            Wait(10)

            emojiTimer = emojiTimer + 1
            if emojiTimer > 12 then
                emojiTimer = 1
            end

            if (os.time() >= delayTime) and AnIndexOf(mojSteam) == 1 and PlayersNumber < GetConvarInt('sv_maxclients', 5) then
                if ConnectMe(mojSteam) then
                    return
                end
            end
        end
    end)
end

function ConnectMe(steam)

    if PlayersNumber < GetConvarInt('sv_maxclients', 5) - 1 then
        if not NekoLoada then
            deferalLista[steam].done()

            deferalLista[steam] = nil
	        queueLista[steam] = nil
            return true
        end
    else
        return true
    end
    return false
end

function WasPlayerDropped(steam)
    
    if CrashList[steam] then
        local tempPrior = CrashList[steam].level
        ConsoleLog( string.format("%s se diskonektovao u %s i dobija crash priority od %d", steam, os.date('%H:%M:%S', CrashList[steam].dropped), tempPrior))

        CrashList[steam] = nil
        return tempPrior
    end
    return false
end 

local function OnPlayerDrop(reason)
    local src = source
    local steamID = GetPlayerIdentifier(src)
    CrashList[steamID] = {level=75, dropped = os.time() + 30}

    if steamID == NekoLoada then
        NekoLoada = false
    end
end

AddEventHandler("playerConnecting", OnPlayerConnecting)
AddEventHandler("playerDropped", OnPlayerDrop)

StopResource("hardcap")
print("^3[Masked-Queue]^0: Queue je aktivan! Kuvarica potpisuje!")
print("^3[Masked-Queue]^0: Hvala vam sto koristite Masked-Queue!")