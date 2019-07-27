script_name("E.D.I.T.H.")
script_author("Anthony Edward Stark")
script_description("E.D.I.T.H. или же Э.Д.И.Т. (с английского: Even in Death, I'm The Hero: Даже в Смерти Я Герой) - это пользовательский интерфейс для всей сети Stark Industries, который предоставляет пользователю полный доступ ко всей сети спутников Stark Industries, а также несколько входов в чёрный ход нескольких крупнейших мировых телекоммуникационных компаний, предоставляя пользователю доступ ко всей личной информации цели. Всех доступных целей. Размещёна в солнцезащитные очки.")

local player = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/pla.png')
local matavoz = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/matavoz.png')
local resX, resY = getScreenResolution()
print(resX, resY)
if resX > 1024 and resY >= 1024 then
  bX = (resX - 1024) / 2
  bY = (resY - 1024) / 2
  size = 1024
  map = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/map1024.png')
elseif resX > 720 and resY >= 720 then
  bX = (resX - 720) / 2
  bY = (resY - 720) / 2
  size = 720
  map = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/map720.png')
else
  bX = (resX - 512) / 2
  bY = (resY - 512) / 2
  size = 512
  map = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/map512.png')
end
local copas = require 'copas'
local http = require 'copas.http'
local requests = require 'requests'
requests.http_socket, requests.https_socket = http, http

function httpRequest(method, request, args, handler) -- lua-requests
  -- start polling task
  if not copas.running then
    copas.running = true
    lua_thread.create(function()
      wait(0)
      while not copas.finished() do
        local ok, err = copas.step(0)
        if ok == nil then error(err) end
        wait(0)
      end
      copas.running = false
    end)
  end
  -- do request
  if handler then
    return copas.addthread(function(m, r, a, h)
      copas.setErrorHandler(function(err) h(nil, err) end)
      h(requests.request(m, r, a))
    end, method, request, args, handler)
  else
    local results
    local thread = copas.addthread(function(m, r, a)
      copas.setErrorHandler(function(err) results = {nil, err} end)
      results = table.pack(requests.request(m, r, a))
    end, method, request, args)
    while coroutine.status(thread) ~= 'dead' do wait(0) end
    return table.unpack(results)
  end
end
function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(100) end
	if sampGetCurrentServerAddress() != "gta.ru" or sampGetCurrentServerAddress() != "185.169.134.11" then
		print("сервер не поддерживается")
		return end
	end
	asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
	licensenick = sampGetPlayerNickname(licenseid)
	sampAddChatMessage("E.D.I.T.H. к вашим услугам. Подробная информация: /edith. Приятной игры, "..licensenick..".", -1)
  a = getCharHeading(playerPed)
  inspect = require "inspect"
  lua_thread.create(
    function()
      --      print(inspect(data))
      a = true
      while a do
        wait(250)
        data = {}
        asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
        licensenick = sampGetPlayerNickname(licenseid)
        x, y, z = getCharCoordinates(playerPed)
        table.insert(data, {sender = licensenick, pos = {x = x, y = y, z = z}, heading = getCharHeading(playerPed)})
        local response, err = httpRequest('POST', {'http://localhost:1488', data = encodeJson(data)})
        if err then print(err) end
        --local json_data = response.json()
        print(inspect(decodeJson(response.text)))
        --a = false
      end
    end
  )

  while true do
    wait(0)
    x, y = getCharCoordinates(playerPed)
    if isKeyDown(77) then
      renderDrawTexture(map, bX, bY, size, size, 0, - 1)
      renderDrawTexture(matavoz, getX(0), getY(0), 16, 16, 0, - 1)
      renderDrawTexture(player, getX(x), getY(y), 16, 16, - getCharHeading(playerPed), - 1)
    end
  end
end

function getX(x)
  x = math.floor(x + 3000)
  return bX + x * (size / 6000) - 8
end

function getY(y)
  y = math.floor(y * - 1 + 3000)
  return bY + y * (size / 6000) - 8
end
