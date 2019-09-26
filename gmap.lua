script_name("gmap")
script_author("qrlk")
script_version("beta-3.7")
script_url("https://github.com/qrlk/gmap")
script_description("Обмен координатами через сервер.")

--[[ИЗМЕНИТЬ]]
local ip = 'ws://31.134.153.163:9128' -- ЗДЕСЬ СЕРВЕР server.py
local server = "185.169.134.11" -- ЗДЕСЬ СЕРВЕР САМПА
--[[ИЗМЕНИТЬ]]

local ip = 'ws://localhost:9128'
--local ip = 'http://localhost:8993'
local websocket = require 'websocket'
local client = websocket.client.copas({timeout = 2})
local inicfg = require 'inicfg'
local key = require("vkeys")
settings = inicfg.load({
  welcome =
  {
    show = true,
  },
  map =
  {
    toggle = false,
    idfura = 506,
    sqr = false,
    hide = false,
    hide_v = false,
    show = true,
    alpha = 0xFFFFFFFF,
    radar = false,
    alphastring = "100%",
  },
  radar =
  {
    enable = true,
    mode = 3,
    size = 256,
    lift = "В транспорте",
    key1 = 0x7A,
    key2 = 57,
    key3 = 48,
    key4 = 187,
    key5 = 189,
  },
}, 'gmap')

color = 0x7ef3fa
local ad = {}
mode = false


function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(100) end
  
  update("http://qrlk.me/dev/moonloader/!edith/stats.php", '['..string.upper(thisScript().name)..']: ', "http://qrlk.me/sampvk", "gmaplog")
  openchangelog("gmaplog", "-")

  asodkas, playerid = sampGetPlayerIdByCharHandle(PLAYER_PED)
  playernick = sampGetPlayerNickname(playerid)
  serverip, serverport = sampGetCurrentServerAddress()

  if sampGetCurrentServerAddress() ~= server then return end
  asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
  licensenick = sampGetPlayerNickname(licenseid)
  sampRegisterChatCommand("gmap", function() lua_thread.create(function() updateMenu() submenus_show(mod_submenus_sa, '{348cb2}gmap v.'..thisScript().version, 'Выбрать', 'Закрыть', 'Назад') end) end)
  connected, err = client:connect(ip, 'echo')
  if not connected then
    if settings.welcome.show then
      sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}Мы не можем установить связь с сервером. {7ef3fa}/gmap_ - рук-во пользователя.", 0xff0000)
      sampAddChatMessage("{7ef3fa}[GMAP]: "..err, 0xff0000)
    end
    wait(-1)
  else
    local ok = client:send(encodeJson({auth = licensenick}))
    if ok then
      local message, opcode = client:receive()
      if message then
        if message == "Granted!" then
          init()
          if settings.welcome.show then
            sampAddChatMessage("Связь с сервером GMAP установлена. Все системы проверены и готовы, босс.", 0x7ef3fa)
            sampAddChatMessage("GMAP "..thisScript().version.." к вашим услугам. Подробная информация: /gmap. Приятной игры, "..licensenick..".", 0x7ef3fa)
          end
        else
          if settings.welcome.show then
            sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}У вас нет доступа к GMAP Если считаете, что это ошибка, сообщите об этом.", 0xff0000)
          end
          client:close()
          thisScript():unload()
          wait(1000)
        end
      else
        if settings.welcome.show then
          sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}Ошибка соединения с сервером.", 0xff0000)
        end
        client:close()
        thisScript():unload()
        wait(1000)
      end
    else
      if settings.welcome.show then
        sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}Ошибка соединения с сервером.", 0xff0000)
      end
      client:close()
      thisScript():unload()
      wait(1000)
    end
  end

  a = getCharHeading(playerPed)
  lua_thread.create(transponder)
  mapmode = 1
  radarKof = 3
  modX = 2
  modY = 2
  active = false
  while true do
    wait(0)
    x, y = getCharCoordinates(playerPed)
    if settings.map.radar then
      radar()
    end
    if settings.map.show then
      fastmap()
    end
  end
end

function init()
  if not doesDirectoryExist(getGameDirectory().."\\moonloader\\resource") then
    createDirectory(getGameDirectory().."\\moonloader\\resource")
  end
  if not doesDirectoryExist(getGameDirectory().."\\moonloader\\resource\\gmap") then
    createDirectory(getGameDirectory().."\\moonloader\\resource\\gmap")
  end
  dn("map1024.png")
  dn("map720.png")
  dn("map512.png")
  dn("matavoz.png")
  dn("pla.png")
  dn('radar_centre.png')
  dn('radar_girlfriend.png')
  dn('radar_police.png')
  for i = 1, 16 do
    dn(i..".png")
    dn(i.."k.png")
  end
  for i = 1, 24 do
    for z = 1, 24 do
      dn(i.."-"..z..".png")
    end
  end
  for i = 1, 24 do
    for z = 1, 24 do
      loadstring("kv"..tostring(i).."_"..tostring(z).." = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/"..tostring(i).."-"..tostring(z)..".png')")()
    end
  end
  player = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/pla.png')
  player1 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/radar_centre.png')
  radar_girlfriend = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/radar_girlfriend.png')
  radar_police = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/radar_police.png')


  matavoz = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/matavoz.png')
  font = renderCreateFont("Impact", 8, 4)
  font4 = renderCreateFont("Impact", 4, 4)
  font6 = renderCreateFont("Impact", 6, 4)
  font8 = renderCreateFont("Impact", 8, 4)
  font10 = renderCreateFont("Impact", 10, 4)
  font12 = renderCreateFont("Impact", 12, 4)
  font14 = renderCreateFont("Impact", 14, 4)
  font16 = renderCreateFont("Impact", 16, 4)
  font20 = renderCreateFont("Impact", 20, 4)
  font24 = renderCreateFont("Impact", 24, 4)


  resX, resY = getScreenResolution()
  m1 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/1.png')
  m2 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/2.png')
  m3 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/3.png')
  m4 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/4.png')
  m5 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/5.png')
  m6 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/6.png')
  m7 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/7.png')
  m8 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/8.png')
  m9 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/9.png')
  m10 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/10.png')
  m11 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/11.png')
  m12 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/12.png')
  m13 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/13.png')
  m14 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/14.png')
  m15 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/15.png')
  m16 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/16.png')
  m1k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/1k.png')
  m2k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/2k.png')
  m3k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/3k.png')
  m4k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/4k.png')
  m5k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/5k.png')
  m6k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/6k.png')
  m7k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/7k.png')
  m8k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/8k.png')
  m9k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/9k.png')
  m10k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/10k.png')
  m11k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/11k.png')
  m12k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/12k.png')
  m13k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/13k.png')
  m14k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/14k.png')
  m15k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/15k.png')
  m16k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/gmap/16k.png')
  if resX > 1024 and resY >= 1024 then
    bX = (resX - 1024) / 2
    bY = (resY - 1024) / 2
    size = 1024
  elseif resX > 720 and resY >= 720 then
    bX = (resX - 720) / 2
    bY = (resY - 720) / 2
    size = 720
  else
    bX = (resX - 512) / 2
    bY = (resY - 512) / 2
    size = 512
  end
