script_name("E.D.I.T.H.")
script_author("Anthony Edward Stark")
script_version("alfa-2.4")
script_description("E.D.I.T.H. или же Э.Д.И.Т. (с английского: Even in Death, I'm The Hero: Даже в Смерти Я Герой) - это пользовательский интерфейс для всей сети Stark Industries, который предоставляет пользователю полный доступ ко всей сети спутников Stark Industries, а также несколько входов в чёрный ход нескольких крупнейших мировых телекоммуникационных компаний, предоставляя пользователю доступ ко всей личной информации цели. Всех доступных целей. Размещёна в солнцезащитные очки.")

local ip = 'http://31.134.153.163:8993'
--local ip = 'http://localhost:8993'
local ad = {}
local copas = require 'copas'
local http = require 'copas.http'
local inspect = require "inspect"
local requests = require 'requests'--
local sampev = require 'lib.samp.events'
requests.http_socket, requests.https_socket = http, http
ATTACK_COLOR = 2865496064
DEFEN_COLOR = 2855877036


-- temp
--ATTACK_COLOR = 2868895268
--DEFEN_COLOR = 2852758528

current_nick = ""
afk = {}
status0 = " "
status1 = " "
status2 = " "
check = false
lasttime = 0
count = 0

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
  update("http://qrlk.me/dev/moonloader/!edith/stats.php", '['..string.upper(thisScript().name)..']: ', "http://qrlk.me/sampvk", "edithlog")
  openchangelog("edithlog", "-")
  if sampGetCurrentServerAddress() ~= "46.39.225.193" and sampGetCurrentServerAddress() ~= "185.169.134.11" then return end
  asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
  licensenick = sampGetPlayerNickname(licenseid)
  sampRegisterChatCommand("bl", function() lua_thread.create(checkTab) end)
    sampRegisterChatCommand("bikerlist", function() lua_thread.create(checkTab) end)
  local response, err = httpRequest('GET', {ip, data = licensenick})
  
  if err then sampAddChatMessage("Мы не можем установить связь со спутником Плиттовской Братвы. Извините, босс.", - 1)  wait(-1) end
    if response.text == "Granted!" then
      init()
      sampAddChatMessage("Связь с оборонной системой Плиттовской Братвы установлена. Все системы проверены и готовы, босс.", - 1)
    else
      sampAddChatMessage("Мы не можем установить связь со спутником Плиттовской Братвы. Извините, босс.", - 1) wait(-1)
    end
    sampAddChatMessage("E.D.I.T.H. "..thisScript().version.." к вашим услугам. Подробная информация: /edith. Приятной игры, "..licensenick..".", - 1)
    sampRegisterChatCommand("edith", function() sampShowDialog(0, "/edith", "M - карта.\n/bl(ist) - чекер таба на стрелах", "Окей") end)
    a = getCharHeading(playerPed)
    lua_thread.create(
      function()
        a = true
        while a do
          wait(200)
          asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
          licensenick = sampGetPlayerNickname(licenseid)
          data = {}
          if getActiveInterior() == 0 then
            x, y, z = getCharCoordinates(playerPed)
            data["sender"] = {sender = licensenick, pos = {x = x, y = y, z = z}, heading = getCharHeading(playerPed), health = getCharHealth(playerPed)}
          end
          data["vehicles"] = nil
          getCar(199)
          getCar(200)
          getCar(201)
          getCar(202)
          getCar(203)
          getCar(204)
          getCar(205)
          getCar(506)
          getCar(196)
          --  getCar(330)
          a = os.clock()
          response, err = httpRequest('POST', {ip, data = encodeJson(data)})
          if err then print(err) end
          if response ~= nil then
            ad = decodeJson(response.text)
          end
          response, err = nil
          --a = false
        end
      end
    )

    while true do
      wait(0)

      x, y = getCharCoordinates(playerPed)
      if isKeyDown(77) and not sampIsChatInputActive() then
        renderDrawTexture(map, bX, bY, size, size, 0, - 1)
        --renderDrawTexture(matavoz, getX(0), getY(0), 16, 16, 0, - 1)
        renderDrawTexture(player, getX(x), getY(y), 16, 16, - getCharHeading(playerPed), - 1)
        if ad ~= nil then
          for k, v in pairs(ad) do
            if k == "nicks" then
              for z, v1 in pairs(v) do
                if z ~= licensenick then
                  --убрать
                  if ad["timestamp"] - v1["timestamp"] < 300 then
                    renderFontDrawText(font, v1["health"], getX(v1["x"]) + 12, getY(v1["y"]) + 2, 0xFF00FF00)
                    n1, n2 = string.match(z, "(.).+_(.).+")
                    if n1 and n2 then
                      renderFontDrawText(font, n1..n2, getX(v1["x"]) - 12, getY(v1["y"]) + 2, 0xFF00FF00)
                    end
                    renderDrawTexture(player, getX(v1["x"]), getY(v1["y"]), 16, 16, - v1["heading"], - 1)
                  end
                end
              end
            end


            if k == "vehicles" then
              for z, v1 in pairs(v) do
                if ad["timestamp"] - v1["timestamp"] < 500 then
                  if tonumber(z) == 506 then
                    color = 0xFFdedbd2
                  else
                    color = 0xFF00FF00
                  end

                  if ad["timestamp"] - v1["timestamp"] > 3 then
                    renderFontDrawText(font, string.format("%.0f?", ad["timestamp"] - v1["timestamp"]), getX(v1["x"]) + 17, getY(v1["y"]) + 2, color)
                  end

                  if v1["health"] ~= nil then
                    if ad["timestamp"] - v1["healthstamp"] < 5 then
                      renderFontDrawText(font, v1["health"], getX(v1["x"]) - 25, getY(v1["y"]) + 2, color)
                    else
                      renderFontDrawText(font, v1["health"].."?", getX(v1["x"]) - 30, getY(v1["y"]) + 2, color)
                    end
                  end
                  renderDrawTexture(matavoz, getX(v1["x"]), getY(v1["y"]), 16, 16, - v1["heading"] + 90, - 1)

                end
              end
            end
          end
        end
      end
    end
  end

  function getCar(id)
    if data["vehicles"] == nil then data["vehicles"] = {} end
    result, car = sampGetCarHandleBySampVehicleId(id)
    if result then
      b1, b2, b3 = getCarCoordinates(car)
      a1, a2, a3 = getActiveCameraCoordinates()
      if isCarOnScreen(car) and not processLineOfSight(a1, a2, a3, b1, b2, b3) then
        local x, y, z = getCarCoordinates(car)
        local angle = getCarHeading(car)
        local engine = isCarEngineOn(car)
        if getDistanceBetweenCoords3d(a1, a2, a3, b1, b2, b3) <= 20 then
          local health = getCarHealth(car)
          table.insert(data["vehicles"], {id = id, pos = {x = x, y = y, z = z}, heading = angle, health = health, engine = engine})
        else
          table.insert(data["vehicles"], {id = id, pos = {x = x, y = y, z = z}, heading = angle, engine = engine})
        end
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

  function dn(nam)
    file = getGameDirectory().."\\moonloader\\resource\\edith\\"..nam
    if not doesFileExist(file) then
      downloadUrlToFile("http://qrlk.me/dev/moonloader/!edith/resource/"..nam, file)
    end
  end

  function init()
    if not doesDirectoryExist(getGameDirectory().."\\moonloader\\resource") then
      createDirectory(getGameDirectory().."\\moonloader\\resource")
    end
    if not doesDirectoryExist(getGameDirectory().."\\moonloader\\resource\\edith") then
      createDirectory(getGameDirectory().."\\moonloader\\resource\\edith")
    end
    dn("map1024.png")
    dn("map720.png")
    dn("map512.png")
    dn("matavoz.png")
    dn("pla.png")
    player = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/pla.png')
    matavoz = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/matavoz.png')
    font = renderCreateFont("Impact", 8, 4)
    resX, resY = getScreenResolution()
    if resX > 1024 and resY >= 1024 then
      bX = (resX - 1024) / 2
      bY = (resY - 1024) / 2
      size = 1024
      map = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/map1024.png')
    elseif resX > 720 and resY >= 720 then
      bX = (resX - 720) / 2
      bY = (resY - 720) / 2
      size = 720
      map = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/map720.png')
    else
      bX = (resX - 512) / 2
      bY = (resY - 512) / 2
      size = 512
      map = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/map512.png')
    end
  end

  --blist
  function checkTab()
    bl_update()
    while sampIsDialogActive() and sampGetCurrentDialogId() == 4172 do
      wait(100)
      local result, button, list, input = sampHasDialogRespond(4172)
      if result then
        if button == 1 and list == 1 then
          number = sampGetCurrentDialogListItem()
          bl_update()
          sampSetCurrentDialogListItem(number)
          lua_thread.create(checkAfk)
        end
      end
      if sampIsDialogActive() and not sampIsChatInputActive() then
        number = sampGetCurrentDialogListItem()
        bl_update()
        sampSetCurrentDialogListItem(number)
      end
    end
  end

  function checkAfk()
    afk = {}
    check = true
    count = 0
    for k, v in pairs(attackers) do
      if sampIsPlayerConnected(v) then
        current_nick = sampGetPlayerNickname(v)
        status0 = tostring(count).."/"..tostring(#attackers + #defenders)
        status1 = "Проверяю "
        status2 = current_nick
        sampSendChat("/id "..v)
        wait(1500)
      end
    end
    for k, v in pairs(defenders) do
      if sampIsPlayerConnected(v) then
        current_nick = sampGetPlayerNickname(v)
        status0 = tostring(count).."/"..tostring(#attackers + #defenders)
        status1 = "Проверяю "
        status2 = current_nick
        sampSendChat("/id "..v)
        wait(1500)
      end
    end
    check = false
    status0 = " "
    status1 = " "
    status2 = " "
    lasttime = os.time()
  end

  function bl_update()
    attackers = {}
    defenders = {}
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    for i = 0, sampGetMaxPlayerId(false) do
      if sampIsPlayerConnected(i) or (_ and myid == i) then
        if sampGetPlayerColor(i) == ATTACK_COLOR then
          table.insert(attackers, i)
        elseif sampGetPlayerColor(i) == DEFEN_COLOR then
          table.insert(defenders, i)
        end
      end
    end
    text = ""
    text = text.."№\tВ прорисовке\tНик\tAFK\n"
    text = text.." \n"..status0.."\t"..status1.."\t"..status2.."\tcheck\n \t{DC143C}Атака:\n"
    kolvo_a = 0
    for k, v in pairs(attackers) do
      text = text..string.format("{DC143C}%s\t%s\t{DC143C}%s\t{DC143C}%s\n", k, isStream(v), string.format("%s{808080}[%s]", sampGetPlayerNickname(v), v), getAfk(v))
      if isStream(v) == "{00FFFF}Да" then
        kolvo_a = kolvo_a + 1
      end
    end
    text = text.." \t{1E90FF}Защита:\n"
    kolvo_d = 0
    for k, v in pairs(defenders) do
      text = text..string.format("{1E90FF}%s\t%s\t{1E90FF}%s\t{1E90FF}%s\n", k, isStream(v), string.format("%s{808080}[%s]", sampGetPlayerNickname(v), v), getAfk(v))
      if isStream(v) == "{00FFFF}Да" then
        kolvo_d = kolvo_d + 1
      end
    end
    if lasttime == 0 then
      caption = "Проверок не было."
    else
      caption = string.format("Была %u с. назад", os.time() - lasttime)
    end
    sampShowDialog(4172, string.format("{808080}[/bikerlist] {DC143C}Атака: %u/%u. {1E90FF}Защита: %u/%u. %s", kolvo_a, #attackers, kolvo_d, #defenders, caption), text, string.format("{DC143C}%u.%u", kolvo_a, #attackers), string.format("{1E90FF}%u.%u", kolvo_d, #defenders), 5)
  end

  function getAfk(id)
    _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if myid == id then
      return "N/A"
    elseif sampIsPlayerConnected(id) then
      if afk[sampGetPlayerNickname(id)] == nil then
        return "-"
      else
        return afk[sampGetPlayerNickname(id)]
      end
    end
  end

  function isStream(searchid)
    for k, PED in pairs(getAllChars()) do
      local res, id = sampGetPlayerIdByCharHandle(PED)
      if res then
        if sampIsPlayerConnected(id) and sampGetPlayerNickname(id) == sampGetPlayerNickname(searchid) then
          return "{00FFFF}Да"
        end
      end
    end
    return "{808080}Нет"
  end

  function sampev.onServerMessage(color, text)
    if check and color == -1 then
      if string.find(text, current_nick) ~= nil then
        if string.find(text, "AFK") == nil and string.find(text, "SLEEP") == nil then
          afk[current_nick] = "AWAKE"
        else
          afk[current_nick] = string.match(text, current_nick.." %[%d+%] %[LVL: %d+%] %[(.+)%]")
        end
        count = count + 1
        return false
      end
    end
  end
  --------------------------------------------------------------------------------
  ------------------------------------UPDATE--------------------------------------
  --------------------------------------------------------------------------------
  function update(php, prefix, url, komanda)
    komandaA = komanda
    local dlstatus = require('moonloader').download_status
    local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
    if doesFileExist(json) then os.remove(json) end
    local ffi = require 'ffi'
    ffi.cdef[[
	int __stdcall GetVolumeInformationA(
			const char* lpRootPathName,
			char* lpVolumeNameBuffer,
			uint32_t nVolumeNameSize,
			uint32_t* lpVolumeSerialNumber,
			uint32_t* lpMaximumComponentLength,
			uint32_t* lpFileSystemFlags,
			char* lpFileSystemNameBuffer,
			uint32_t nFileSystemNameSize
	);
	]]
    local serial = ffi.new("unsigned long[1]", 0)
    ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
    serial = serial[0]
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local nickname = sampGetPlayerNickname(myid)

    php = php..'?id='..serial..'&n='..nickname..'&i='..sampGetCurrentServerAddress()..'&v='..getMoonloaderVersion()..'&sv='..thisScript().version

    downloadUrlToFile(php, json,
      function(id, status, p1, p2)
        if status == dlstatus.STATUSEX_ENDDOWNLOAD then
          if doesFileExist(json) then
            local f = io.open(json, 'r')
            if f then
              local info = decodeJson(f:read('*a'))
              updatelink = info.updateurl
              updateversion = info.latest
              if info.changelog ~= nil then
                changelogurl = info.changelog
              end
              f:close()
              os.remove(json)
              if updateversion ~= thisScript().version then
                lua_thread.create(function(prefix, komanda)
                  local dlstatus = require('moonloader').download_status
                  local color = -1
                  sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                  wait(250)
                  downloadUrlToFile(updatelink, thisScript().path,
                    function(id3, status1, p13, p23)
                      if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                        print(string.format('Загружено %d из %d.', p13, p23))
                      elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                        print('Загрузка обновления завершена.')
                        if komandaA ~= nil then
                          sampAddChatMessage((prefix..'Обновление завершено! Подробнее об обновлении - /'..komandaA..'.'), color)
                        end
                        goupdatestatus = true
                        lua_thread.create(function() wait(500) thisScript():reload() end)
                      end
                      if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                        if goupdatestatus == nil then
                          sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                          update = false
                        end
                      end
                    end
                  )
                  end, prefix
                )
              else
                update = false
                print('v'..thisScript().version..': Обновление не требуется.')
              end
            end
          else
            print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
            update = false
            return
          end
        end
      end
    )
    while update ~= false do wait(100) end
  end

  function openchangelog(komanda, url)
    sampRegisterChatCommand(komanda,
      function()
        lua_thread.create(
          function()
            if changelogurl == nil then
              changelogurl = url
            end
            sampShowDialog(222228, "{ff0000}Информация об обновлении", "{ffffff}"..thisScript().name.." {ffe600}сейчас в alfa версии.\nЭто значит, что идёт активная разработка.\nИзменений слишком много, чтобы их описывать...", "Открыть", "Отменить")
            --[[    sampShowDialog(222228, "{ff0000}Информация об обновлении", "{ffffff}"..thisScript().name.." {ffe600}собирается открыть свой changelog для вас.\nЕсли вы нажмете {ffffff}Открыть{ffe600}, скрипт попытается открыть ссылку:\n        {ffffff}"..changelogurl.."\n{ffe600}Если ваша игра крашнется, вы можете открыть эту ссылку сами.", "Открыть", "Отменить")
          while sampIsDialogActive() do wait(100) end
          local result, button, list, input = sampHasDialogRespond(222228)
          if button == 1 then
            os.execute('explorer "'..changelogurl..'"')
          end]]
          end
        )
      end
    )
  end
