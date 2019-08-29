script_name("E.D.I.T.H.")
script_author("Anthony Edward Stark")
script_version("beta-3.7")
script_description("E.D.I.T.H. или же Э.Д.И.Т. (с английского: Even in Death, I'm The Hero: Даже в Смерти Я Герой) - это пользовательский интерфейс для всей сети Stark Industries, который предоставляет пользователю полный доступ ко всей сети спутников Stark Industries, а также несколько входов в чёрный ход нескольких крупнейших мировых телекоммуникационных компаний, предоставляя пользователю доступ ко всей личной информации цели. Всех доступных целей. Размещёна в солнцезащитные очки.")

local ip = 'ws://31.134.153.163:9128'
--local ip = 'http://localhost:8993'
--local inspect = require "inspect"
local sampev = require 'lib.samp.events'
local websocket = require'websocket'
local client = websocket.client.copas({timeout = 2})
local inicfg = require 'inicfg'
local key = require("vkeys")
if doesFileExist(getGameDirectory().."\\moonloader\\config\\score.ini") and not doesFileExist(getGameDirectory().."\\moonloader\\config\\edith.ini") then
  os.rename(getGameDirectory().."\\moonloader\\config\\score.ini", getGameDirectory().."\\moonloader\\config\\edith.ini")
end
settings = inicfg.load({
  score =
  {
    posX = 23,
    posY = 426,
    size1 = 0.4,
    size2 = 2,
    key1 = 49,
    key2 = 50,
    enable = true,
    key3 = 51,
    key4 = 52,
    key5 = 53,
  },
  capturetimer = {
    enable = true,
  },
  stats =
  {
    dmg = 0,
    kills = 0,
    deaths = 0,
  },
  heist =
  {
    enable = true,
    sound = true,
  },
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
  usedrugs =
  {
    isactive = 1,
    sound = 1,
    txdtype = 1,
    --[Wait]
    cooldown = 60,
    --[DrugsPos]
    posX1 = 56,
    posY1 = 424,
    --[DrugsSize]
    size1 = 0.6,
    size2 = 1.2,
    --[DrugsStyle]
    style1 = 3,
    --[TimerPos]
    posX2 = 80,
    posY2 = 315,
    --[TimerSize]
    size3 = 0.4,
    size4 = 2,
    --[TimerStyle]
    style2 = 3,
    --[KEY]
    key = 88,
  },
}, 'edith')

ATTACK_COLOR = 2865496064
DEFEN_COLOR = 2855877036
color = 0x7ef3fa
local ad = {}
current_nick = ""
checkafk = os.time()
wasafk = false
timeleft_type = 0
afk = {}
status0 = " "
status1 = " "
status2 = " "
check = false
offline = false
lasttime = 0
count = 0
given = 0
k_given = 0
kills = 0
sendtype = 0
k_kills = 0
deaths = 0
waitforcapture = false
mode = false

function kvadrat()
  local X, Y = getCharCoordinates(playerPed)
  X = math.ceil((X + 3000) / 250)
  Y = math.ceil((Y * - 1 + 3000) / 250)
  return X, Y