end

function transponder()
  while connected do
    wait(0)
    asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    licensenick = sampGetPlayerNickname(licenseid)
    data = {}
    if getActiveInterior() == 0 and not settings.map.hide then
      x, y, z = getCharCoordinates(playerPed)
      data["sender"] = {sender = licensenick, pos = {x = x, y = y, z = z}, heading = getCharHeading(playerPed), health = getCharHealth(playerPed)}
    end
    data["vehicles"] = nil
    --[[if not settings.map.hide_v then
      getCar(199)--
      getCar(200)--
      getCar(201)
      getCar(202)--
      getCar(203)--
      getCar(204)--
      getCar(205)--
      --hamc
      --462 фура, 463-472 байки
      for i = 462, 472 do
        getCar(i)
      end
      --himc
      --528 фура, 529-538 байки
      for i = 528, 538 do
        getCar(i)
      end
      --fsmc
      --550 фура, 551-560 байки
      for i = 550, 560 do
        getCar(i)
      end
      --vmc
      --561 фура, 562-571 байки
      for i = 561, 571 do
        getCar(i)
      end
      --omc
      --495 фура, 496-505 байки
      for i = 495, 505 do
        getCar(i)
      end
      --mmc
      --473 фура, 474-483 байки
      for i = 473, 483 do
        getCar(i)
      end
      --pmc
      --484 фура, 485-494 байки
      for i = 484, 494 do
        getCar(i)
      end
      --wmc
      --517 фура, 518-527 байки
      for i = 517, 527 do
        getCar(i)
      end
      --bmc
      --539 фура, 540-549 байки
      for i = 539, 549 do
        getCar(i)
      end
      --smc
      --506 фура, 507-516 байки
      for i = 506, 516 do
        getCar(i)
      end

      --энфорсер
      for i = 137, 138 do
        getCar(i)
      end
      --мото
      for i = 139, 141 do
        getCar(i)
      end
      --пдшные
      for i = 143, 149 do
        getCar(i)
      end
      for i = 154, 155 do
        getCar(i)
      end
      --ранчеры
      for i = 151, 153 do
        getCar(i)
      end
      --верт
      getCar(150)
      --детективы
      for i = 156, 157 do
        getCar(i)
      end
    end]]



    a = os.clock()
    local ok = client:send(encodeJson(data))
    if ok then
      message1, opcode = client:receive()
      if message1 then
        ad = decodeJson(message1)
        --  print(os.clock())
      else
        print("не пришло")
      end
    else
      print('connection closed')
    end
  end
end

function changeradarhotkey(mode)
  local modes =
    {
      [1] = " для тогла радара",
      [2] = " для уменьшения размера радара",
      [3] = " для увеличения размера радара",
      [4] = " для уменьшения масштаба (числа квадратов)",
      [5] = " для увеличения масштаба (числа квадратов)"
    }
  mode = tonumber(mode)
  sampShowDialog(989, "Изменение горячей клавиши"..modes[mode], "Нажмите \"Окей\", после чего нажмите нужную клавишу.\nНастройки будут изменены.", "Окей", "Закрыть")
  while sampIsDialogActive(989) do wait(100) end
  local resultMain, buttonMain, typ = sampHasDialogRespond(988)
  if buttonMain == 1 then
    while ke1y == nil do
      wait(0)
      for i = 1, 200 do
        if isKeyDown(i) then
          if mode == 1 then
            settings.radar.key1 = i
          end
          if mode == 2 then
            settings.radar.key2 = i
          end
          if mode == 3 then
            settings.radar.key3 = i
          end
          if mode == 4 then
            settings.radar.key4 = i
          end
          if mode == 5 then
            settings.radar.key5 = i
          end
          print(i)
          sampAddChatMessage("Установлена новая горячая клавиша - "..key.id_to_name(i), - 1)
          addOneOffSound(0.0, 0.0, 0.0, 1052)
          inicfg.save(settings, "gmap")
          ke1y = 1
          break
        end
      end
    end
    ke1y = nil
  end
end

