local socket = require "socket"
local udp = socket.udp()

udp:settimeout(0)
udp:setsockname('*', 45165)

local games = {} 
local data, msg_or_ip, port_or_nil
local entity, cmd, parms, code, ent
local hosts = {}

local running = true

function checkIfInGame(code, user)
	for client in pairs(games[code]) do
		print(client, user)
		if client == user then
			print("MEOW")
			return true
		end
	end
end

function getSentence()
	local sentences = {}
	for line in io.lines("sentences.txt") do
		table.insert(sentences, line)
	end
	local sentence_number = #sentences
	if sentence_number > 0 then
		local random_index = math.random(1, sentence_number)
		return sentences[random_index]
	end
end

function makeBlank(sentence)
	local words = {}

	for i=#sentence, 1, -1 do
		if sentence:sub(i, i) == " " then
			words[#words + 1] = i
		end
	end
	random_word = math.random(1, #words)
	start_pos = words[random_word]
	end_pos = sentence:find(" ", start_pos)
	blanked_word = sentence:sub(1, start_pos) .. "___" .. sentence:sub(end_pos, #sentence)
	return blanked_word
end

function updateRoundTime()
	for i=1, #hosts do
		if hosts[i].active and hosts[i].running == true then
			local current_time = os.time()
			if current_time - hosts[i].last_update >= 1 and games[i] ~= {} then
				hosts[i].round_seconds = hosts[i].round_seconds - 1
				hosts[i].last_update = current_time
				sendToAll(i, string.format("placeholder %s %s", 'time', hosts[i].round_seconds), true)
				print("Round seconds for game ", i, ":", hosts[i].round_seconds)  -- Debug print
			end
		end
	end
end

function sendToAll(code, msg, send_to_host)
	for _, client in pairs(games[code]) do
		if type(client) == "table" then
			udp:sendto(msg, client.ip, client.port)
			print(string.format("Sent %s to client %s:%s", msg, client.ip, client.port))
		end
		if send_to_host and hosts[code].active then
			udp:sendto(msg, hosts[code].ip, hosts[code].port)
			print(string.format("Sent %s to host %s:%s", msg, hosts[code].ip, hosts[code].port))
		end
	end
end

function notifyEntityRemoval(code, entity)
	for _, client in pairs(games[code]) do
		sendToAll(code, string.format("%s %s u", entity, 'remove'), true)
	end
end

function cleanupLocalEntity(code, entity)
	-- Print debug info
	print("Cleaning up local reference to: " .. entity .. " in game: " .. code)

	-- Notify clients about entity removal
	notifyEntityRemoval(code, entity)

	-- Remove from world table
	games[code][entity] = nil

	-- Clear any local references to this entity
	if localEntityData then localEntityData[entity] = nil end
	if entitySprites then entitySprites[entity] = nil end
	if entitySounds then entitySounds[entity] = nil end

	-- Clear any targeting or interaction references
	if selectedEntity == entity then selectedEntity = nil end
	if targetEntity == entity then targetEntity = nil end

	-- Clear any queued actions involving this entity
	if actionQueue then
		for i = #actionQueue, 1, -1 do
			if actionQueue[i].target == entity then
				table.remove(actionQueue, i)
			end
		end
	end

	-- Force garbage collection (optional)
	collectgarbage("collect")

	-- Verify cleanup
	print("Local entity cleanup complete. Verifying removal:", entity)
	print("Entity entry exists:", games[code][entity] ~= nil)
end

print "Beginning server loop."
while running do
	updateRoundTime()

    data, msg_or_ip, port_or_nil = udp:receivefrom()
	if data then
		-- more of these funky match paterns!
		entity, cmd, parms = data:match("^(%S*) (%S+) (.*)")
		if cmd == 'quit' then
			code = tonumber(parms:match("([^%s]+)"))
			cleanupLocalEntity(code, entity)
			print(entity ..  " left.")
        elseif cmd == 'new' then
			local code = #games + 1
			print("Created new game with code: ", code)
			games[code] = {}
			hosts[code] = {ip = msg_or_ip, port = port_or_nil, active = true, running = false, round_seconds = -1}
            udp:sendto(string.format("%s %s %i", 'game', 'code', code), msg_or_ip, port_or_nil)
		elseif cmd == 'start' then
			code = tonumber(parms:match("([^%s]+)"))
			print("Starting game: ", code)
			hosts[code].running = true
			hosts[code].round_seconds = 60
			hosts[code].round = 1
			hosts[code].start_time = os.time()
			hosts[code].last_update = os.time()
			hosts[code].sentence = makeBlank(getSentence())
			sendToAll(code, string.format("placeholder %s %s", 'start', hosts[code].sentence), true)
		elseif cmd == 'end' then
			print("Game " .. parms .. " is closing.")
			if games[code] then
				games[code].active = false
				for k, v in pairs(games[code]) do
					cleanupLocalEntity(code, k)
				end
			games[code] = {}
			end
		elseif cmd == 'submit' then
			code, answer = parms:match("^(%S+)%s+(.*)")
			code = tonumber(code)

			current_round = hosts[code].round

			games[code][entity][current_round] = answer

			local dg = string.format("%s %s %i %s", entity, 'answer', current_round, answer)
			sendToAll(code, dg, true)

			print("Received answer: " .. answer .. " from " .. entity .. " in game " .. code .. " .")
			
		elseif cmd == 'join' then
			code = tonumber(parms:match("([^%s]+)"))
			if hosts[code] then
				if hosts[code].active and checkIfInGame(code, entity) ~= false then
					print("Game " .. code .. " is active")
					games[code][entity] = {ip = msg_or_ip, port = port_or_nil, 	points = 0}
					udp:sendto(string.format("placeholder %s %i", 'code', code), msg_or_ip, port_or_nil)
					udp:sendto(string.format("%s %s %s", entity, 'join', entity), hosts[code].ip, hosts[code].port)
				else
					print("Game " .. code .. " is not active")
					udp:sendto(string.format("placeholder %s placeholder", 'dne'), msg_or_ip, port_or_nil)
				end
			else
				print("Game " .. code .. " is not active")
				udp:sendto(string.format("placeholder %s placeholder", 'dne'), msg_or_ip, port_or_nil)
			end
        else
			print("Unrecognised command:", cmd)
		end
	elseif msg_or_ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
	end
	
	socket.sleep(0.01)
end

print "Thank you."