end

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then return end
  while not isSampAvailable() do wait(100) end
  update("http://qrlk.me/dev/moonloader/!edith/stats.php", '['..string.upper(thisScript().name)..']: ', "http://qrlk.me/sampvk", "edithlog")
  asodkas, playerid = sampGetPlayerIdByCharHandle(PLAYER_PED)
  playernick = sampGetPlayerNickname(playerid)
  serverip, serverport = sampGetCurrentServerAddress()

  intim = inicfg.load({
    usedrugs =
    {
      lasttime = 1,
      kolvo = "???",
    },
  }, 'EDITH\\'..serverip..'-'..playernick)
  if not doesFileExist(getGameDirectory().."\\moonloader\\config\\edith\\"..serverip.."-"..playernick..".ini") then
    inicfg.save(intim, 'EDITH\\'..serverip..'-'..playernick)
  end
  openchangelog("edithlog", "-")
  if sampGetCurrentServerAddress() ~= "46.39.225.193" and sampGetCurrentServerAddress() ~= "185.169.134.11" and sampGetCurrentServerAddress() ~= "176.32.37.37" then return end
  asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
  licensenick = sampGetPlayerNickname(licenseid)
  sampRegisterChatCommand("bl", function() lua_thread.create(checkTab) end)
  sampRegisterChatCommand("bikerlist", function() lua_thread.create(checkTab) end)
  sampRegisterChatCommand("edith", function() lua_thread.create(function() updateMenu() submenus_show(mod_submenus_sa, '{348cb2}EDITH v.'..thisScript().version, 'Выбрать', 'Закрыть', 'Назад') end) end)
  lua_thread.create(score)
  lua_thread.create(capturetimer)
  lua_thread.create(heist_beep)
  usedrugs = lua_thread.create(usedrugs)
  connected, err = client:connect(ip, 'echo')
  if not connected then
    if settings.welcome.show then
      sampAddChatMessage("{7ef3fa}[EDITH]: {ff0000}Мы не можем установить связь со спутником Плиттовской Братвы. {7ef3fa}/edith - рук-во пользователя.", 0xff0000)
      sampAddChatMessage("{7ef3fa}[EDITH]: "..err, 0xff0000)
    end
    offline = true
    wait(-1)
  else
    local ok = client:send(encodeJson({auth = licensenick}))
    if ok then
      local message, opcode = client:receive()
      if message then
        if message == "Granted!" then
          init()
          if settings.welcome.show then
            sampAddChatMessage("Связь с оборонной системой Плиттовской Братвы установлена. Все системы проверены и готовы, босс.", 0x7ef3fa)
            sampAddChatMessage("E.D.I.T.H. "..thisScript().version.." к вашим услугам. Подробная информация: /edith. Приятной игры, "..licensenick..".", 0x7ef3fa)
          end
        else
          if settings.welcome.show then
            sampAddChatMessage("{7ef3fa}[EDITH]: {ff0000}У вас нет доступа к E.D.I.T.H. Если считаете, что это ошибка, сообщите об этом.", 0xff0000)
          end
          client:close()
          thisScript():unload()
          wait(1000)
        end
      else
        if settings.welcome.show then
          sampAddChatMessage("{7ef3fa}[EDITH]: {ff0000}Ошибка соединения со спутником Плиттовской Братвы.", 0xff0000)
        end
        client:close()
        thisScript():unload()
        wait(1000)
      end
    else
      if settings.welcome.show then
        sampAddChatMessage("{7ef3fa}[EDITH]: {ff0000}Ошибка соединения со спутником Плиттовской Братвы.", 0xff0000)
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
    if not settings.map.hide_v then
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
    end



    --  getCar(330)
    a = os.clock()
    if waitforcapture then
      data["timeleft_type"] = sendtype
      waitforcapture = false
    end
    local ok = client:send(encodeJson(data))
    if ok then
      message1, opcode = client:receive()
      if message1 then
        offline = false
        ad = decodeJson(message1)
        --  print(os.clock())
        if ad["capture"]["time"] ~= nil then
          if timeleft_type ~= ad["capture"]["type"] or ad["capture"]["type"] == 2 then
            timeleft_type = ad["capture"]["type"]
            timeleft_base = math.floor(ad["capture"]["time"] + math.floor(os.time() - ad["timestamp"]))
          end
        end
      else
        print("не пришло")
        offline = true
      end
    else
      print('connection closed')
      offline = true
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
          inicfg.save(settings, "edith")
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
      inicfg.save(settings, "edith")
    end
    if isKeyDown(settings.radar.key2) then
      if settings.radar.size == 5 then
        settings.radar.size = 5
      else
        settings.radar.size = settings.radar.size - 5
      end
      inicfg.save(settings, "edith")
    end
    if isKeyDown(settings.radar.key3) then
      if settings.radar.size == 1000 then
        settings.radar.size = 1000
      else
        settings.radar.size = settings.radar.size + 5
      end
      inicfg.save(settings, "edith")
    end
    if wasKeyPressed(settings.radar.key4) then
      if settings.radar.mode - 2 < 1 then
        settings.radar.mode = 1
      else
        settings.radar.mode = settings.radar.mode - 2
      end
      inicfg.save(settings, "edith")
    end
    if wasKeyPressed(settings.radar.key5) then
      if settings.radar.mode + 2 > 23 then
        settings.radar.mode = 23
      else
        settings.radar.mode = settings.radar.mode + 2
      end
      inicfg.save(settings, "edith")
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
            if k == "vehicles" and not settings.map.hide then
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
            end
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
    inicfg.save(settings, "edith")
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


        if k == "vehicles" and not settings.map.hide then
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
        end
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
        sampShowDialog(0, "{7ef3fa}/edith v."..thisScript().version.." - руководство пользователя.", "{00ff66}EDITH{ffffff} - мощный скрипт для байкеров срп с кучей модулей, многие из которых уникальны.\n\n{AAAAAA}Модули\n{00ff66}* НАВИГАЦИЯ - {ffffff}Обмен координатами на карте между пользователями через сервер.\n{00ff66}* БАЙКЕРЛИСТ{ffffff} - Чекер таба на стрелах байкеров.\n{00ff66}* CAPTURETIMER - {ffffff}Таймер стрел с синхронизацией между юзерами через сервер.\n{00ff66}* HEIST BEEP - {ffffff}Считает сколько осталось времени для след груза при ограблениях.\n{00ff66}* EDISCORE - {ffffff}Считает дамаг, смерти и килы, сообщает о результативности после смерти.\n{00ff66}* Таймер /usedrugs - {ffffff}Простой таймер юзедрагс, показывает остаток и кд.\n\nP.S. Подробная информация в разделе каждого модуля.", "Окей")
      end
    },
    {
      title = 'Показывать вступительное сообщение: '..tostring(settings.welcome.show),
      onclick = function()
        settings.welcome.show = not settings.welcome.show
        inicfg.save(settings, "edith")
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
            sampShowDialog(0, "{7ef3fa}/edith v."..thisScript().version.." - информация о модуле {00ff66}\"НАВИГАЦИЯ\"", "{00ff66}НАВИГАЦИЯ\n{ffffff}Модуль предназначен для быстрого обмена координатами.\nКоординаты передаются через сервер между всеми юзерами.\nЕсли сервер недоступен, модуль не работает.\n\n{7ef3fa}M{ffffff} - открыть всю карту со всеми доступными данными.\n{7ef3fa}<(Б){ffffff} - открыть 1/4 карты. Стрелками можно перемещаться по ней.\n{7ef3fa}K{ffffff} - сменить режим 1/4 карты: карта с квадратами или обычная.\n\nНа карте отмечаются:\n\n{7ef3fa}1. Ваши координаты и направление.\n{7ef3fa}2. Координаты других юзеров.{ffffff}\n   *Слева от метки 2 буквы - инициалы.\n   *Справа от метки - HP.\n{7ef3fa}3. Матовозы:{ffffff}\n   *Обновляются только когда объекты есть в поле зрения.\n   */dl обновляется при дистанции <20м.\n   *Слева от метки - hp машины.\n   *Справа - когда последний раз видели.\n{7ef3fa}4. Фура SOS тоже отмечена на карте, выделена серым цветом.{ffffff}\n\n{FF0000}ВАЖНО: {ffffff}загрузка карты с квадратами фризит игру, да, это факт.\n", "Окей")
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
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '95%',
              onclick = function()
                settings.map.alpha = 0xF2FFFFFF
                settings.map.alphastring = "95%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '90%',
              onclick = function()
                settings.map.alpha = 0xE6FFFFFF
                settings.map.alphastring = "90%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '85%',
              onclick = function()
                settings.map.alpha = 0xD9FFFFFF
                settings.map.alphastring = "85%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '80%',
              onclick = function()
                settings.map.alpha = 0xCCFFFFFF
                settings.map.alphastring = "80%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '75%',
              onclick = function()
                settings.map.alpha = 0xBFFFFFFF
                settings.map.alphastring = "75%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '70%',
              onclick = function()
                settings.map.alpha = 0xB3FFFFFF
                settings.map.alphastring = "70%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '65%',
              onclick = function()
                settings.map.alpha = 0xA6FFFFFF
                settings.map.alphastring = "65%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '60%',
              onclick = function()
                settings.map.alpha = 0x99FFFFFF
                settings.map.alphastring = "60%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '55%',
              onclick = function()
                settings.map.alpha = 0x8CFFFFFF
                settings.map.alphastring = "55%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '50%',
              onclick = function()
                settings.map.alpha = 0x80FFFFFF
                settings.map.alphastring = "50%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '45%',
              onclick = function()
                settings.map.alpha = 0x73FFFFFF
                settings.map.alphastring = "45%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '40%',
              onclick = function()
                settings.map.alpha = 0x66FFFFFF
                settings.map.alphastring = "40%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '35%',
              onclick = function()
                settings.map.alpha = 0x59FFFFFF
                settings.map.alphastring = "35%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '30%',
              onclick = function()
                settings.map.alpha = 0x4DFFFFFF
                settings.map.alphastring = "30%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '25%',
              onclick = function()
                settings.map.alpha = 0x40FFFFFF
                settings.map.alphastring = "25%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '20%',
              onclick = function()
                settings.map.alpha = 0x33FFFFFF
                settings.map.alphastring = "20%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '15%',
              onclick = function()
                settings.map.alpha = 0x26FFFFFF
                settings.map.alphastring = "15%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '10%',
              onclick = function()
                settings.map.alpha = 0x1AFFFFFF
                settings.map.alphastring = "10%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '5%',
              onclick = function()
                settings.map.alpha = 0x0DFFFFFF
                settings.map.alphastring = "5%"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = '0%',
              onclick = function()
                settings.map.alpha = 0x00FFFFFF
                settings.map.alphastring = "0%"
                inicfg.save(settings, "edith")
              end
            },

          }
        },
        {
          title = 'ID фуры вашего клуба: '..tostring(settings.map.idfura),
          submenu = {
            {
              title = 'hamc 462',
              onclick = function()
                settings.map.idfura = 462
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'mmc 473',
              onclick = function()
                settings.map.idfura = 473
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'pmc 484',
              onclick = function()
                settings.map.idfura = 484
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'omc 495',
              onclick = function()
                settings.map.idfura = 495
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'smc 506',
              onclick = function()
                settings.map.idfura = 506
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'wmc 517',
              onclick = function()
                settings.map.idfura = 517
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'himc 528',
              onclick = function()
                settings.map.idfura = 528
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'bmc 539',
              onclick = function()
                settings.map.idfura = 539
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'fsmc 550',
              onclick = function()
                settings.map.idfura = 550
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'vmc 561',
              onclick = function()
                settings.map.idfura = 561
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'нет у меня фуры 9999',
              onclick = function()
                settings.map.idfura = 99999
                inicfg.save(settings, "edith")
              end
            },
          }
        },
        {
          title = 'Показывать карту на M и ,: '..tostring(settings.map.show),
          onclick = function()
            settings.map.show = not settings.map.show
            inicfg.save(settings, "edith")
          end
        },
        {
          title = 'Скрывать мои координаты: '..tostring(settings.map.hide),
          onclick = function()
            settings.map.hide = not settings.map.hide
            inicfg.save(settings, "edith")
          end
        },
        {
          title = 'Скрывать транспорт от сервера: '..tostring(settings.map.hide_v),
          onclick = function()
            settings.map.hide_v = not settings.map.hide_v
            inicfg.save(settings, "edith")
          end
        },
        {
          title = 'Переключать вместо удержания: '..tostring(settings.map.toggle),
          onclick = function()
            settings.map.toggle = not settings.map.toggle
            inicfg.save(settings, "edith")
          end
        },
        {
          title = 'Включить радар (Alfa): '..tostring(settings.map.radar),
          onclick = function()
            settings.map.radar = not settings.map.radar
            if settings.map.radar then
              sampShowDialog(0, "{7ef3fa}Информация", key.id_to_name(settings.radar.key1).." - скрыть/показать радар.\nКнопками "..key.id_to_name(settings.radar.key3).." и "..key.id_to_name(settings.radar.key2).." можно увеличивать и уменьшать размер квадрата.\nКнопками "..key.id_to_name(settings.radar.key4).." и "..key.id_to_name(settings.radar.key5).." можно уменьшать и увеличивать количество квадратов.\nВ настройках можно сменить хоткеи и установить, сдвигать ли спидометр.\nПодробная информация о модуле 'радар' в /edith.", "Окей")

            end
            inicfg.save(settings, "edith")
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
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'В транспорте',
              onclick = function()
                settings.radar.lift = "В транспорте"
                inicfg.save(settings, "edith")
              end
            },
            {
              title = 'Никогда',
              onclick = function()
                settings.radar.lift = "Никогда"
                inicfg.save(settings, "edith")
              end
            },
          }
        },
      }
    },
    {
      title = '{00ff66}Байкерлист',

      submenu = {
        {
          title = 'Информация о модуле',
          onclick = function()
            sampShowDialog(0, "{7ef3fa}/edith v."..thisScript().version.." - информация о модуле {00ff66}\"БАЙКЕРЛИСТ\"", "{00ff66}БАЙКЕРЛИСТ{ffffff}\nВо время стрелы сервер устанавливает байкерам уникальные клисты.\nСкрипт проверяет таб и выводит диалог с полезной информацией.\n\n{7ef3fa}/bl(ist){ffffff} - открыть байкерлист.\n\nПримечания:\n* Диалог обновляется когда он открыт.\n* Можно проверить игроков на афк в том же диалоге.\n* Может быть случай, когда игрок с прошлой стрелы не изменил клист.", "Окей")
          end
        },
        {
          title = ' '
        },
        {
          title = 'Открыть байкерлист',
          onclick = function()
            lua_thread.create(checkTab)
          end
        },
      }
    },
    {
      title = '{00ff66}CAPTURETIMER',
      submenu = {
        {
          title = 'Информация о модуле',
          onclick = function()
            sampShowDialog(0, "{7ef3fa}/edith v."..thisScript().version.." - информация о модуле {00ff66}\"CAPTURETIMER\"", "{00ff66}CAPTURETIMER{ffffff}\nСкрипт отображает таймер до конца стрелы в правом нижнем углу.\nРаботает как через сервер, так и если он лежит.\n\nПримечания:\n* Таймер может быть неточным, так как сервер продлевает на несколько секунд.\n* Точность времени при синхронизации с сервером пока хромает.", "Окей")
          end
        },
        {
          title = 'Вкл/выкл модуля: '..tostring(settings.capturetimer.enable),
          onclick = function()
            settings.capturetimer.enable = not settings.capturetimer.enable
            inicfg.save(settings, "edith")
          end
        },
      }
    },
    {
      title = '{00ff66}HEIST BEEP',
      submenu = {
        {
          title = 'Информация о модуле',
          onclick = function()
            sampShowDialog(0, "{7ef3fa}/edith v."..thisScript().version.." - информация о модуле {00ff66}\"HEIST BEEP\"", "{00ff66}HEIST BEEP{ffffff}\nПосле взятия груза отсчитывает 5.15 секунд для следующего.\nРендерит на экран оставшееся время.\nЗвуковое уведомление настраивается в настройках.", "Окей")
          end
        },
        {
          title = ' '
        },
        {
          title = 'Вкл/выкл модуля: '..tostring(settings.heist.enable),
          onclick = function()
            settings.heist.enable = not settings.heist.enable
            inicfg.save(settings, "edith")
          end
        },
        {
          title = 'Вкл/выкл звука: '..tostring(settings.heist.sound),
          onclick = function()
            settings.heist.sound = not settings.heist.sound
            inicfg.save(settings, "edith")
          end
        },
      }
    },
    {
      title = '{00ff66}EDISCORE',
      submenu = {
        {
          title = 'Информация о модуле',
          onclick = function()
            sampShowDialog(0, "{7ef3fa}/edith v."..thisScript().version.." - информация о модуле {00ff66}\"EDISCORE\"", "{00ff66}EDISCORE{ffffff}\nФункция считает дамаг, смерти и килы, сообщает о результативности после смерти.\nОна рисует текстдрав, на котором по умолчанию нанесенный вами урон за жизнь.\n\nНажмите {7ef3fa}"..key.id_to_name(settings.score.key1).."{ffffff}, чтобы показать весь урон.\nНажмите {7ef3fa}"..key.id_to_name(settings.score.key2).."{ffffff}, чтобы показать убийства.\nНажмите {7ef3fa}"..key.id_to_name(settings.score.key3).."{ffffff}, чтобы показать смерти.\nНажмите {7ef3fa}"..key.id_to_name(settings.score.key4).."{ffffff}, чтобы показать соотношение убийств к смертям.\nНажмите {7ef3fa}"..key.id_to_name(settings.score.key5).."{ffffff}, чтобы сменить режим: за сеанс (белый) или за всё время (красный).", "Окей")
          end
        },
        {
          title = 'Посмотреть статистику',
          onclick = function()
            sampShowDialog(0, "{7ef3fa}Ваша статистика", "{00ff66}За жизнь:{ffffff}\nУрон: "..tostring(k_given).."\nУбийств: "..tostring(k_kills).."\n{00ff66}За сеанс:{ffffff}\nУрон: "..tostring(given).."\nУбийств: "..tostring(kills).."\nСмертей: "..tostring(deaths).."\n"..string.format("K/D: %2.1f", kills / deaths).."\n{00ff66}За всё время:{ffffff}\nУрон: "..string.format("%2.1f", settings.stats.dmg).."\nУбийств: "..tostring(settings.stats.kills).."\nСмертей: "..tostring(settings.stats.deaths).."\n"..string.format("K/D: %2.1f", settings.stats.kills / settings.stats.deaths), "Окей")
          end
        },
        {
          title = ' '
        },
        {
          title = 'Вкл/выкл модуля: '..tostring(settings.score.enable),
          onclick = function()
            settings.score.enable = not settings.score.enable
            if not settings.score.enable then
              sampTextdrawDelete(440)
            end
            inicfg.save(settings, "edith")
          end
        },
        {
          title = ' '
        },
        {
          title = 'Сбросить счётчик',
          onclick = function()
            lua_thread.create(resetscore)
          end
        },
        {
          title = ' '
        },
        {
          title = 'Изменить позицию и размер',
          onclick = function()
            lua_thread.create(changepos)
          end
        },
        {
          title = 'Изменить клавишу активации',
          submenu = {
            {
              title = 'Показать весь урон - {7ef3fa}'..key.id_to_name(settings.score.key1),
              onclick = function()
                lua_thread.create(changehotkey, 1)
              end
            },
            {
              title = 'Показать убийства - {7ef3fa}'..key.id_to_name(settings.score.key2),
              onclick = function()
                lua_thread.create(changehotkey, 2)
              end
            },
            {
              title = 'Показать смерти - {7ef3fa}'..key.id_to_name(settings.score.key3),
              onclick = function()
                lua_thread.create(changehotkey, 3)
              end
            },
            {
              title = 'Показать K/D - {7ef3fa}'..key.id_to_name(settings.score.key4),
              onclick = function()
                lua_thread.create(changehotkey, 4)
              end
            },
            {
              title = 'Смена режима (белый - сеанс, красный - всё время) - {7ef3fa}'..key.id_to_name(settings.score.key5),
              onclick = function()
                lua_thread.create(changehotkey, 5)
              end
            },
          },
          {
            title = '[4] Восстановить дефолтные настройки',
            onclick = function()
              cmdDrugsTxdDefault()
            end
          }
        },
      }
    },
    {
      title = '{00ff66}Таймер /usedrugs',
      submenu = {
        {
          title = 'Информация о модуле',
          onclick = function()
            sampShowDialog(0, "{7ef3fa}/edith v."..thisScript().version.." - информация о модуле {00ff66}\"Таймер / usedrugs\"", "{00ff66}Таймер /usedrugs{ffffff}\n\n{ffffff}Представляет собой доработанный и переписанный на Lua Drugs Master makaron'a.\nПо нажатию хоткея ({00ccff}X{ffffff} по умолчанию) скрипт автоматически юзнет нужное количество наркотиков.\nПосле нажатия запустится таймер до следующего употребления (/usedrugs).\nДержите хоткей ({00ccff}X{ffffff} по умолчанию), чтобы заюзать 1 грамм (помогает от ломки).\nВ автоматическом режиме скрипт отслеживает оставшееся количество нарко.\nВ настройках можно изменить хоткей, шрифт textdraw'ов, их размер и положение,\nпоменять задержку, изменить стиль \"Drugs\", выключить звук и вовсе отключить модуль.", "Окей")
          end
        },
        {
          title = 'Вкл/выкл модуля: '..tostring(settings.usedrugs.isactive),
          onclick = function()
            lua_thread.create(cmdChangeUsedrugsActive)
          end
        },
        {
          title = ' '
        },
        {
          title = 'Изменить горячую клавишу',
          onclick = function()
            lua_thread.create(cmdChangeDrugsHotkey)
          end
        },
        {
          title = 'Изменить задержку нарко',
          onclick = function()
            lua_thread.create(cmdChangeUsedrugsDelay)
          end
        },
        {
          title = 'Включить/выключить ПДИНЬ',
          onclick = function()
            cmdChangeUsedrugsSoundActive()
          end
        },
        {
          title = ' '
        },
        {
          title = '{AAAAAA}Настройки TextDraw'
        },
        {
          title = 'Настройки "Drugs"',
          submenu = {
            {
              title = '[0] Изменить стиль оформления "Drugs"',
              submenu = {
                {
                  title = '[0] Выбрать тип оверлея - "Drugs"',
                  onclick = function()
                    cmdChangeDrugsTxdType(0)
                  end
                },
                {
                  title = '[1] Выбрать тип оверлея - "Drugs 150"',
                  onclick = function()
                    cmdChangeDrugsTxdType(1)
                  end
                },
                {
                  title = '[2] Выбрать тип оверлея - "150"',
                  onclick = function()
                    cmdChangeDrugsTxdType(2)
                  end
                },
              },
            },
            {
              title = '[1] Изменить шрифт "Drugs"',
              submenu = {
                {
                  title = '[0] "The San Andreas Font"',
                  onclick = function()
                    cmdChangeDrugsTxdStyle(0)
                  end
                },
                {
                  title = '[1] "Both case characters"',
                  onclick = function()
                    cmdChangeDrugsTxdStyle(1)
                  end
                },
                {
                  title = '[2] "Only capital letters"',
                  onclick = function()
                    cmdChangeDrugsTxdStyle(2)
                  end
                },
                {
                  title = '[3] "Стандартный"',
                  onclick = function()
                    cmdChangeDrugsTxdStyle(3)
                  end
                },
              },
              {
                title = '[4] Восстановить дефолтные настройки',
                onclick = function()
                  cmdDrugsTxdDefault()
                end
              }
            },
            {
              title = '[2] Изменить положение и размер "Drugs"',
              submenu = {
                {
                  title = '[0] Изменить положение и размер "Drugs"',
                  onclick = function()
                    cmdChangeDrugsPos(0)
                  end
                },
                {
                  title = '[1] Восстановить дефолтные настройки',
                  onclick = function()
                    cmdChangeDrugsPos(1)
                  end
                }
              },
            },
          }
        },
        {
          title = 'Настройки "DrugsTimer"',
          submenu = {
            {
              title = '[0] Изменить шрифт "DrugsTimer"',
              submenu = {
                {
                  title = '[0] "The San Andreas Font"',
                  onclick = function()
                    cmdChangeDrugsTimerTxdStyle(0)
                  end
                },
                {
                  title = '[1] "Both case characters"',
                  onclick = function()
                    cmdChangeDrugsTimerTxdStyle(1)
                  end
                },
                {
                  title = '[2] "Only capital letters"',
                  onclick = function()
                    cmdChangeDrugsTimerTxdStyle(2)
                  end
                },
                {
                  title = '[3] "Стандартный"',
                  onclick = function()
                    cmdChangeDrugsTimerTxdStyle(3)
                  end
                },
              },
            },
            {
              title = '[1] Изменить положение и размер "DrugsTimer"',
              submenu = {
                {
                  title = '[0] Изменить положение и размер "DrugsTimer"',
                  onclick = function()
                    cmdChangeDrugsTimerPos(0)
                  end
                },
                {
                  title = '[1] Восстановить дефолтные настройки',
                  onclick = function()
                    cmdChangeDrugsTimerPos(1)
                  end
                }
              },
            },
            {
              title = '[2] Восстановить дефолтные настройки',
              onclick = function()
                cmdDrugsTimerDefault()
              end
            }
          }
        },
        {
          title = 'Восстановить дефолтные настройки',
          onclick = function()
            cmdDrugsTxdDefault()
            cmdDrugsTimerDefault()
          end
        }
      }
    },
    {
      title = ' '
    },
    {
      title = 'Показать changelog',
      onclick = function()
        wait(100)
        showlog()
      end
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
      loadstring("kv"..tostring(i).."_"..tostring(z).." = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/"..tostring(i).."-"..tostring(z)..".png')")()
    end
  end
  player = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/pla.png')
  player1 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/radar_centre.png')
  radar_girlfriend = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/radar_girlfriend.png')
  radar_police = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/radar_police.png')


  matavoz = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/matavoz.png')
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
  m1 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/1.png')
  m2 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/2.png')
  m3 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/3.png')
  m4 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/4.png')
  m5 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/5.png')
  m6 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/6.png')
  m7 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/7.png')
  m8 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/8.png')
  m9 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/9.png')
  m10 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/10.png')
  m11 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/11.png')
  m12 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/12.png')
  m13 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/13.png')
  m14 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/14.png')
  m15 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/15.png')
  m16 = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/16.png')
  m1k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/1k.png')
  m2k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/2k.png')
  m3k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/3k.png')
  m4k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/4k.png')
  m5k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/5k.png')
  m6k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/6k.png')
  m7k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/7k.png')
  m8k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/8k.png')
  m9k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/9k.png')
  m10k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/10k.png')
  m11k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/11k.png')
  m12k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/12k.png')
  m13k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/13k.png')
  m14k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/14k.png')
  m15k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/15k.png')
  m16k = renderLoadTextureFromFile(getGameDirectory()..'/moonloader/resource/edith/16k.png')
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
--------------------------------------------------------------------------------
--------------------------------ТАЙМЕР НАРКОТИКОВ-------------------------------
--------------------------------------------------------------------------------
function usedrugs()
  if settings.usedrugs.isactive == 1 then
    if settings.usedrugs.txdtype == 0 then
      sampTextdrawCreate(617, "Drugs", settings.usedrugs.posX1, settings.usedrugs.posY1)
    end
    if settings.usedrugs.txdtype == 1 then
      sampTextdrawCreate(617, "Drugs "..intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
    end
    if settings.usedrugs.txdtype == 2 then
      sampTextdrawCreate(617, intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
    end
    if settings.score.enable then
      ust = lua_thread.create(usedrugstimer)
    end
    sampTextdrawSetStyle(617, settings.usedrugs.style1)
    sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
    sampTextdrawSetOutlineColor(617, 1, - 16777216)
    narkotrigger = true
    while true do
      wait(0)
      if isKeyJustPressed(settings.usedrugs.key) and sampIsDialogActive() == false and sampIsChatInputActive() == false and isPauseMenuActive() == false then
        if narkotrigger == true then
          if stopscan == nil then stopscan = 0 end
          kolvousedrugs = math.ceil((160 - getCharHealth(playerPed)) / 10)
          if kolvousedrugs == 0 then kolvousedrugs = 1 end
          if intim.usedrugs.kolvo ~= "???" and kolvousedrugs > tonumber(intim.usedrugs.kolvo) and tonumber(intim.usedrugs.kolvo) > 0 then kolvousedrugs = tonumber(intim.usedrugs.kolvo) end
          if kolvousedrugs == 16 then kolvousedrugs = 15 end
          if narkotrigger == true then sampSendChat("/usedrugs "..kolvousedrugs) end
        elseif isKeyDown(settings.usedrugs.key) then
          wait(200)
          if isKeyDown(settings.usedrugs.key) then
            sampSendChat("/usedrugs 1")
          end
        end
      end
    end
  end
end

function usedrugstimer()
  while true do
    wait(0)
    if narkotrigger == false then sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 ) end
    while narkotrigger == false do
      wait(0)
      sampTextdrawCreate(618, intim.usedrugs.lasttime + settings.usedrugs.cooldown - os.time(), settings.usedrugs.posX2, settings.usedrugs.posY2)
      sampTextdrawSetStyle(618, settings.usedrugs.style2)
      sampTextdrawSetLetterSizeAndColor(618, settings.usedrugs.size3, settings.usedrugs.size4, - 13447886)
      sampTextdrawSetOutlineColor(618, 1, - 16777216)
      if intim.usedrugs.lasttime + settings.usedrugs.cooldown <= os.time() then
        sampTextdrawDelete(618)
        if settings.usedrugs.sound == 1 and isKeyDown(settings.usedrugs.key) == false then addOneOffSound(0.0, 0.0, 0.0, 1057) end
        sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
        narkotrigger = true
      end
    end
  end
end
--------------------------------------------------------------------------------
---------------------------------CAPTURETIMER-----------------------------------
--------------------------------------------------------------------------------
function capturetimer()
  while true do
    wait(250)
    if settings.capturetimer.enable then
      if os.time() - checkafk > 2 then
        wasafk = true
        lua_thread.create(function() wait(2000) wasafk = false end)
      end
      checkafk = os.time()
      if timeleft_type ~= 0 then
        if timeleft_type == 25 then
          timeleft = timeleft_base + 1500 - os.time()
        elseif timeleft_type == 10 then
          timeleft = timeleft_base + 600 - os.time()
        elseif timeleft_type == 2 then
          timeleft = timeleft_base + 120 - os.time()
        end
        if timeleft < 600 then
          timeleft_minute = math.floor(timeleft / 60)
          timeleft_seconds = timeleft % 60
          if timeleft_minute < 10 then timeleft_minute = "0"..timeleft_minute end
          if timeleft_seconds < 10 then timeleft_seconds = "0"..timeleft_seconds end
          sampTextdrawCreate(471, timeleft_minute..":"..timeleft_seconds, 588, 428)
          sampTextdrawSetStyle(471, 3)
          sampTextdrawSetLetterSizeAndColor(471, 0.5, 2, - 65536)
          sampTextdrawSetOutlineColor(471, 1, - 16777216)
        else
          timeleft_minute = math.floor(timeleft / 60)
          timeleft_seconds = timeleft % 60
          if timeleft_minute < 10 then timeleft_minute = "0"..timeleft_minute end
          if timeleft_seconds < 10 then timeleft_seconds = "0"..timeleft_seconds end
          sampTextdrawCreate(471, timeleft_minute..":"..timeleft_seconds, 588, 428)
          sampTextdrawSetStyle(471, 3)
          sampTextdrawSetLetterSizeAndColor(471, 0.5, 2, - 13447886)
          sampTextdrawSetOutlineColor(471, 1, - 16777216)
        end
      else
        if sampTextdrawIsExists(471) then
          sampTextdrawDelete(471)
        end
      end
    end
  end
end
--------------------------------------------------------------------------------
-------------------------------НАСТРОЙКИ НАРКОТИКОВ-----------------------------
--------------------------------------------------------------------------------
function cmdChangeDrugsHotkey()
  sampShowDialog(989, "Изменение горячей клавиши", "Нажмите \"Окей\", после чего нажмите нужную клавишу.\nНастройки будут изменены.", "Окей", "Закрыть")
  while sampIsDialogActive(989) do wait(100) end
  local resultMain, buttonMain, typ = sampHasDialogRespond(988)
  if buttonMain == 1 then
    while ke1y == nil do
      wait(0)
      for i = 1, 200 do
        if isKeyDown(i) then
          settings.usedrugs.key = i
          sampAddChatMessage("Установлена новая горячая клавиша - "..settings.usedrugs.key, color)
          inicfg.save(settings, "edith") ke1y = 1 break
        end
      end
    end
  end
  ke1y = nil
end

function cmdDrugsTxdDefault()
  settings.usedrugs.style1 = 3
  settings.usedrugs.posX1 = 56
  settings.usedrugs.posY1 = 424
  settings.usedrugs.size1 = 0.6
  settings.usedrugs.size2 = 1.2
  inicfg.save(settings, "edith")
  usedrugs:terminate()
  if narkotrigger == false then
    usedrugs:run()
    wait(100)
    narkotrigger = false
  else
    usedrugs:run()
  end
end

function cmdDrugsTimerDefault()
  settings.usedrugs.style2 = 3
  settings.usedrugs.posX2 = 80
  settings.usedrugs.posY2 = 315
  settings.usedrugs.size3 = 0.4
  settings.usedrugs.size4 = 2
  inicfg.save(settings, "edith")
  usedrugs:terminate()
  if narkotrigger == false then
    usedrugs:run()
    wait(100)
    narkotrigger = false
  else
    usedrugs:run()
  end
end

function cleardrugstxds()
  sampTextdrawDelete(617)
  sampTextdrawDelete(618)
end

function cmdChangeUsedrugsDelay()
  sampShowDialog(989, "Установка задержки нарко", string.format("Введите задержку в секундах.\nТекущая задержка: "..settings.usedrugs.cooldown.." сек."), "Выбрать", "Закрыть", 1)
  while sampIsDialogActive() do wait(100) end
  if tonumber(sampGetCurrentDialogEditboxText(989)) ~= nil then
    settings.usedrugs.cooldown = tonumber(sampGetCurrentDialogEditboxText(989))
    inicfg.save(settings, "edith")
  end
end

function cmdChangeUsedrugsActive()
  if settings.usedrugs.isactive == 1 then settings.usedrugs.isactive = 0 sampAddChatMessage('[EDITH]: Таймер нарко деактивирован.', color) cleardrugstxds()
    usedrugs:terminate()
  else settings.usedrugs.isactive = 1 sampAddChatMessage('[EDITH]: Таймер нарко активирован.', color)
    if narkotrigger == false then
      usedrugs:run()
      wait(100)
      narkotrigger = false
    else
      usedrugs:run()
    end
  end
  inicfg.save(settings, "edith")
end

function cmdChangeUsedrugsSoundActive()
  if settings.usedrugs.sound == 1 then settings.usedrugs.sound = 0 sampAddChatMessage('[EDITH]: "ПДИНЬ" при истечении кд нарко выключен.', color) else settings.usedrugs.sound = 1 sampAddChatMessage('[EDITH]: "ПДИНЬ" при истечении кд нарко включен.', color)
  end
  inicfg.save(settings, "edith")
end

function cmdChangeDrugsTxdType(param)
  local txdtype = tonumber(param)
  if txdtype == 0 then settings.usedrugs.txdtype = 0 end
  if txdtype == 1 then settings.usedrugs.txdtype = 1 end
  if txdtype == 2 then settings.usedrugs.txdtype = 2 end
  inicfg.save(settings, "edith")
  usedrugs:terminate()
  if narkotrigger == false then
    usedrugs:run()
    wait(100)
    narkotrigger = false
  else
    usedrugs:run()
  end
end

function cmdChangeDrugsPos(param)
  local drugspostype = tonumber(param)
  if drugspostype == 0 then
    local bckpX1 = settings.usedrugs.posX1
    local bckpY1 = settings.usedrugs.posY1
    local bckpS1 = settings.usedrugs.size1
    local bckpS2 = settings.usedrugs.size2
    sampShowDialog(3838, "Изменение положения и размера.", "{ffcc00}Изменение положения textdraw.\n{ffffff}Изменить положение можно с помощью стрелок клавы.\n\n{ffcc00}Изменение размера textdraw.\n{ffffff}Изменить размер ПРОПОРЦИОНАЛЬНО можно с помощью {00ccff}'-'{ffffff} и {00ccff}'+'{ffffff}.\n{ffffff}Изменить размер по горизонтали можно с помощью {00ccff}'9'{ffffff} и {00ccff}'0'{ffffff}.\n{ffffff}Изменить размер по вертикали можно с помощью {00ccff}'7'{ffffff} и {00ccff}'8'{ffffff}.\n\n{ffcc00}Как принять изменения?\n{ffffff}Нажмите \"Enter\", чтобы принять изменения.\nНажмите пробел, чтобы отменить изменения.\nВ меню можно восстановить дефолт.", "Я понял")
    while sampIsDialogActive(3838) == true do wait(100) end
    while true do
      wait(0)
      if bckpY1 > 0 and bckpY1 < 480 and bckpX1 > 0 and bckpX1 < 640 then
        wait(0)
        if isKeyDown(40) and bckpY1 + 1 < 480 then bckpY1 = bckpY1 + 1 end
        if isKeyDown(38) and bckpY1 - 1 > 0 then bckpY1 = bckpY1 - 1 end
        if isKeyDown(37) and bckpX1 - 1 > 0 then bckpX1 = bckpX1 - 1 end
        if isKeyDown(39) and bckpX1 + 1 < 640 then bckpX1 = bckpX1 + 1 end
        if isKeyJustPressed(57) then
          if bckpS1 - 0.1 > 0 then
            bckpS1 = bckpS1 - 0.1
          end
        end
        if isKeyJustPressed(48) then
          if bckpS1 + 0.1 > 0 then
            bckpS1 = bckpS1 + 0.1
          end
        end

        if isKeyJustPressed(55) then
          if bckpS2 - 0.1 > 0 then
            bckpS2 = bckpS2 - 0.1
          end
        end
        if isKeyJustPressed(56) then
          if bckpS2 + 0.1 > 0 then
            bckpS2 = bckpS2 + 0.1
          end
        end
        if isKeyJustPressed(189) then
          if bckpS1 - 0.1 > 0 then
            bckpS1 = bckpS1 - 0.1
            bckpS2 = bckpS1 * 2
          end
        end
        if isKeyJustPressed(187) then
          if bckpS1 + 0.1 > 0 then
            bckpS1 = bckpS1 + 0.1
            bckpS2 = bckpS1 * 2
          end
        end
        if settings.usedrugs.isactive == 1 then
          if settings.usedrugs.txdtype == 0 then
            sampTextdrawCreate(617, "Drugs", bckpX1, bckpY1)
          end
          if settings.usedrugs.txdtype == 1 then
            sampTextdrawCreate(617, "Drugs "..intim.usedrugs.kolvo, bckpX1, bckpY1)
          end
          if settings.usedrugs.txdtype == 2 then
            sampTextdrawCreate(617, intim.usedrugs.kolvo, bckpX1, bckpY1)
          end
          sampTextdrawSetStyle(617, settings.usedrugs.style1)
          sampTextdrawSetLetterSizeAndColor(617, bckpS1, bckpS2, - 13447886)
          sampTextdrawSetOutlineColor(617, 1, - 16777216)
        end
        if isKeyJustPressed(13) then
          settings.usedrugs.posX1 = bckpX1
          settings.usedrugs.posY1 = bckpY1
          settings.usedrugs.size1 = bckpS1
          settings.usedrugs.size2 = bckpS2
          addOneOffSound(0.0, 0.0, 0.0, 1052)
          inicfg.save(settings, "edith")
          usedrugs:terminate()
          if narkotrigger == false then
            usedrugs:run()
            wait(100)
            narkotrigger = false
          else
            usedrugs:run()
          end
          break
        end
        if isKeyJustPressed(32) then
          addOneOffSound(0.0, 0.0, 0.0, 1053)
          usedrugs:terminate()
          if narkotrigger == false then
            usedrugs:run()
            wait(100)
            narkotrigger = false
          else
            usedrugs:run()
          end
          break
        end
      end
    end
  end
  if drugspostype == 1 then
    settings.usedrugs.posX1 = 56
    settings.usedrugs.posY1 = 424
    settings.usedrugs.size1 = 0.6
    settings.usedrugs.size2 = 1.2
    addOneOffSound(0.0, 0.0, 0.0, 1052)
    inicfg.save(settings, "edith")
    usedrugs:terminate()
    if narkotrigger == false then
      usedrugs:run()
      wait(100)
      narkotrigger = false
    else
      usedrugs:run()
    end
  end
end

function cmdChangeDrugsTimerPos(param)
  local drugspostype = tonumber(param)
  if drugspostype == 0 then
    local bckpX1 = settings.usedrugs.posX2
    local bckpY1 = settings.usedrugs.posY2
    local bckpS1 = settings.usedrugs.size3
    local bckpS2 = settings.usedrugs.size4
    sampShowDialog(3838, "Изменение положения и размера.", "{ffcc00}Изменение положения textdraw.\n{ffffff}Изменить положение можно с помощью стрелок клавы.\n\n{ffcc00}Изменение размера textdraw.\n{ffffff}Изменить размер ПРОПОРЦИОНАЛЬНО можно с помощью {00ccff}'-'{ffffff} и {00ccff}'+'{ffffff}.\n{ffffff}Изменить размер по горизонтали можно с помощью {00ccff}'9'{ffffff} и {00ccff}'0'{ffffff}.\n{ffffff}Изменить размер по вертикали можно с помощью {00ccff}'7'{ffffff} и {00ccff}'8'{ffffff}.\n\n{ffcc00}Как принять изменения?\n{ffffff}Нажмите \"Enter\", чтобы принять изменения.\nНажмите пробел, чтобы отменить изменения.\nВ меню можно восстановить дефолт.", "Я понял")
    while sampIsDialogActive(3838) == true do wait(100) end
    while true do
      wait(0)
      if bckpY1 > 0 and bckpY1 < 480 and bckpX1 > 0 and bckpX1 < 640 then
        wait(0)
        if isKeyDown(40) and bckpY1 + 1 < 480 then bckpY1 = bckpY1 + 1 end
        if isKeyDown(38) and bckpY1 - 1 > 0 then bckpY1 = bckpY1 - 1 end
        if isKeyDown(37) and bckpX1 - 1 > 0 then bckpX1 = bckpX1 - 1 end
        if isKeyDown(39) and bckpX1 + 1 < 640 then bckpX1 = bckpX1 + 1 end
        if isKeyJustPressed(57) then
          if bckpS1 - 0.1 > 0 then
            bckpS1 = bckpS1 - 0.1
          end
        end
        if isKeyJustPressed(48) then
          if bckpS1 + 0.1 > 0 then
            bckpS1 = bckpS1 + 0.1
          end
        end
        if isKeyJustPressed(55) then
          if bckpS2 - 0.1 > 0 then
            bckpS2 = bckpS2 - 0.1
          end
        end
        if isKeyJustPressed(56) then
          if bckpS2 + 0.1 > 0 then
            bckpS2 = bckpS2 + 0.1
          end
        end
        if isKeyJustPressed(57) then
          if bckpS1 - 0.1 > 0 then
            bckpS1 = bckpS1 - 0.1
          end
        end
        if isKeyJustPressed(48) then
          if bckpS1 + 0.1 > 0 then
            bckpS1 = bckpS1 + 0.1
          end
        end
        if isKeyJustPressed(55) then
          if bckpS2 - 0.1 > 0 then
            bckpS2 = bckpS2 - 0.1
          end
        end
        if isKeyJustPressed(56) then
          if bckpS2 + 0.1 > 0 then
            bckpS2 = bckpS2 + 0.1
          end
        end
        if isKeyJustPressed(189) then
          if bckpS1 - 0.1 > 0 then
            bckpS1 = bckpS1 - 0.1
            bckpS2 = bckpS1 * 5
          end
        end
        if isKeyJustPressed(187) then
          if bckpS1 + 0.1 > 0 then
            bckpS1 = bckpS1 + 0.1
            bckpS2 = bckpS1 * 5
          end
        end
        if settings.usedrugs.isactive == 1 then
          sampTextdrawCreate(422, "69", bckpX1, bckpY1)
          sampTextdrawSetStyle(422, settings.usedrugs.style2)
          sampTextdrawSetLetterSizeAndColor(422, bckpS1, bckpS2, - 13447886)
          sampTextdrawSetOutlineColor(422, 1, - 16777216)
        end
        if isKeyJustPressed(13) then
          sampTextdrawDelete(422)
          if narkotrigger == false then sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 ) end
          settings.usedrugs.posX2 = bckpX1
          settings.usedrugs.posY2 = bckpY1
          settings.usedrugs.size3 = bckpS1
          settings.usedrugs.size4 = bckpS2
          addOneOffSound(0.0, 0.0, 0.0, 1052)
          inicfg.save(settings, "edith")
          usedrugs:terminate()
          if narkotrigger == false then
            usedrugs:run()
            wait(100)
            narkotrigger = false
          else
            usedrugs:run()
          end
          break
        end
        if isKeyJustPressed(32) then
          sampTextdrawDelete(422)
          addOneOffSound(0.0, 0.0, 0.0, 1053)
          usedrugs:terminate()
          if narkotrigger == false then
            usedrugs:run()
            wait(100)
            narkotrigger = false
          else
            usedrugs:run()
          end
          break
        end
      end
    end
  end
  if drugspostype == 1 then
    sampTextdrawDelete(618)
    settings.usedrugs.posX2 = 80
    settings.usedrugs.posY2 = 315
    settings.usedrugs.size3 = 0.4
    settings.usedrugs.size4 = 2
    addOneOffSound(0.0, 0.0, 0.0, 1052)
    inicfg.save(settings, "edith")
    usedrugs:terminate()
    if narkotrigger == false then
      usedrugs:run()
      wait(100)
      narkotrigger = false
    else
      usedrugs:run()
    end
  end
end

function cmdChangeDrugsTxdStyle(param)
  local txdstyle = tonumber(param)
  settings.usedrugs.style1 = txdstyle
  addOneOffSound(0.0, 0.0, 0.0, 1052)
  inicfg.save(settings, "edith")
  usedrugs:terminate()
  if narkotrigger == false then
    usedrugs:run()
    wait(100)
    narkotrigger = false
  else
    usedrugs:run()
  end
end

function cmdChangeDrugsTimerTxdStyle(param)
  local txdstyle = tonumber(param)
  settings.usedrugs.style2 = txdstyle
  addOneOffSound(0.0, 0.0, 0.0, 1052)
  inicfg.save(settings, "edith")
  usedrugs:terminate()
  if narkotrigger == false then
    usedrugs:run()
    wait(100)
    narkotrigger = false
  else
    usedrugs:run()
  end
end
--------------------------------------------------------------------------------
-------------------------------------SCORE--------------------------------------
--------------------------------------------------------------------------------
function score()
  if settings.score.enable then
    sampTextdrawCreate(440, "0", settings.score.posX, settings.score.posY)
    sampTextdrawSetStyle(440, 3)
    sampTextdrawSetLetterSizeAndColor(440, settings.score.size1, settings.score.size2, - 1)
    sampTextdrawSetOutlineColor(440, 1, - 16777216)

    lua_thread.create(
      function()
        while true do
          wait(200)
          if settings.score.enable and isCharDead(PLAYER_PED) then
            if killer ~= nil and killer_id ~= nil and killer_w ~= nil and killer_b ~= nil and k_given ~= nil and k_kills ~= nil then
              sampAddChatMessage("{7ef3fa}[EDITH]:{ef3226} "..killer.."{808080}["..killer_id.."]{ffffff} убил вас из {ef3226}"..getweaponname(killer_w).."{ffffff} прямо в {ef3226}"..getbodypart(killer_b)..".", - 1)
              sampAddChatMessage("{7ef3fa}[EDITH]: {ffffff}За жизнь вы нанесли {ef3226}"..math.floor(k_given).."{ffffff} урона, у вас {ef3226}"..k_kills.."{ffffff} "..getending(k_kills)..".", - 1)
            end
            k_given = 0
            k_kills = 0
            deaths = deaths + 1
            settings.stats.deaths = settings.stats.deaths + 1
            inicfg.save(settings, "edith")
            while isCharDead(PLAYER_PED) ~= false do
              wait(200)
            end
          end
        end
      end
    )
    while true do
      wait(10)
      if isKeyDown(settings.score.key1) and sampIsDialogActive() == false and sampIsChatInputActive() == false and isPauseMenuActive() == false then
        if mode then
          sampTextdrawSetString(440, string.format("%2.1f", settings.stats.dmg))
        else
          sampTextdrawSetString(440, string.format("%2.1f", given))
        end
      elseif isKeyDown(settings.score.key2) and sampIsDialogActive() == false and sampIsChatInputActive() == false and isPauseMenuActive() == false then
        if mode then
          sampTextdrawSetString(440, string.format("K:%d", settings.stats.kills))
        else
          sampTextdrawSetString(440, string.format("K:%d", kills))
        end
      elseif isKeyDown(settings.score.key3) and sampIsDialogActive() == false and sampIsChatInputActive() == false and isPauseMenuActive() == false then
        if mode then
          sampTextdrawSetString(440, string.format("D:%d", settings.stats.deaths))
        else
          sampTextdrawSetString(440, string.format("D:%d", deaths))
        end
      elseif isKeyDown(settings.score.key4) and sampIsDialogActive() == false and sampIsChatInputActive() == false and isPauseMenuActive() == false then
        if mode then
          sampTextdrawSetString(440, string.format("K/D:%2.1f", settings.stats.kills / settings.stats.deaths))
        else
          sampTextdrawSetString(440, string.format("K/D:%2.1f", kills / deaths))
        end
      elseif wasKeyPressed(settings.score.key5) and sampIsDialogActive() == false and sampIsChatInputActive() == false and isPauseMenuActive() == false then
        mode = not mode
        addOneOffSound(0.0, 0.0, 0.0, 1052)
        if mode then
          sampTextdrawSetLetterSizeAndColor(440, settings.score.size1, settings.score.size2, - 65536)
        else
          sampTextdrawSetLetterSizeAndColor(440, settings.score.size1, settings.score.size2, - 1)
        end
      else
        if mode then
          sampTextdrawSetString(440, string.format("%2.1f", k_given))
        else
          sampTextdrawSetString(440, string.format("%2.1f", k_given))
        end
      end
    end
  end
end

function getending(count)
  count = count % 10
  if count == 0 then
    return "убийств"
  elseif count == 1 then
    return "убийство"
  elseif count == 2 or count == 3 or count == 4 then
    return "убийства"
  elseif count > 5 then
    return "убийств"
  end
end

function resetscore()
  settings.stats.dmg = 0
  settings.stats.kills = 0
  settings.stats.deaths = 0
  k_given = 0
  given = 0
  kills = 0
  k_kills = 0
  deaths = 0
  addOneOffSound(0.0, 0.0, 0.0, 1052)
  inicfg.save(settings, "edith")
end

function changepos()
  local bckpX1 = settings.score.posX
  local bckpY1 = settings.score.posY
  local bckpS1 = settings.score.size1
  local bckpS2 = settings.score.size2
  sampShowDialog(3838, "Изменение положения и размера.", "{ffcc00}Изменение положения textdraw.\n{ffffff}Изменить положение можно с помощью стрелок клавы.\n\n{ffcc00}Изменение размера textdraw.\n{ffffff}Изменить размер ПРОПОРЦИОНАЛЬНО можно с помощью {00ccff}'-'{ffffff} и {00ccff}'+'{ffffff}.\n{ffffff}Изменить размер по горизонтали можно с помощью {00ccff}'9'{ffffff} и {00ccff}'0'{ffffff}.\n{ffffff}Изменить размер по вертикали можно с помощью {00ccff}'7'{ffffff} и {00ccff}'8'{ffffff}.\n\n{ffcc00}Как принять изменения?\n{ffffff}Нажмите \"Enter\", чтобы принять изменения.\nНажмите пробел, чтобы отменить изменения.\nВ меню можно восстановить дефолт.", "Я понял")
  while sampIsDialogActive(3838) == true do wait(100) end
  while true do
    wait(0)
    if bckpY1 > 0 and bckpY1 < 480 and bckpX1 > 0 and bckpX1 < 640 then
      wait(0)
      if isKeyDown(40) and bckpY1 + 1 < 480 then bckpY1 = bckpY1 + 1 end
      if isKeyDown(38) and bckpY1 - 1 > 0 then bckpY1 = bckpY1 - 1 end
      if isKeyDown(37) and bckpX1 - 1 > 0 then bckpX1 = bckpX1 - 1 end
      if isKeyDown(39) and bckpX1 + 1 < 640 then bckpX1 = bckpX1 + 1 end
      if isKeyJustPressed(57) then
        if bckpS1 - 0.1 > 0 then
          bckpS1 = bckpS1 - 0.1
        end
      end
      if isKeyJustPressed(48) then
        if bckpS1 + 0.1 > 0 then
          bckpS1 = bckpS1 + 0.1
        end
      end
      if isKeyJustPressed(55) then
        if bckpS2 - 0.1 > 0 then
          bckpS2 = bckpS2 - 0.1
        end
      end
      if isKeyJustPressed(56) then
        if bckpS2 + 0.1 > 0 then
          bckpS2 = bckpS2 + 0.1
        end
      end
      if isKeyJustPressed(57) then
        if bckpS1 - 0.1 > 0 then
          bckpS1 = bckpS1 - 0.1
        end
      end
      if isKeyJustPressed(48) then
        if bckpS1 + 0.1 > 0 then
          bckpS1 = bckpS1 + 0.1
        end
      end
      if isKeyJustPressed(55) then
        if bckpS2 - 0.1 > 0 then
          bckpS2 = bckpS2 - 0.1
        end
      end
      if isKeyJustPressed(56) then
        if bckpS2 + 0.1 > 0 then
          bckpS2 = bckpS2 + 0.1
        end
      end
      if isKeyJustPressed(189) then
        if bckpS1 - 0.1 > 0 then
          bckpS1 = bckpS1 - 0.1
          bckpS2 = bckpS1 * 5
        end
      end
      if isKeyJustPressed(187) then
        if bckpS1 + 0.1 > 0 then
          bckpS1 = bckpS1 + 0.1
          bckpS2 = bckpS1 * 5
        end
      end
      sampTextdrawCreate(422, "999", bckpX1, bckpY1)
      sampTextdrawSetStyle(422, 3)
      sampTextdrawSetLetterSizeAndColor(422, bckpS1, bckpS2, - 1)
      sampTextdrawSetOutlineColor(422, 1, - 16777216)
      if isKeyJustPressed(13) then
        sampTextdrawDelete(422)
        settings.score.posX = bckpX1
        settings.score.posY = bckpY1
        settings.score.size1 = bckpS1
        settings.score.size2 = bckpS2
        addOneOffSound(0.0, 0.0, 0.0, 1052)
        inicfg.save(settings, "edith")
        sampTextdrawSetPos(440, settings.score.posX, settings.score.posY)
        sampTextdrawSetLetterSizeAndColor(440, settings.score.size1, settings.score.size2, - 1)
        break
      end
      if isKeyJustPressed(32) then
        sampTextdrawDelete(422)
        addOneOffSound(0.0, 0.0, 0.0, 1053)
        break
      end
    end
  end
end

function changehotkey(mode)
  local modes =
    {
      [1] = " для дамага за всё время",
      [2] = " для убийств",
      [3] = " для смертей",
      [4] = " для k/d",
      [5] = " для смены режима сеанс/всё время"
    }
  if tonumber(mode) == nil or tonumber(mode) < 1 or tonumber(mode) > 5 then
    sampAddChatMessage("1) Посмотреть дамаг за сеанс: "..key.id_to_name(settings.score.key1)..". 2) Посмотреть убийства: "..key.id_to_name(settings.score.key2)..". 3) Посмотреть смерти: "..key.id_to_name(settings.score.key3)..". 4) k/d: "..key.id_to_name(settings.score.key4)..". 5) Сеанс/всё время: "..key.id_to_name(settings.score.key5)..".", - 1)
    sampAddChatMessage("Изменить: /ediscorekey [1|2|3|4|5]", - 1)
  else
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
              settings.score.key1 = i
            end
            if mode == 2 then
              settings.score.key2 = i
            end
            if mode == 3 then
              settings.score.key3 = i
            end
            if mode == 4 then
              settings.score.key4 = i
            end
            if mode == 5 then
              settings.score.key5 = i
            end
            print(i)
            sampAddChatMessage("Установлена новая горячая клавиша - "..key.id_to_name(i), - 1)
            addOneOffSound(0.0, 0.0, 0.0, 1052)
            inicfg.save(settings, "edith")
            ke1y = 1
            break
          end
        end
      end
    end
    ke1y = nil
  end
end

function getbodypart(part)
  local names = {
    [3] = "Торс",
    [4] = "Писю",
    [5] = "Левую руку",
    [6] = "Правую руку",
    [7] = "Левую ногу",
    [8] = "Правую ногу",
    [9] = "Голову"
  }
  return names[part]
end

function getweaponname(weapon) -- getweaponname by FYP
  local names = {
    [0] = "Кулака",
    [1] = "Кастета",
    [2] = "Клюшки для гольфа",
    [3] = "Полицейской дубинки",
    [4] = "Ножа",
    [5] = "Биты",
    [6] = "Лопаты",
    [7] = "Кия",
    [8] = "Катаны",
    [9] = "Бензопилы",
    [10] = "Розового дилдо",
    [11] = "Дилдо",
    [12] = "Вибратора",
    [13] = "Серебрянного вибратора",
    [14] = "Цветов",
    [15] = "Трости",
    [16] = "Гранаты",
    [17] = "Слезоточивого газа",
    [18] = "Коктейля молотова",
    [22] = "Пистолета",
    [23] = "Пистолета с глушителем",
    [24] = "Deagle",
    [25] = "Shotgun",
    [26] = "Обреза",
    [27] = "Боевого дробовика",
    [28] = "Micro SMG/Uzi",
    [29] = "MP5",
    [30] = "AK-47",
    [31] = "M4",
    [32] = "Tec-9",
    [33] = "Винтовки",
    [34] = "Снайперской винтовки",
    [35] = "РПГ",
    [36] = "HS Rocket",
    [37] = "Огнемёта",
    [38] = "Минигана",
    [39] = "Satchel Charge",
    [40] = "Detonator",
    [41] = "Газового балончика",
    [42] = "Огнетушителя",
    [43] = "Camera",
    [44] = "Night Vis Goggles",
    [45] = "Thermal Goggles",
    [46] = "Parachute" }
return names[weapon]
end
--------------------------------------------------------------------------------
-------------------------------------BLIST--------------------------------------
--------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------
------------------------------------SAMPEV--------------------------------------
--------------------------------------------------------------------------------
function sampev.onSendDialogResponse(dialogId, button, listboxId, input)
  lua_thread.create(
    function()
      if connected and not offline and getActiveInterior() == 11 and button == 1 and sampGetCurrentDialogId() == 123 then
        if listboxId == 0 then listboxId = "Deagle" end
        if listboxId == 1 then listboxId = "Shotgun" end
        if listboxId == 2 then listboxId = "SMG" end
        if listboxId == 3 then listboxId = "AK47" end
        if listboxId == 4 then listboxId = "M4" end
        if listboxId == 5 then listboxId = "Rifle" end

        client:send(encodeJson({nick = licensenick, typ = "take", subject = listboxId}))
      end
    end
  )
end

function sampev.onServerMessage(color, text)
  if text ~= nil then
    if settings.usedrugs.isactive == 1 then
      if string.find(text, "Здоровье пополнено") then
        intim.usedrugs.lasttime = os.time()
        narkotrigger = false
        stopscan = nil
        inicfg.save(intim, 'EDITH\\'..serverip..'-'..playernick)
      end
      if string.find(text, "(У вас есть (%d+) грамм)") then
        if string.match(text, "(%d+)", string.find(text, "(У вас есть (%d+) грамм)")) ~= nil and string.match(text, "(%d+)", string.find(text, "(У вас есть (%d+) грамм)")) ~= intim.usedrugs.kolvo then
          intim.usedrugs.kolvo = string.match(text, "(%d+)", string.find(text, "(У вас есть (%d+) грамм)"))
          inicfg.save(intim, 'EDITH\\'..serverip..'-'..playernick)
          if settings.usedrugs.txdtype == 1 then
            sampTextdrawCreate(617, "Drugs "..intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
            sampTextdrawSetStyle(617, settings.usedrugs.style1)
            if os.time() < intim.usedrugs.lasttime + settings.usedrugs.cooldown then
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 )
            else
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
            end
            sampTextdrawSetOutlineColor(617, 1, - 16777216)
          end
          if settings.usedrugs.txdtype == 2 then
            sampTextdrawCreate(617, intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
            sampTextdrawSetStyle(617, settings.usedrugs.style1)
            if os.time() < intim.usedrugs.lasttime + settings.usedrugs.cooldown then
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 )
            else
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
            end
            sampTextdrawSetOutlineColor(617, 1, - 16777216)
          end
          text = nil
        end
      end
      if text == " Вы взяли из сейфа нарко" or text == " Вы положили в сейф нарко" then
        intim.usedrugs.kolvo = "???"
        inicfg.save(intim, 'EDITH\\'..serverip..'-'..playernick)
        if settings.usedrugs.txdtype == 1 then
          sampTextdrawCreate(617, "Drugs "..intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
          sampTextdrawSetStyle(617, settings.usedrugs.style1)
          if os.time() < intim.usedrugs.lasttime + settings.usedrugs.cooldown then
            sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 )
          else
            sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
          end
          sampTextdrawSetOutlineColor(617, 1, - 16777216)
        end
        if settings.usedrugs.txdtype == 2 then
          sampTextdrawCreate(617, intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
          sampTextdrawSetStyle(617, settings.usedrugs.style1)
          if os.time() < intim.usedrugs.lasttime + settings.usedrugs.cooldown then
            sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 )
          else
            sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
          end
          sampTextdrawSetOutlineColor(617, 1, - 16777216)
        end
      end
      --покупка с рук, кража, продажа на руки.
      if not string.find(text, " Вы купили ", 1, true) and not string.find(text, " грамм за ", 1, true) then trigger1 = true end
      if not string.find(text, " купил(а) у вас ", 1, true) and not string.find(text, " грамм ", 1, true) then trigger2 = true end
      if ((string.find(text, "(( Остаток:", 1, true)) and not string.find(text, "материалов", 1, true)) or string.find(text, "Вы украли 150 грамм наркотических лекарств", 1, true) or (string.find(text, " Вы купили ", 1, true) and not string.find(text, "У вас есть", 1, true) and string.find(text, " грамм за ", 1, true) and trigger1 == true) or (string.find(text, " купил(а) у вас ", 1, true) and string.find(text, " грамм ", 1, true) and trigger2 == true) then
        if string.match(text, "(%d+)") ~= nil or string.match(text, "(%d+)") then
          if string.find(text, " Вы купили ", 1, true) then intim.usedrugs.kolvo = intim.usedrugs.kolvo + string.match(text, "(%d+)") trigger1 = false
          elseif string.match(text, "(%d+)") ~= intim.usedrugs.kolvo and not string.find(text, " купил(а) у вас ", 1, true) then intim.usedrugs.kolvo = string.match(text, "(%d+)") end
          if string.find(text, " купил(а) у вас ", 1, true) and string.find(text, " грамм ", 1, true) then intim.usedrugs.kolvo = intim.usedrugs.kolvo - string.match(text, "(%d+)") trigger2 = false end
          inicfg.save(intim, 'EDITH\\'..serverip..'-'..playernick)
          if settings.usedrugs.txdtype == 1 then
            sampTextdrawCreate(617, "Drugs "..intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
            sampTextdrawSetStyle(617, settings.usedrugs.style1)
            if os.time() < intim.usedrugs.lasttime + settings.usedrugs.cooldown then
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 )
            else
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
            end
            sampTextdrawSetOutlineColor(617, 1, - 16777216)
          end
          if settings.usedrugs.txdtype == 2 then
            sampTextdrawCreate(617, intim.usedrugs.kolvo, settings.usedrugs.posX1, settings.usedrugs.posY1)
            sampTextdrawSetStyle(617, settings.usedrugs.style1)
            if os.time() < intim.usedrugs.lasttime + settings.usedrugs.cooldown then
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 65536 )
            else
              sampTextdrawSetLetterSizeAndColor(617, settings.usedrugs.size1, settings.usedrugs.size2, - 13447886)
            end
            sampTextdrawSetOutlineColor(617, 1, - 16777216)
          end
        end


      end
    end
    if string.find(text, "ачало через 15 минут") then
      if not wasafk then
        lua_thread.create(function() waitforcapture = true sendtype = 25 end)
      end
      if offline and not wasafk then
        timeleft_type = 25
        timeleft_base = os.time()
      end
    end
    if string.find(text, "ойна началась") then
      if not wasafk then
        lua_thread.create(function() waitforcapture = true sendtype = 10 end)
      end
      if offline and not wasafk then
        timeleft_type = 10
        timeleft_base = os.time()
      end
    end
    if string.find(text, "обедитель не определ") then
      if not wasafk then
        lua_thread.create(function() waitforcapture = true sendtype = 2 end)
      end
      if offline and not wasafk then
        timeleft_type = 2
        timeleft_base = os.time()
      end
    end
    if string.find(text, "аш клуб выиграл") then
      if not wasafk then
        lua_thread.create(function() waitforcapture = true sendtype = 0 end)
      end
      if offline and not wasafk then
        timeleft_type = 0
        timeleft_base = os.time()
      end
    end
    if string.find(text, "аш клуб проиграл") then
      if not wasafk then
        lua_thread.create(function() waitforcapture = true sendtype = 0 end)
      end
      if offline and not wasafk then
        timeleft_type = 0
        timeleft_base = os.time()
      end
    end
    --
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
end