function radar()
  if kD == nil then kD = resX / 15 end
  if sampIsChatInputActive() == false and isSampfuncsConsoleActive() == false and sampIsDialogActive() == false then
    if wasKeyPressed(settings.radar.key1) then
      settings.radar.enable = not settings.radar.enable
      inicfg.save(settings, "gmap")
    end
    if isKeyDown(settings.radar.key2) then
      if settings.radar.size == 5 then
        settings.radar.size = 5
      else
        settings.radar.size = settings.radar.size - 5
      end
      inicfg.save(settings, "gmap")
    end
    if isKeyDown(settings.radar.key3) then
      if settings.radar.size == 1000 then
        settings.radar.size = 1000
      else
        settings.radar.size = settings.radar.size + 5
      end
      inicfg.save(settings, "gmap")
    end
    if wasKeyPressed(settings.radar.key4) then
      if settings.radar.mode - 2 < 1 then
        settings.radar.mode = 1
      else
        settings.radar.mode = settings.radar.mode - 2
      end
      inicfg.save(settings, "gmap")
    end
    if wasKeyPressed(settings.radar.key5) then
      if settings.radar.mode + 2 > 23 then
        settings.radar.mode = 23
      else
        settings.radar.mode = settings.radar.mode + 2
      end
      inicfg.save(settings, "gmap")
    end
  end
  if settings.radar.enable then
    kXT, kYT = kvadrat()
    centerX = kXT
    centerY = kYT


    if kXT ~= nil and kYT ~= nil then
      kD = settings.radar.size / settings.radar.mode
      if settings.radar.lift ~= "Никогда" and (settings.radar.lift == "Всегда" or (settings.radar.lift == "В транспорте" and isCharInAnyCar(playerPed) and getCarCharIsUsing(playerPed) ~= nil and playerPed == getDriverOfCar(getCarCharIsUsing(playerPed)))) then
        kY = resY - kD * settings.radar.mode - (resY - 80) / 5
        kX = resX - kD * settings.radar.mode
      else
        kY = resY - kD * settings.radar.mode
        kX = resX - kD * settings.radar.mode
      end

      radariconsize = kD / 7

      radaroffset = math.floor((settings.radar.mode - 1) / 2)


      if kXT - radaroffset < 1 then
        centerX = centerX + (1 + radaroffset - kXT)
      end

      if kXT + radaroffset > 24 then
        centerX = centerX - (radaroffset - (math.abs(24 - kXT)))
      end


      if kYT - radaroffset < 1 then
        centerY = centerY + (1 + radaroffset - kYT)
      end

      if kYT + radaroffset > 24 then
        centerY = centerY - (radaroffset - (math.abs(24 - kYT)))
      end


      kvX = 0
      kvY = 0
      for i = centerY - radaroffset, centerY + radaroffset do
        kvX = kvX + 1
        kvY = 0
        for z = centerX - radaroffset, centerX + radaroffset do
          kvY = kvY + 1
          loadstring(string.format("kv%d__%d = kv%d_%d", kvX, kvY, i, z))()
        end
      end

      kvX = 0
      kvY = 0
      for i = centerY - radaroffset, centerY + radaroffset do
        kvX = kvX + 1
        kvY = 0
        for z = centerX - radaroffset, centerX + radaroffset do
          kvY = kvY + 1
          loadstring(string.format("renderDrawTexture(kv%d__%d, kX + kD * %d, kY + kD * %d, kD, kD, 0, settings.map.alpha)", kvX, kvY, kvY - 1, kvX - 1, i, z))()
        end
      end
      if settings.radar.mode ~= 0 then
        local X, Y = getCharCoordinates(playerPed)

        if ad ~= nil then
          for k, v in pairs(ad) do
            --[[if k == "vehicles" and not settings.map.hide then
              for z, v1 in pairs(v) do
                if canrender(v1["x"], v1["y"], centerX, centerY) then
                  rendercar = tonumber(z)
                  --fura sos
                  if rendercar == 506 then
                    renderbikefura("sos", v1)
                    --matovoz
                  elseif rendercar >= 199 and rendercar <= 205 then
                    rendermatovoz(v1)
                  elseif rendercar >= 462 and rendercar <= 472 then
                    --hamc
                    if rendercar == 462 then
                      renderbikefura("hamc", v1)
                    else
                      renderbike("hamc", v1)
                    end
                  elseif rendercar >= 473 and rendercar <= 483 then
                    --mmc
                    if rendercar == 473 then
                      renderbikefura("mmc", v1)
                    else
                      renderbike("mmc", v1)
                    end
                  elseif rendercar >= 484 and rendercar <= 494 then
                    --pmc
                    if rendercar == 484 then
                      renderbikefura("pmc", v1)
                    else
                      renderbike("pmc", v1)
                    end
                  elseif rendercar >= 495 and rendercar <= 505 then
                    --omc
                    if rendercar == 495 then
                      renderbikefura("omc", v1)
                    else
                      renderbike("omc", v1)
                    end
                  elseif rendercar >= 506 and rendercar <= 516 then
                    --smc
                    if rendercar == 506 then
                      renderbikefura("sos", v1)
                    else
                      renderbike("sos", v1)
                    end
                  elseif rendercar >= 517 and rendercar <= 527 then
                    --wmc
                    if rendercar == 517 then
                      renderbikefura("wmc", v1)
                    else
                      renderbike("wmc", v1)
                    end
                  elseif rendercar >= 528 and rendercar <= 538 then
                    --himc
                    if rendercar == 528 then
                      renderbikefura("hmc", v1)
                    else
                      renderbike("hmc", v1)
                    end
                  elseif rendercar >= 550 and rendercar <= 560 then
                    --fsmc
                    if rendercar == 550 then
                      renderbikefura("FMC", v1)
                    else
                      renderbike("fmc", v1)
                    end
                  elseif rendercar >= 561 and rendercar <= 571 then
                    --vmc
                    if rendercar == 561 then
                      renderbikefura("vmc", v1)
                    else
                      renderbike("vmc", v1)
                    end
                  elseif rendercar >= 539 and rendercar <= 549 then
                    --bmc
                    if rendercar == 539 then
                      renderbikefura("bmc", v1)
                    else
                      renderbike("bmc", v1)
                    end
                    --энфорсер
                  elseif rendercar == 137 or rendercar == 138 or rendercar == 139 or rendercar == 140 or rendercar == 141 or rendercar == 143 or rendercar == 144 or rendercar == 145 or rendercar == 146 or rendercar == 147 or rendercar == 148 or rendercar == 149 or rendercar == 154 or rendercar == 155 or rendercar == 151 or rendercar == 152 or rendercar == 153 or rendercar == 150 or rendercar == 156 or rendercar == 157 then
                    --lvpd
                    renderpolicecar("LVPD", v1)
                  end
                end
              end
            end]]
            if k == "nicks" and not settings.map.hide then
              for z, v1 in pairs(v) do
                if canrender(v1["x"], v1["y"], centerX, centerY) then
                  if z ~= licensenick then
                    --убрать
                    if ad["timestamp"] - v1["timestamp"] < 300 then
                      renderFontDrawText(font, v1["health"], radarGetX(v1["x"]) + 12, radarGetY(v1["y"]) + 2, 0xFF00FF00)
                      n1, n2 = string.match(z, "(.).+_(.).+")
                      if n1 and n2 then
                        renderFontDrawText(font, n1..n2, radarGetX(v1["x"]) - 12, radarGetY(v1["y"]) + radariconsize / 2, 0xFF00FF00)
                      end
                      renderDrawTexture(player, radarGetX(v1["x"]), radarGetY(v1["y"]), radariconsize, radariconsize, - v1["heading"], - 1)
                    end
                  end
                end
              end
            end
          end
        end
        renderDrawTexture(player1, radarGetX(X), radarGetY(Y), radariconsize, radariconsize, - getCharHeading(playerPed), - 1)
      end
    end
  end
end
--[[
function renderbikefura(club, v1)
  if ad["timestamp"] - v1["timestamp"] < 500 then
    color = 0xFFdedbd2
    if ad["timestamp"] - v1["timestamp"] > 3 then
      renderFontDrawText(font, string.format("%.0f?", ad["timestamp"] - v1["timestamp"]), radarGetX(v1["x"]) + 17, radarGetY(v1["y"]) + 2, color)
    end
    if v1["health"] ~= nil then
      if ad["timestamp"] - v1["healthstamp"] < 5 then
        renderFontDrawText(font, v1["health"], radarGetX(v1["x"]) - 25, radarGetY(v1["y"]) + 2, color)
      else
        renderFontDrawText(font, v1["health"].."?", radarGetX(v1["x"]) - 30, radarGetY(v1["y"]) + 2, color)
      end
    end
    renderDrawTexture(matavoz, radarGetX(v1["x"]), radarGetY(v1["y"]), radariconsize, radariconsize, - v1["heading"] + 90, - 1)
    renderFontDrawText(font, string.upper(club), radarGetX(v1["x"]) - 3, radarGetY(v1["y"]) + 10, color)
  end
end

function rendermatovoz(v1)
  if ad["timestamp"] - v1["timestamp"] < 500 then
    color = 0xFF00FF00
    if ad["timestamp"] - v1["timestamp"] > 3 then
      renderFontDrawText(font, string.format("%.0f?", ad["timestamp"] - v1["timestamp"]), radarGetX(v1["x"]) + 17, radarGetY(v1["y"]) + 2, color)
    end
    if v1["health"] ~= nil then
      if ad["timestamp"] - v1["healthstamp"] < 5 then
        renderFontDrawText(font, v1["health"], radarGetX(v1["x"]) - 25, radarGetY(v1["y"]) + 2, color)
      else
        renderFontDrawText(font, v1["health"].."?", radarGetX(v1["x"]) - 30, radarGetY(v1["y"]) + 2, color)
      end
    end
    renderDrawTexture(matavoz, radarGetX(v1["x"]), radarGetY(v1["y"]), radariconsize, radariconsize, - v1["heading"] + 90, - 1)
  end
end

function renderbike(club, v1)
  if ad["timestamp"] - v1["timestamp"] < 5 then
    color = 0xFFdedbd2
    if ad["timestamp"] - v1["timestamp"] > 2 then
      rendertext(string.format("%.0f?", ad["timestamp"] - v1["timestamp"]), v1["x"], v1["y"], radariconsize, radariconsize / 6, radariconsize, color)
    end
    renderDrawTexture(radar_girlfriend, radarGetX(v1["x"]), radarGetY(v1["y"]), radariconsize, radariconsize, - v1["heading"] + 180, - 1)
    rendertext(string.upper(club), v1["x"], v1["y"], - radariconsize / 6, radariconsize, radariconsize, - 1)
  end
end


function renderpolicecar(club, v1)
  if ad["timestamp"] - v1["timestamp"] < 5 then
    color = 0xFFdedbd2
    if ad["timestamp"] - v1["timestamp"] > 2 then
      rendertext(string.format("%.0f?", ad["timestamp"] - v1["timestamp"]), v1["x"], v1["y"], radariconsize, radariconsize / 6, radariconsize, color)
    end
    renderDrawTexture(radar_police, radarGetX(v1["x"]), radarGetY(v1["y"]), radariconsize, radariconsize, - v1["heading"] + 180, - 1)
    rendertext(string.upper(club), v1["x"], v1["y"], - radariconsize / 6, radariconsize, radariconsize, - 1)
  end
end
]]
function rendertext(text, x, y, offsetX, offsetY, sizeicon, color)
  if sizeicon == nil then
    offset = offsetX
  else
    offset = sizeicon
  end

  if offset > 70 then
    renderFontDrawText(font24, text, radarGetX(x) + 5, radarGetY(y) + offset, color)
  elseif offset > 50 then
    renderFontDrawText(font20, text, radarGetX(x) + offsetX, radarGetY(y) + offsetY, color)
  elseif offset > 40 then
    renderFontDrawText(font16, text, radarGetX(x) + offsetX, radarGetY(y) + offsetY, color)
  elseif offset > 25 then
    renderFontDrawText(font14, text, radarGetX(x) + offsetX, radarGetY(y) + offsetY, color)
  elseif offset > 20 then
    renderFontDrawText(font12, text, radarGetX(x) + offsetX, radarGetY(y) + offsetY, color)
  elseif offset > 15 then
    renderFontDrawText(font10, text, radarGetX(x) + offsetX, radarGetY(y) + offsetY, color)
  else
    renderFontDrawText(font4, text, radarGetX(x) + offsetX, radarGetY(y) + offsetY, color)
  end
end