function sampev.onSendGiveDamage(playerID, damage, weaponID, bodypart)
  if sampIsPlayerConnected(playerID) then
    result, handle2 = sampGetCharHandleBySampPlayerId(playerID)
    if result then
      health = sampGetPlayerHealth(playerID)
      if health < damage or health == 0 then
        kills = kills + 1
        k_kills = k_kills + 1
        settings.stats.kills = settings.stats.kills + 1
        inicfg.save(settings, "edith")
      end
    end
    k_given = k_given + damage
    given = given + damage
    settings.stats.dmg = settings.stats.dmg + damage
    inicfg.save(settings, "edith")
  end
end

function sampev.onSendTakeDamage(playerID, damage, weaponID, bodypart)
  if sampIsPlayerConnected(playerID) then
    killer = sampGetPlayerNickname(playerID)
    killer_id = playerID
    killer_w = weaponID
    killer_b = bodypart
  end
end
--------------------------------------------------------------------------------
-------------------------------------HEIST--------------------------------------
--------------------------------------------------------------------------------
function heist_beep()
  font_beep = renderCreateFont("Impact", 15, 4)
  local resX1, resY1 = getScreenResolution()
  while true do
    wait(0)
    if settings.heist.enable and heist_t == true then
      renderFontDrawText(font_beep, string.format("Груз: %.3f", (heist_timestamp - os.clock()) * - 1), resX1 / 2 - 100, resY1 / 2, 0xFF00FF00)
      if os.clock() >= heist_timestamp + 5.15 then
        if settings.heist.sound then
          addOneOffSound(0.0, 0.0, 0.0, 1138)
        end
        heist_t = false
      end
    end
  end
end
function sampev.onSendPickedUpPickup(id)
  if settings.heist.enable then
    if id == 1978 then
      heist_timestamp = os.clock()
      heist_t = true
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

function showlog()
  sampShowDialog(222228, "{ff0000}Информация об обновлении", "{ff0000}"..thisScript().name.." beta-3.7 2019.08.29{ffffff}\n* Фикс зависания на слабых пк если выключить capturetimer.\n* Добавлена возможность скрывать транспорт. Может помочь при просадках фпс.\n* Выбор фуры клуба в меню навигации.\n* Настройка хоткеев радара.\n* Файл настроек переименован score.ini -> edith.ini. Должен автоматом переименоваться.", "Открыть", "Отменить")
end

function openchangelog(komanda, url)
  sampRegisterChatCommand(komanda,
    function()
      lua_thread.create(
        function()
          if changelogurl == nil then
            changelogurl = url
          end
          showlog()
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