function canrender(x, y, centerX, centerY)
  local x = math.ceil((x + 3000) / 250)
  local y = math.ceil((y * - 1 + 3000) / 250)
  if x >= centerX - radaroffset and x <= centerX + radaroffset and y <= centerY + radaroffset and y >= centerY - radaroffset then
    return true
  end
  return false
end

function radarGetX(x1)
  x1 = (x1 + 3000) - (centerX - 1) * 250
  return kX + kD * radaroffset + x1 * (kD / 250) - radariconsize / 2
end

function radarGetY(y1)
  y1 = (y1 * - 1 + 3000) - (centerY - 1) * 250
  return kY + kD * radaroffset + y1 * (kD / 250) - radariconsize / 2
end

function fastmap()
  if settings.map.toggle and wasKeyPressed(77) and not sampIsChatInputActive() then
    if active and mapmode ~= 0 then
      mapmode = 0
    else
      active = not active
    end
  elseif settings.map.toggle and wasKeyPressed(188) and not sampIsChatInputActive() then
    if active and mapmode == 0 then
      mapmode = 1
    else
      active = not active
    end
  end
  if not sampIsChatInputActive() and wasKeyPressed(0x4B) then
    settings.map.sqr = not settings.map.sqr
    inicfg.save(settings, "gmap")
  end
  if not sampIsChatInputActive() and (settings.map.toggle and active) or (settings.map.toggle == false and not sampIsChatInputActive() and (isKeyDown(77) or isKeyDown(188))) then
    if isKeyDown(77) then
      mapmode = 0
    elseif isKeyDown(188) or mapmode ~= 0 then
      mapmode = getMode(modX, modY)
      if wasKeyPressed(0x25) then
        print(11)
        if modY > 1 then
          modY = modY - 1
        end
      elseif wasKeyPressed(0x27) then
        if modY < 3 then
          modY = modY + 1
        end
      elseif wasKeyPressed(0x26) then
        if modX < 3 then
          modX = modX + 1
        end
      elseif wasKeyPressed(0x28) then
        if modX > 1 then
          modX = modX - 1
        end
      end
    end
    if mapmode == 0 then
      renderDrawTexture(m1, bX, bY, size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m2, bX + size / 4, bY, size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m3, bX + 2 * (size / 4), bY, size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m4, bX + 3 * (size / 4), bY, size / 4, size / 4, 0, settings.map.alpha)

      renderDrawTexture(m5, bX, bY + size / 4, size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m6, bX + size / 4, bY + size / 4, size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m7, bX + 2 * (size / 4), bY + size / 4, size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m8, bX + 3 * (size / 4), bY + size / 4, size / 4, size / 4, 0, settings.map.alpha)

      renderDrawTexture(m9, bX, bY + 2 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m10, bX + size / 4, bY + 2 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m11, bX + 2 * (size / 4), bY + 2 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m12, bX + 3 * (size / 4), bY + 2 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)

      renderDrawTexture(m13, bX, bY + 3 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m14, bX + size / 4, bY + 3 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m15, bX + 2 * (size / 4), bY + 3 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)
      renderDrawTexture(m16, bX + 3 * (size / 4), bY + 3 * (size / 4), size / 4, size / 4, 0, settings.map.alpha)
      if size == 1024 then
        iconsize = 16
      end
      if size == 720 then
        iconsize = 12
      end
      if size == 512 then
        iconsize = 10
      end
    else
      if size == 1024 then
        iconsize = 32
      end
      if size == 720 then
        iconsize = 24
      end
      if size == 512 then
        iconsize = 16
      end
    end
    if mapmode == 1 then
      if settings.map.sqr then
        renderDrawTexture(m9k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m10k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m13k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m14k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m9, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m10, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m13, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m14, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 2 then
      if settings.map.sqr then
        renderDrawTexture(m10k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m11k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m14k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m15k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m10, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m11, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m14, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m15, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 3 then
      if settings.map.sqr then
        renderDrawTexture(m11k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m12k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m15k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m16k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m11, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m12, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m15, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m16, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 4 then
      if settings.map.sqr then
        renderDrawTexture(m5k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m6k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m9k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m10k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m5, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m6, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m9, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m10, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 5 then
      if settings.map.sqr then
        renderDrawTexture(m6k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m7k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m10k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m11k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m6, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m7, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m10, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m11, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 6 then
      if settings.map.sqr then
        renderDrawTexture(m7k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m8k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m11k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m12k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m7, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m8, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m11, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m12, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 7 then
      if settings.map.sqr then
        renderDrawTexture(m1k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m2k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m5k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m6k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m1, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m2, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m5, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m6, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 8 then
      if settings.map.sqr then
        renderDrawTexture(m2k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m3k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m6k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m7k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m2, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m3, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m6, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m7, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    if mapmode == 9 then
      if settings.map.sqr then
        renderDrawTexture(m3k, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m4k, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m7k, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m8k, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      else
        renderDrawTexture(m3, bX, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m4, bX + size / 2, bY, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m7, bX, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
        renderDrawTexture(m8, bX + size / 2, bY + size / 2, size / 2, size / 2, 0, settings.map.alpha)
      end
    end
    --renderDrawTexture(matavoz, getX(0), getY(0), 16, 16, 0, - 1)
    if getQ(x, y, mapmode) or mapmode == 0 then
      renderDrawTexture(player, getX(x), getY(y), iconsize, iconsize, - getCharHeading(playerPed), - 1)
    end
    if ad ~= nil then
      for k, v in pairs(ad) do
        if k == "nicks" and not settings.map.hide then
          for z, v1 in pairs(v) do
            if getQ(v1["x"], v1["y"], mapmode) or mapmode == 0 then
              if z ~= licensenick then
                --убрать
                if ad["timestamp"] - v1["timestamp"] < 300 then
                  if mapmode == 0 then
                    renderFontDrawText(font, v1["health"], getX(v1["x"]) + 12, getY(v1["y"]) + 2, 0xFF00FF00)
                  else
                    renderFontDrawText(font12, v1["health"], getX(v1["x"]) + 28, getY(v1["y"]) + 4, 0xFF00FF00)
                  end
                  n1, n2 = string.match(z, "(.).+_(.).+")
                  if n1 and n2 then
                    if mapmode == 0 then
                      renderFontDrawText(font, n1..n2, getX(v1["x"]) - 12, getY(v1["y"]) + 2, 0xFF00FF00)
                    else
                      renderFontDrawText(font12, z, getX(v1["x"]) - string.len(z) * 8.3, getY(v1["y"]) + 4, 0xFF00FF00)
                    end
                  end
                  renderDrawTexture(player, getX(v1["x"]), getY(v1["y"]), iconsize, iconsize, - v1["heading"], - 1)
                end
              end
            end
          end
        end


        --[[if k == "vehicles" and not settings.map.hide then
          for z, v1 in pairs(v) do
            if getQ(v1["x"], v1["y"], mapmode) or mapmode == 0 then
              if ((tonumber(z) >= 199 and tonumber(z) <= 205) or tonumber(z) == settings.map.idfura) and ad["timestamp"] - v1["timestamp"] < 500 then
                if tonumber(z) == settings.map.idfura then
                  color = 0xFFdedbd2
                else
                  color = 0xFF00FF00
                end

                if ad["timestamp"] - v1["timestamp"] > 3 then
                  if mapmode == 0 then
                    renderFontDrawText(font, string.format("%.0f?", ad["timestamp"] - v1["timestamp"]), getX(v1["x"]) + 17, getY(v1["y"]) + 2, color)
                  else
                    renderFontDrawText(font12, string.format("%.0f?", ad["timestamp"] - v1["timestamp"]), getX(v1["x"]) + 31, getY(v1["y"]) + 4, color)
                  end
                end
                if v1["health"] ~= nil then
                  if ad["timestamp"] - v1["healthstamp"] < 5 then
                    if mapmode == 0 then
                      renderFontDrawText(font, v1["health"], getX(v1["x"]) - 25, getY(v1["y"]) + 2, color)
                    else
                      renderFontDrawText(font12, v1["health"], getX(v1["x"]) - string.len(v1["health"]) * 9.4, getY(v1["y"]) + 4, color)
                    end
                  else
                    if mapmode == 0 then
                      renderFontDrawText(font, v1["health"].."?", getX(v1["x"]) - 30, getY(v1["y"]) + 2, color)
                    else
                      renderFontDrawText(font12, v1["health"].."?", getX(v1["x"]) - string.len(v1["health"].."?") * 9.4, getY(v1["y"]) + 4, color)
                    end
                  end
                end
                renderDrawTexture(matavoz, getX(v1["x"]), getY(v1["y"]), iconsize, iconsize, - v1["heading"] + 90, - 1)
              end
            end
          end
        end]]
      end
    end
  end
end

function getMode(x, y)
  if x == 1 then
    if y == 1 then
      return 1
    end
    if y == 2 then
      return 2
    end
    if y == 3 then
      return 3
    end
  end
  if x == 2 then
    if y == 1 then
      return 4
    end
    if y == 2 then
      return 5
    end
    if y == 3 then
      return 6
    end
  end
  if x == 3 then
    if y == 1 then
      return 7
    end
    if y == 2 then
      return 8
    end
    if y == 3 then
      return 9
    end
  end
end

function updateMenu()
  mod_submenus_sa = {
    {
      title = 'Информация о скрипте',
      onclick = function()
        sampShowDialog(0, "{7ef3fa}/gmap /gmapmenu v."..thisScript().version.." - руководство пользователя.", "Описать тут", "Окей")
      end
    },
    {
      title = 'Показывать вступительное сообщение: '..tostring(settings.welcome.show),
      onclick = function()
        settings.welcome.show = not settings.welcome.show
        inicfg.save(settings, "gmap")
      end
    },
    {
      title = ' '
    },
    {
      title = '{AAAAAA}Модули'
    },
    {
      title = '{00ff66}Навигация',
      submenu = {
        {
          title = 'Информация о модуле',
          onclick = function()
            sampShowDialog(0, "{7ef3fa}/gmap v."..thisScript().version.." - информация о модуле {00ff66}\"НАВИГАЦИЯ\"", "{00ff66}НАВИГАЦИЯ\n{ffffff}Модуль предназначен для быстрого обмена координатами.\nКоординаты передаются через сервер между всеми юзерами.\nЕсли сервер недоступен, модуль не работает.\n\n{7ef3fa}M{ffffff} - открыть всю карту со всеми доступными данными.\n{7ef3fa}<(Б){ffffff} - открыть 1/4 карты. Стрелками можно перемещаться по ней.\n{7ef3fa}K{ffffff} - сменить режим 1/4 карты: карта с квадратами или обычная.\n\nНа карте отмечаются:\n\n{7ef3fa}1. Ваши координаты и направление.\n{7ef3fa}2. Координаты других юзеров.{ffffff}\n   *Слева от метки 2 буквы - инициалы.\n   *Справа от метки - HP.\n{7ef3fa}3. Транспорт:{ffffff}\n   *Обновляются только когда объекты есть в поле зрения.\n   */dl обновляется при дистанции <20м.\n   *Слева от метки - hp машины.\n   *Справа - когда последний раз видели.\n{7ef3fa}4. Фура SOS тоже отмечена на карте, выделена серым цветом.{ffffff}\n\n{FF0000}ВАЖНО: {ffffff}загрузка карты с квадратами фризит игру, да, это факт.\n", "Окей")
          end
        },
        {
          title = ' '
        },
        {
          title = 'Прозрачность: '..tostring(settings.map.alphastring),
          submenu = {
            {
              title = '100%',
              onclick = function()
                settings.map.alpha = 0xFFFFFFFF
                settings.map.alphastring = "100%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '95%',
              onclick = function()
                settings.map.alpha = 0xF2FFFFFF
                settings.map.alphastring = "95%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '90%',
              onclick = function()
                settings.map.alpha = 0xE6FFFFFF
                settings.map.alphastring = "90%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '85%',
              onclick = function()
                settings.map.alpha = 0xD9FFFFFF
                settings.map.alphastring = "85%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '80%',
              onclick = function()
                settings.map.alpha = 0xCCFFFFFF
                settings.map.alphastring = "80%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '75%',
              onclick = function()
                settings.map.alpha = 0xBFFFFFFF
                settings.map.alphastring = "75%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '70%',
              onclick = function()
                settings.map.alpha = 0xB3FFFFFF
                settings.map.alphastring = "70%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '65%',
              onclick = function()
                settings.map.alpha = 0xA6FFFFFF
                settings.map.alphastring = "65%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '60%',
              onclick = function()
                settings.map.alpha = 0x99FFFFFF
                settings.map.alphastring = "60%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '55%',
              onclick = function()
                settings.map.alpha = 0x8CFFFFFF
                settings.map.alphastring = "55%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '50%',
              onclick = function()
                settings.map.alpha = 0x80FFFFFF
                settings.map.alphastring = "50%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '45%',
              onclick = function()
                settings.map.alpha = 0x73FFFFFF
                settings.map.alphastring = "45%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '40%',
              onclick = function()
                settings.map.alpha = 0x66FFFFFF
                settings.map.alphastring = "40%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '35%',
              onclick = function()
                settings.map.alpha = 0x59FFFFFF
                settings.map.alphastring = "35%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '30%',
              onclick = function()
                settings.map.alpha = 0x4DFFFFFF
                settings.map.alphastring = "30%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '25%',
              onclick = function()
                settings.map.alpha = 0x40FFFFFF
                settings.map.alphastring = "25%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '20%',
              onclick = function()
                settings.map.alpha = 0x33FFFFFF
                settings.map.alphastring = "20%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '15%',
              onclick = function()
                settings.map.alpha = 0x26FFFFFF
                settings.map.alphastring = "15%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '10%',
              onclick = function()
                settings.map.alpha = 0x1AFFFFFF
                settings.map.alphastring = "10%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '5%',
              onclick = function()
                settings.map.alpha = 0x0DFFFFFF
                settings.map.alphastring = "5%"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = '0%',
              onclick = function()
                settings.map.alpha = 0x00FFFFFF
                settings.map.alphastring = "0%"
                inicfg.save(settings, "gmap")
              end
            },

          }
        },
        --[[{
          title = 'ID фуры вашего клуба: '..tostring(settings.map.idfura),
          submenu = {
            {
              title = 'hamc 462',
              onclick = function()
                settings.map.idfura = 462
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'mmc 473',
              onclick = function()
                settings.map.idfura = 473
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'pmc 484',
              onclick = function()
                settings.map.idfura = 484
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'omc 495',
              onclick = function()
                settings.map.idfura = 495
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'smc 506',
              onclick = function()
                settings.map.idfura = 506
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'wmc 517',
              onclick = function()
                settings.map.idfura = 517
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'himc 528',
              onclick = function()
                settings.map.idfura = 528
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'bmc 539',
              onclick = function()
                settings.map.idfura = 539
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'fsmc 550',
              onclick = function()
                settings.map.idfura = 550
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'vmc 561',
              onclick = function()
                settings.map.idfura = 561
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'нет у меня фуры 9999',
              onclick = function()
                settings.map.idfura = 99999
                inicfg.save(settings, "gmap")
              end
            },
          }
        },]]
        {
          title = 'Показывать карту на M и ,: '..tostring(settings.map.show),
          onclick = function()
            settings.map.show = not settings.map.show
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = 'Скрывать мои координаты: '..tostring(settings.map.hide),
          onclick = function()
            settings.map.hide = not settings.map.hide
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = 'Скрывать транспорт от сервера: '..tostring(settings.map.hide_v),
          onclick = function()
            settings.map.hide_v = not settings.map.hide_v
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = 'Переключать вместо удержания: '..tostring(settings.map.toggle),
          onclick = function()
            settings.map.toggle = not settings.map.toggle
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = 'Включить радар (Alfa): '..tostring(settings.map.radar),
          onclick = function()
            settings.map.radar = not settings.map.radar
            if settings.map.radar then
              sampShowDialog(0, "{7ef3fa}Информация", key.id_to_name(settings.radar.key1).." - скрыть/показать радар.\nКнопками "..key.id_to_name(settings.radar.key3).." и "..key.id_to_name(settings.radar.key2).." можно увеличивать и уменьшать размер квадрата.\nКнопками "..key.id_to_name(settings.radar.key4).." и "..key.id_to_name(settings.radar.key5).." можно уменьшать и увеличивать количество квадратов.\nВ настройках можно сменить хоткеи и установить, сдвигать ли спидометр.\nПодробная информация о модуле 'радар' в /gmap.", "Окей")
            end
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = ' '
        },
        {
          title = '{AAAAAA}Настройки Радара'
        },
        {
          title = 'Изменить клавишу активации',
          submenu = {
            {
              title = 'Скрыть/показать - {7ef3fa}'..key.id_to_name(settings.radar.key1),
              onclick = function()
                lua_thread.create(changeradarhotkey, 1)
              end
            },
            {
              title = 'Уменьшить размер радара - {7ef3fa}'..key.id_to_name(settings.radar.key2),
              onclick = function()
                lua_thread.create(changeradarhotkey, 2)
              end
            },
            {
              title = 'Увеличить размер радара - {7ef3fa}'..key.id_to_name(settings.radar.key3),
              onclick = function()
                lua_thread.create(changeradarhotkey, 3)
              end
            },
            {
              title = 'Уменьшить масштаб радара - {7ef3fa}'..key.id_to_name(settings.radar.key4),
              onclick = function()
                lua_thread.create(changeradarhotkey, 4)
              end
            },
            {
              title = 'Увеличить масштаб радара - {7ef3fa}'..key.id_to_name(settings.radar.key5),
              onclick = function()
                lua_thread.create(changeradarhotkey, 5)
              end
            },
          },
        },
        {
          title = 'Сдвигать радар по оси Y: '..tostring(settings.radar.lift),
          submenu = {
            {
              title = 'Всегда',
              onclick = function()
                settings.radar.lift = "Всегда"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'В транспорте',
              onclick = function()
                settings.radar.lift = "В транспорте"
                inicfg.save(settings, "gmap")
              end
            },
            {
              title = 'Никогда',
              onclick = function()
                settings.radar.lift = "Никогда"
                inicfg.save(settings, "gmap")
              end
            },
          }
        },
      }
    },
  }
end

function getQ(x, y, mp)
  if mp == 1 then
    if x <= 0 and y <= 0 then
      return true
    end
  end
  if mp == 2 then
    if x >= -1500 and x <= 1500 and y <= 0 then
      return true
    end
  end
  if mp == 3 then
    if x >= 0 and y <= 0 then
      return true
    end
  end
  if mp == 4 then
    if x <= 0 and y >= -1500 and y <= 1500 then
      return true
    end
  end
  if mp == 5 then
    if x >= -1500 and x <= 1500 and y >= -1500 and y <= 1500 then
      return true
    end
  end
  if mp == 6 then
    if x >= 0 and y >= -1500 and y <= 1500 then
      return true
    end
  end
  if mp == 7 then
    if x <= 0 and y >= 0 then
      return true
    end
  end
  if mp == 8 then
    if x >= -1500 and x <= 1500 and y >= 0 then
      return true
    end
  end
  if mp == 9 then
    if x >= 0 and y >= 0 then
      return true
    end
  end
  return false
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
  if mapmode == 0 then
    x = math.floor(x + 3000)
    return bX + x * (size / 6000) - iconsize / 2
  end
  if mapmode == 3 or mapmode == 9 or mapmode == 6 then
    return bX - iconsize / 2 + math.floor(x) * (size / 3000)
  end
  if mapmode == 1 or mapmode == 7 or mapmode == 4 then
    return bX - iconsize / 2 + math.floor(x + 3000) * (size / 3000)
  end
  if mapmode == 2 or mapmode == 8 or mapmode == 5 then
    return bX - iconsize / 2 + math.floor(x + 1500) * (size / 3000)
  end
end

function getY(y)
  if mapmode == 0 then
    y = math.floor(y * - 1 + 3000)
    return bY + y * (size / 6000) - iconsize / 2
  end
  if mapmode == 7 or mapmode == 9 or mapmode == 8 then
    return bY + size - iconsize / 2 - math.floor(y) * (size / 3000)
  end
  if mapmode == 1 or mapmode == 3 or mapmode == 2 then
    return bY + size - iconsize / 2 - math.floor(y + 3000) * (size / 3000)
  end
  if mapmode == 4 or mapmode == 5 or mapmode == 6 then
    return bY + size - iconsize / 2 - math.floor(y + 1500) * (size / 3000)
  end
end

function kvadrat()
  local X, Y = getCharCoordinates(playerPed)
  X = math.ceil((X + 3000) / 250)
  Y = math.ceil((Y * - 1 + 3000) / 250)
  return X, Y
end

function dn(nam)
  file = getGameDirectory().."\\moonloader\\resource\\gmap\\"..nam
  if not doesFileExist(file) then
    downloadUrlToFile("http://qrlk.me/dev/moonloader/!gmap/resource/"..nam, file)
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
            updatelnk = info.updateurl
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
                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Смерть..'), color)
                        thisScript():unload()
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
          print('v'..thisScript().version..': Не могу проверить обновление. Сайт сдох, я сдох, ваш интернет работает криво. Одно из этого списка.')
          thisScript():unload()
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
          sampShowDialog(222228, "{ff0000}Информация об обновлении", "{ffffff}"..thisScript().name.." {ffe600}собирается открыть свой changelog для вас.\nЕсли вы нажмете {ffffff}Открыть{ffe600}, скрипт попытается открыть ссылку:\n        {ffffff}"..changelogurl.."\n{ffe600}Если ваша игра крашнется, вы можете открыть эту ссылку сами.", "Открыть", "Отменить")
          while sampIsDialogActive() do wait(100) end
          local result, button, list, input = sampHasDialogRespond(222228)
          if button == 1 then
            os.execute('explorer "'..changelogurl..'"')
          end
        end
      )
    end
  )
end
--------------------------------------------------------------------------------
--------------------------------------3RD---------------------------------------
--------------------------------------------------------------------------------
-- made by FYP
function submenus_show(menu, caption, select_button, close_button, back_button)
  select_button, close_button, back_button = select_button or 'Select', close_button or 'Close', back_button or 'Back'
  prev_menus = {}
  function display(menu, id, caption)
    local string_list = {}
    for i, v in ipairs(menu) do
      table.insert(string_list, type(v.submenu) == 'table' and v.title .. '  >>' or v.title)
    end
    sampShowDialog(id, caption, table.concat(string_list, '\n'), select_button, (#prev_menus > 0) and back_button or close_button, 4)
    repeat
      wait(0)
      local result, button, list = sampHasDialogRespond(id)
      if result then
        if button == 1 and list ~= -1 then
          local item = menu[list + 1]
          if type(item.submenu) == 'table' then -- submenu
            table.insert(prev_menus, {menu = menu, caption = caption})
            if type(item.onclick) == 'function' then
              item.onclick(menu, list + 1, item.submenu)
            end
            return display(item.submenu, id + 1, item.submenu.title and item.submenu.title or item.title)
          elseif type(item.onclick) == 'function' then
            local result = item.onclick(menu, list + 1)
            if not result then return result end
            return display(menu, id, caption)
          end
        else -- if button == 0
          if #prev_menus > 0 then
            local prev_menu = prev_menus[#prev_menus]
            prev_menus[#prev_menus] = nil
            return display(prev_menu.menu, id - 1, prev_menu.caption)
        end
        return false
        end
      end
    until result
  end
  return display(menu, 31337, caption or menu.title)
end
