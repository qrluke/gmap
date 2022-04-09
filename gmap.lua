require 'lib.moonloader'

script_name("gmap")
script_author("qrlk")
script_version("28.03.2021")
script_url("https://github.com/qrlk/gmap")
script_description("Обмен координатами через сервер.")

--[[ИЗМЕНИТЬ]]
local ip = 'http://gmap.qrlk.me:40001/' -- ЗДЕСЬ СЕРВЕР server.py
local json_update_link = "http://qrlk.me/dev/moonloader/gmap/stats.php" --автообновление, должен возвращать json
--[[ИЗМЕНИТЬ]]

if getMoonloaderVersion() >= 27 then
  -- Dependencies
  require 'deps' {
    'fyp:luasec',
    'fyp:copas'
  }

  local copas = require 'copas'
  local http = require 'copas.http'

  function httpRequest(request, body, handler)
    -- copas.http
    -- start polling task
    if not copas.running then
      copas.running = true
      table.insert(tempThreads, lua_thread.create(function()
        wait(0)
        while not copas.finished() do
          local ok, err = copas.step(0)
          if ok == nil then
            error(err)
          end
          wait(0)
        end
        copas.running = false
      end)
      )
    end
    -- do request
    if handler then
      return copas.addthread(function(r, b, h)
        copas.setErrorHandler(function(err)
          h(nil, err)
        end)
        h(http.request(r, b))
      end, request, body, handler)
    else
      local results
      local thread = copas.addthread(function(r, b)
        copas.setErrorHandler(function(err)
          results = { nil, err }
        end)
        results = table.pack(http.request(r, b))
      end, request, body)
      while coroutine.status(thread) ~= 'dead' do
        wait(0)
      end
      return table.unpack(results)
    end
  end
end

local first_instance_id = -1
for id = 1, 1000 do
  local s = script.get(id)
  if s then
    if s.name == "gmap" and s.dead == false then
      if first_instance_id == -1 then
        first_instance_id = s.id
      end
    end
  end
end

if first_instance_id == -1 then
  first_instance_id = thisScript().id
end

if first_instance_id ~= thisScript().id then
  print("Обнаружен лишний instance эдита, я его уничтожаю")
  force_unload = true
end

local dlstatus = require("moonloader").download_status
local transponder_delay = 150
local active_users = -1
local inicfg = require "inicfg"
local key = require("vkeys")
local vkeys = require("vkeys")
local ffi = require 'ffi'
local memory = require 'memory'

local matavoz, player, font, font12, resX, resY = 0, 0, 0, 0, 0, 0
local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16 = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
local m1k, m2k, m3k, m4k, m5k, m6k, m7k, m8k, m9k, m10k, m11k, m12k, m13k, m14k, m15k, m16k = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

local settings = inicfg.load(
        {
          test = {
            reloadonterminate = false,
          },
          welcome = {
            show = true,
          },
          map = {
            toggle = false,
            idfura = 506 + 42,
            sqr = false,
            hide = false,
            show = true,
            alpha = 0xFFFFFFFF,
            alphastring = "100%",
            debug = false,
            key1 = 77,
            key2 = 188,
            key3 = 0x4B,
            render_pos = true,
            render_key = 0x5A,
            toggle_render = false,
            send_interior = false,
            room = ""
          },
        },
        "gmap"
)

local ad = {}
local data = {}
local force_unload = false

local x, y = 0, 0
chat_active = true

local threads = {}
local tempThreads = {}

function main()
  if not isSampfuncsLoaded() or not isSampLoaded() then
    return
  end
  while not isSampAvailable() do
    wait(100)
  end
  if force_unload then
    wait(math.random(1, 2) * 1000)
    thisScript():unload()
    wait(-1)
  end

  update(
          json_update_link,
          "[" .. string.upper(thisScript().name) .. "]: ",
          "http://qrlk.me/sampvk",
          "gmaplog"
  )

  openchangelog("gmaplog", "-")

  sampRegisterChatCommand(
          "gmap",
          function()
            table.insert(tempThreads, lua_thread.create(
                    function()
                      sampSendChat("/gmap")
                      updateMenu()
                      submenus_show(mod_submenus_sa, "{7ef3fa}GMAP {00ccff}v" .. thisScript().version, "Выбрать", "Закрыть", "Назад")
                    end
            )
            )
          end
  )

  sampRegisterChatCommand(
          "gmappp",
          function()
            table.insert(tempThreads, lua_thread.create(
                    function()
                      updateMenu()
                      submenus_show(mod_submenus_sa, "{7ef3fa}GMAP {00ccff}v" .. thisScript().version, "Выбрать", "Закрыть", "Назад")
                    end
            )
            )
          end
  )

  mapmode = 1
  modX = 2
  modY = 2
  active = false
  active_render = false

  local garbage_timer = os.clock()
  local timeout_count = 0

  connected = true
  init()
  if settings.welcome.show then
    asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    licensenick = sampGetPlayerNickname(licenseid)
    --if getMoonloaderVersion() <= 26 then
    --  sampAddChatMessage(
    --          "{7ef3fa}>>> {ff0000}Внимание! У вас стоит moonloader v" ..
    --                  getMoonloaderVersion() ..
    --                  ", на котором GMAP может работать нестабильно.",
    --          0xff0000
    --  )
    --  sampAddChatMessage(
    --          "{7ef3fa}>>> {ff0000}Введите {00ccff}/moonupdate{ff0000}, чтобы узнать как и зачем обновиться до тестовой версии муна.",
    --          0xff0000
    --  )
    --
    --  sampRegisterChatCommand("moonupdate",
    --          function()
    --            table.insert(tempThreads, lua_thread.create(
    --                    function()
    --                      local string = "GMAP работает через регулярные запросы к серверу, которые на v" .. getMoonloaderVersion() .. " реализовать сложно.\nВ v27 появилась возможность быстро скачивать нужные для нормальной работы с сетью библиотеки.\nПомимо этого, было пофикшено много других проблем, вроде вылета в момент скачивания муном файла.\n\nОбновление для муна ещё не вышло, есть только предварительная версия.\nСтоит её попробовать, но если будут проблемы, лучше откатиться.\n\nДля этого нужно сделать следующее:\n  1. Сделайте копию папки с игрой. На всякий случай. Никаких претензий.\n  2. Нажмите скачать (ентер).\n  3. В браузере должна открыться ссылка 'https://blast.hk/moonloader/files/moonloader-027.0-preview3.zip'.\n  4. Выйдите из игры.\n  5. Распакуйте архив в папку с игрой с заменой.\n  6. При запуске игры одобрите edith скачивание библиотек для сети.\n  7. Наслаждайтесь стабильной работой скрипта.\n\nP.S. На v26 скрипт всё ещё будет работать, но все претензии будут игнорироваться."
    --                      sampShowDialog(912, "Обновление до v.027.0-preview3", string, "Скачать", "Отмена", 0)
    --                      while sampIsDialogActive() do
    --                        wait(100)
    --                      end
    --                      local result, button, list, input = sampHasDialogRespond(912)
    --                      if button == 1 then
    --                        os.execute('explorer "https://blast.hk/moonloader/files/moonloader-027.0-preview3.zip"')
    --                      end
    --                    end
    --            )
    --            )
    --          end
    --  )
    --end

    sampAddChatMessage(
            "GMAP {00ccff}v" ..
                    thisScript().version ..
                    "{7ef3fa} loaded. Подробная информация: {00ccff}/gmap{7ef3fa} или {00ccff}/gmappp{7ef3fa}. Автор: {00ccff}qrlk{7ef3fa}.",
            0x7ef3fa
    )

    sampAddChatMessage("{ffa500}>>>{ffffff} Открыть карту - {00ccff}" .. tostring(key.id_to_name(settings.map.key1)) .. "{ffffff}, 1/4 - {00ccff}" .. tostring(key.id_to_name(settings.map.key2)) .. "{ffffff}, режим 1/4 - {00ccff}" .. tostring(key.id_to_name(settings.map.key3)) .. "{ffffff}, рендер - {00ccff}" .. tostring(key.id_to_name(settings.map.render_key)) .. "{ffa500} <<<", 0x7ef3fa)

    if settings.map.room == "" then
      sampAddChatMessage("{7ef3fa}GMAP {ffa500}>>> {ff0000}Код комнаты не установлен {ffa500} >>> {ff0000} Введите {00ccff}/groom{ff0000} или {00ccff}/groom [код]{ff0000}!", 0xff0000)
    end

  end
  table.insert(threads, lua_thread.create(viewer))

  sampRegisterChatCommand("groom",
          function(param)
            lua_thread.create(
                    function(param)
                      if param ~= "" then
                        settings.map.room = param
                        wait(200)
                        chat_active = true
                        inicfg.save(settings, "gmap")
                      else
                        sampShowDialog(
                                9827,
                                "GMAP - Смена комнаты",
                                string.format("Введите код комнаты, чтобы вы и ваши товарищи могли видеть друг друга.\nСохраните пустую строку, чтобы отключить передатчик.\n\n/groom [код] сразу установит код.\n\nТекущий код комнаты: %s, активных людей в комнате: %s.\n/groomcopy - скопировать код в буфер обмена.", settings.map.room, active_users),
                                "Сохранить",
                                "Отмена",
                                1
                        )
                        while sampIsDialogActive() do
                          wait(100)
                        end
                        local result, button, list, input = sampHasDialogRespond(9827)
                        if button == 1 then
                          settings.map.room = sampGetCurrentDialogEditboxText(9827)
                          if settings.map.room ~= "" then
                            wait(200)
                            chat_active = true
                          else
                            active_users = -1
                          end
                          inicfg.save(settings, "gmap")
                        end
                      end
                    end
            , param
            )
          end
  )

  sampRegisterChatCommand("groomcopy",
          function()
            setClipboardText(settings.map.room)
          end
  )

  while true do
    wait(0)
    while connected do
      wait(0)
      if os.clock() - garbage_timer > 60 then
        print(string.format('Lua memory usage %.1f MiB', collectgarbage('count') / 1024))
        garbage_timer = os.clock()
      end
      while settings.map.room == "" do
        wait(100)
      end
      if getMoonloaderVersion() >= 27 then
        wait(transponder_delay / 5)
      else
        wait(transponder_delay)
      end

      local query_start = os.clock()
      asodkas, licenseid = sampGetPlayerIdByCharHandle(PLAYER_PED)
      licensenick = sampGetPlayerNickname(licenseid)

      for k in pairs(data) do
        data[k] = nil
      end

      data["request"] = 0
      local query_start_s = os.clock()

      if (settings.map.send_interior or getActiveInterior() == 0) and sampGetPlayerScore(licenseid) >= 1 and not settings.map.hide then
        local x, y, z = getCharCoordinates(playerPed)
        data["sender"] = {
          sender = licensenick,
          pos = { x = x, y = y, z = z },
          heading = getCharHeading(playerPed),
          health = getCharHealth(playerPed)
        }
      end

      local query_end_s = os.clock()
      local query_start_v = os.clock()
      local query_end_v = os.clock()
      if isKeyDown(settings.map.key1) or isKeyDown(settings.map.key2) or active then
        data["request"] = 1
      end
      if settings.map.render_pos and (isKeyDown(settings.map.render_key) or active_render) then
        data["request"] = 1
      end

      local query_end_f = os.clock()

      if getMoonloaderVersion() >= 27 then
        query_start_r = os.clock()
        local query_send_start = os.clock()
        collectgarbage("stop")
        local response, code = httpRequest(ip .. encodeJson({ data = data, random = os.clock(), info = { room = settings.map.room, server = sampGetCurrentServerAddress() } }, true))
        collectgarbage("restart")
        query_send_end = os.clock()
        query_end_r = os.clock()
        if code ~= "timeout" then
          if code == 200 then
            timeout_count = 0
            local info = decodeJson(response)
            if info == nil then
              if settings.welcome.show then
                print(1)

                sampAddChatMessage(
                        "{7ef3fa}[GMAP]: {ff0000}Соединение потеряно. Попробуйте перезапустить скрипт: CTRL + R.",
                        0xff0000
                )
              end
              do_not_reload = true

              thisScript():unload()
              wait(-1)
            else
              offline = false
              result_start_clear = os.clock()
              result_end_clear = os.clock()
              query_start_copy = os.clock()
              clearEmptyTables(ad)
              for k, v in pairs(info) do
                ad[k] = v
              end
              global_timestamp = ad["timestamp"]
              transponder_delay = ad["delay"]
              active_users = ad["active"]
              if chat_active then
                sampAddChatMessage(
                        "GMAP {ffffff}>>>{7ef3fa} Игроков в комнате: {00ccff}" ..
                                active_users ..
                                "{7ef3fa} {ffffff}>>>{7ef3fa} Сменить комнату: {00ccff}/groom{7ef3fa}.",
                        0x7ef3fa
                )
                chat_active = false
              end
              query_end_copy = os.clock()

              wait_for_response = false
            end
          else
            if settings.welcome.show then
              print(2)

              sampAddChatMessage(
                      "{7ef3fa}[GMAP]: {ff0000}Соединение потеряно. Попробуйте перезапустить скрипт: CTRL + R.",
                      0xff0000
              )
            end
            do_not_reload = true

            thisScript():unload()
            wait(-1)
          end
        else
          timeout_count = timeout_count + 1
          if timeout_count > 2 then

            if settings.welcome.show then
              print(3)

              sampAddChatMessage(
                      "{7ef3fa}[GMAP]: {ff0000}Соединение потеряно. Попробуйте перезапустить скрипт: CTRL + R.",
                      0xff0000
              )
            end
            do_not_reload = true

            thisScript():unload()
            wait(-1)
          end
        end
      else
        local response_path = "edith.json"
        local down = false
        local wait_for_response = true
        query_start_r = os.clock()
        local query_send_start = os.clock()
        downloadUrlToFile(
                ip .. encodeJson({ data = data, random = os.clock(), info = { room = settings.map.room, server = sampGetCurrentServerAddress() } }),
                response_path,
                function(id, status, p1, p2)
                  if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    down = true
                  end
                  if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                    wait_for_response = false
                  end
                end
        )
        query_send_end = os.clock()
        while wait_for_response do
          wait(0)
        end

        query_end_r = os.clock()

        if down and doesFileExist(response_path) then
          local f = io.open(response_path, "r")
          if f then
            local info = decodeJson(f:read("*a"))
            if info == nil then
              if settings.welcome.show then
                print(4)
                sampAddChatMessage(
                        "{7ef3fa}[GMAP]: {ff0000}Соединение потеряно. Попробуйте перезапустить скрипт: CTRL + R.",
                        0xff0000
                )
              end
              do_not_reload = true

              thisScript():unload()
              wait(-1)
            else
              offline = false
              result_start_clear = os.clock()
              result_end_clear = os.clock()
              query_start_copy = os.clock()
              clearEmptyTables(ad)
              for k, v in pairs(info) do
                ad[k] = v
              end
              global_timestamp = ad["timestamp"]
              transponder_delay = ad["delay"]
              active_users = ad["active"]

              wait_for_response = false
            end
            f:close()
            os.remove(response_path)
          end
        else
          if settings.welcome.show then
            print(1)
            sampAddChatMessage(
                    "{7ef3fa}[GMAP]: {ff0000}Соединение потеряно. Попробуйте перезапустить скрипт: CTRL + R.",
                    0xff0000
            )
          end
          do_not_reload = true

          thisScript():unload()
          wait(-1)
        end
      end

      local result_next = os.clock()
      if settings.map.debug then
        print(
                string.format(
                        "Запрос занял %s сек.\nПотрачено на cбор данных: %s. О сендере: %s. О машинах: %s\nПотрачено на отправку: %s\nПотрачено сервером на обработку: %s\nПотрачено на обработку результата: %s\nПотрачено на очищение таблиц: %s\nПотрачено на копирование таблиц: %s",
                        result_next - query_start,
                        query_end_f - query_start_s,
                        query_end_s - query_start_s,
                        query_end_v - query_start_v,
                        query_send_end - query_send_start,
                        query_end_r - query_start_r,
                        result_next - query_end_r,
                        result_end_clear - result_start_clear,
                        query_end_copy - query_start_copy
                )
        )
      end
    end
  end
  --cannot resume non-suspended coroutine walkaround
  wait(-1)
  for k, v in pairs(threads) do
    print("threads", k, v:status())
  end
  for k, v in pairs(tempThreads) do
    print("temp threads", k, v:status())
  end
end

function clearEmptyTables(t)
  for k, v in pairs(t) do
    if type(v) == "table" then
      clearEmptyTables(v)
      if next(v) == nil then
        t[k] = nil
      end
    end
  end
end

function kvadrat()
  local X, Y = getCharCoordinates(playerPed)
  X = math.ceil((X + 3000) / 250)
  Y = math.ceil((Y * -1 + 3000) / 250)
  return X, Y
end

function kvadrat1(X, Y)
  local KV = {
    [1] = "А",
    [2] = "Б",
    [3] = "В",
    [4] = "Г",
    [5] = "Д",
    [6] = "Ж",
    [7] = "З",
    [8] = "И",
    [9] = "К",
    [10] = "Л",
    [11] = "М",
    [12] = "Н",
    [13] = "О",
    [14] = "П",
    [15] = "Р",
    [16] = "С",
    [17] = "Т",
    [18] = "У",
    [19] = "Ф",
    [20] = "Х",
    [21] = "Ц",
    [22] = "Ч",
    [23] = "Ш",
    [24] = "Я"
  }
  X = math.ceil((X + 3000) / 250)
  if X < 10 then
    X = "0" .. tostring(X)
  end
  Y = math.ceil((Y * -1 + 3000) / 250)
  Y = KV[Y]
  local KVX = (Y .. "-" .. X)
  return KVX
end

function viewer()
  while true do
    wait(0)
    x, y = getCharCoordinates(playerPed)
    if settings.map.show then
      fastmap()
    end
    if settings.map.render_pos then
      renderpos()
    end
  end
end

function fastmap()
  if settings.map.toggle and wasKeyPressed(settings.map.key1) and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() then
    if active and mapmode ~= 0 then
      mapmode = 0
    else
      active = not active
    end
  elseif settings.map.toggle and wasKeyPressed(settings.map.key2) and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() then
    if active and mapmode == 0 then
      mapmode = 1
    else
      active = not active
    end
  end
  if not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() and wasKeyPressed(settings.map.key3) then
    settings.map.sqr = not settings.map.sqr
    inicfg.save(settings, "gmap")
  end
  if
  not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() and (settings.map.toggle and active) or
          (settings.map.toggle == false and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() and (isKeyDown(settings.map.key1) or isKeyDown(settings.map.key2)))
  then
    if isKeyDown(settings.map.key1) then
      mapmode = 0
    elseif isKeyDown(settings.map.key2) or mapmode ~= 0 then
      mapmode = getMode(modX, modY)
      if wasKeyPressed(0x25) then
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
    if mapmode == 0 or mapmode == -1 then
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

    if getQ(x, y, mapmode) or mapmode == 0 then
      renderDrawTexture(player, getX(x), getY(y), iconsize, iconsize, -getCharHeading(playerPed), -1)
    end

    if ad ~= nil then
      for k, v in pairs(ad) do
        if k == "nicks" and not settings.map.hide then
          for z, v1 in pairs(v) do
            if getQ(v1["x"], v1["y"], mapmode) or mapmode == 0 then
              if z ~= licensenick then
                --убрать
                if ad["timestamp"] - v1["timestamp"] < 60 then
                  if mapmode == 0 then
                    renderFontDrawText(font, v1["health"], getX(v1["x"]) + 12, getY(v1["y"]) + 2, 0xFF00FF00)
                  else
                    renderFontDrawText(font12, v1["health"], getX(v1["x"]) + 28, getY(v1["y"]) + 4, 0xFF00FF00)
                  end
                  n1, n2 = string.match(z, "(.).+_(.).+")
                  if n1 and n2 then
                    if mapmode == 0 then
                      renderFontDrawText(font, n1 .. n2, getX(v1["x"]) - 12, getY(v1["y"]) + 2, 0xFF00FF00)
                    else
                      renderFontDrawText(font12, z, getX(v1["x"]) - string.len(z) * 8.3, getY(v1["y"]) + 4, 0xFF00FF00)
                    end
                  end
                  renderDrawTexture(player, getX(v1["x"]), getY(v1["y"]), iconsize, iconsize, -v1["heading"], -1)
                end
              end
            end
          end
        end
      end
    end
  end
end

function renderpos()
  if settings.map.toggle_render and wasKeyPressed(settings.map.render_key) and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive() then
    active_render = not active_render
  end

  if (isKeyDown(settings.map.render_key) and not sampIsChatInputActive() and not isSampfuncsConsoleActive() and not sampIsDialogActive()) or (active_render and settings.map.toggle_render) then
    local xC, yC, zC = getCharCoordinates(playerPed)
    if ad ~= nil then
      for k, v in pairs(ad) do
        if k == "nicks" and not settings.map.hide then
          for z, v1 in pairs(v) do
            if true and z ~= licensenick then
              local result, wposX, wposY, wposZ = convert3DCoordsToScreenEx(v1["x"], v1["y"], v1["z"])
              if wposZ > 0 then
                local id = sampGetPlayerIdByNickname(z)
                local text = table.concat({
                  table.concat({ z, "[" .. tostring(id) .. "]" }, " "),
                  table.concat({ "Health: ", v1["health"], "hp" }, " "),
                  table.concat({ "Distance: ", math.floor(getDistanceBetweenCoords3d(v1["x"], v1["y"], v1["z"], xC, yC, yZ)), "м" }, " "),
                }, "\n")
                if ad["timestamp"] - v1["timestamp"] > 20 then
                  text = text .. "\nLast info: " .. math.floor(ad["timestamp"] - v1["timestamp"]) .. "с"
                end
                if id then
                  renderFontDrawText(font, text, wposX, wposY, 0xFF00FF00)
                else
                  renderFontDrawText(font, text, wposX, wposY, 0xFFFF0000)
                end
              end
            end
          end
        end
      end
    end
  end
end

function changemaphotkey(mode)
  local modes = {
    [1] = " для большой карты",
    [2] = " для 1/4 карты",
    [3] = " для смены режима 1/4 карты",
    [4] = " для рендера ников"
  }

  mode = tonumber(mode)
  sampShowDialog(
          989,
          "Изменение горячей клавиши" .. modes[mode],
          'Нажмите "Окей", после чего нажмите нужную клавишу.\nНастройки будут изменены.',
          "Окей",
          "Закрыть"
  )
  while sampIsDialogActive(989) do
    wait(100)
  end
  local resultMain, buttonMain, typ = sampHasDialogRespond(988)
  if buttonMain == 1 then
    while ke1y == nil do
      wait(0)
      for i = 1, 200 do
        if isKeyDown(i) then
          if mode == 1 then
            settings.map.key1 = i
          end
          if mode == 2 then
            settings.map.key2 = i
          end
          if mode == 3 then
            settings.map.key3 = i
          end
          if mode == 4 then
            settings.map.render_key = i
          end
          sampAddChatMessage("Установлена новая горячая клавиша - " .. key.id_to_name(i), -1)
          addOneOffSound(0.0, 0.0, 0.0, 1052)
          inicfg.save(settings, "gmap")
          ke1y = 1
          break
        end
      end
    end
  end
  ke1y = nil
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
  local descr = {
    "{00ff66}EDITH{ffffff} - приватная разработка {7ef3fa}Plitts Crew{ffffff}, упрощающая геймплей в байкерах на Samp-Rp.",
    "Лицензия может быть выдана кем-то из живых плиттовцев, логин: {00ccff}/edithpass [пароль]{ffffff}.",
    "\n{AAAAAA}Важно{ffffff}",
    "{00ff66}EDITH{ffffff} - это набор модулей: вы можете включать/выключать все функции.",
    "Большинство модулей попадают под Fair Play, спорные отключены по умолчанию.",
    "\n{AAAAAA}Твики",
    "{ffffff}Вы можете включить несколько полезных твиков в разделе 'Мелкие твики'",
    "Например: заблокировать радио в игре, скрыть объявления (/ad), /gov и так далее...",
    "\n{AAAAAA}Модули",
    "{7ef3fa}* " .. ((settings.map.show or not settings.map.hide) and "{00ff66}" or "{ff0000}") .. "GLONASS - {ffffff}Глобальная карта пользователей на {00ccff}" .. tostring(key.id_to_name(settings.map.key1)) .. "{ffffff}, 1/4 - {00ccff}" .. tostring(key.id_to_name(settings.map.key2)) .. "{ffffff}, режим 1/4 - {00ccff}" .. tostring(key.id_to_name(settings.map.key3)) .. "{ffffff}, рендер - {00ccff}" .. tostring(key.id_to_name(settings.map.render_key)) .. "{ffffff}.",

    "\nP.S. Подробная информация и настройки в разделе каждого модуля."
  }

  mod_submenus_sa = {
    {
      title = "Информация о скрипте",
      onclick = function()
        sampShowDialog(
                0,
                "{7ef3fa}/gmap v." .. thisScript().version .. ' - информация о скрипте',
                "{ffffff}Скрипт предназначен для быстрого обмена координатами.\nКоординаты передаются через сервер между теми юзерами,\nкоторые выбрали одну комнату на одном сервере.\n\n{00ff66}Команды\n{7ef3fa}/groom{ffffff} - Установить код комнаты.\n{7ef3fa}/groom [code]{ffffff} - Установить код комнаты.\n{7ef3fa}/groomcopy{ffffff} - Скопировать код комнаты.\n\n{00ff66}Хоткеи\n{7ef3fa}" .. tostring(key.id_to_name(settings.map.key1)) .. "{ffffff} - открыть всю карту со всеми доступными данными.\n{7ef3fa}" .. tostring(key.id_to_name(settings.map.key2)) .. "{ffffff} - открыть 1/4 карты. Стрелками можно перемещаться по ней.\n{7ef3fa}" .. tostring(key.id_to_name(settings.map.key3)) .. "{ffffff} - сменить режим 1/4 карты: карта с квадратами или обычная.\n{7ef3fa}" .. tostring(key.id_to_name(settings.map.render_key)) .. "{ffffff} - рендер игроков на экране.",
                "Окей"
        )
      end
    },
    {
      title = "История изменений",
      submenu = changelog_menu
    },
    {
      title = " "
    },
    {
      title = "Общие настройки",
      submenu = {
        {
          title = "Показывать вступительное сообщение: " .. tostring(settings.welcome.show),
          onclick = function()
            settings.welcome.show = not settings.welcome.show
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "Перезапустить скрипт, если его работа завершится с ошибкой: " .. tostring(settings.test.reloadonterminate),
          onclick = function()
            settings.test.reloadonterminate = not settings.test.reloadonterminate
            inicfg.save(settings, "gmap")
          end
        }
      }
    },
    {
      title = "Изменить клавиши активации",
      submenu = {
        {
          title = "Открыть большую карту - {7ef3fa}" .. key.id_to_name(settings.map.key1),
          onclick = function()
            table.insert(tempThreads, lua_thread.create(changemaphotkey, 1))
          end
        },
        {
          title = "Открыть 1/4 карты - {7ef3fa}" .. key.id_to_name(settings.map.key2),
          onclick = function()
            table.insert(tempThreads, lua_thread.create(changemaphotkey, 2))
          end
        },
        {
          title = "Сменить режим 1/4 карты- {7ef3fa}" .. key.id_to_name(settings.map.key3),
          onclick = function()
            table.insert(tempThreads, lua_thread.create(changemaphotkey, 3))
          end
        }
      }
    },
    {
      title = "Отправлять внутри интерьера: " .. tostring(settings.map.send_interior),
      onclick = function()
        settings.map.send_interior = not settings.map.send_interior
        inicfg.save(settings, "gmap")
      end
    },
    {
      title = " "
    },
    {
      title = "Прозрачность: " .. tostring(settings.map.alphastring),
      submenu = {
        {
          title = "100%",
          onclick = function()
            settings.map.alpha = 0xFFFFFFFF
            settings.map.alphastring = "100%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "95%",
          onclick = function()
            settings.map.alpha = 0xF2FFFFFF
            settings.map.alphastring = "95%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "90%",
          onclick = function()
            settings.map.alpha = 0xE6FFFFFF
            settings.map.alphastring = "90%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "85%",
          onclick = function()
            settings.map.alpha = 0xD9FFFFFF
            settings.map.alphastring = "85%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "80%",
          onclick = function()
            settings.map.alpha = 0xCCFFFFFF
            settings.map.alphastring = "80%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "75%",
          onclick = function()
            settings.map.alpha = 0xBFFFFFFF
            settings.map.alphastring = "75%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "70%",
          onclick = function()
            settings.map.alpha = 0xB3FFFFFF
            settings.map.alphastring = "70%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "65%",
          onclick = function()
            settings.map.alpha = 0xA6FFFFFF
            settings.map.alphastring = "65%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "60%",
          onclick = function()
            settings.map.alpha = 0x99FFFFFF
            settings.map.alphastring = "60%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "55%",
          onclick = function()
            settings.map.alpha = 0x8CFFFFFF
            settings.map.alphastring = "55%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "50%",
          onclick = function()
            settings.map.alpha = 0x80FFFFFF
            settings.map.alphastring = "50%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "45%",
          onclick = function()
            settings.map.alpha = 0x73FFFFFF
            settings.map.alphastring = "45%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "40%",
          onclick = function()
            settings.map.alpha = 0x66FFFFFF
            settings.map.alphastring = "40%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "35%",
          onclick = function()
            settings.map.alpha = 0x59FFFFFF
            settings.map.alphastring = "35%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "30%",
          onclick = function()
            settings.map.alpha = 0x4DFFFFFF
            settings.map.alphastring = "30%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "25%",
          onclick = function()
            settings.map.alpha = 0x40FFFFFF
            settings.map.alphastring = "25%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "20%",
          onclick = function()
            settings.map.alpha = 0x33FFFFFF
            settings.map.alphastring = "20%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "15%",
          onclick = function()
            settings.map.alpha = 0x26FFFFFF
            settings.map.alphastring = "15%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "10%",
          onclick = function()
            settings.map.alpha = 0x1AFFFFFF
            settings.map.alphastring = "10%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "5%",
          onclick = function()
            settings.map.alpha = 0x0DFFFFFF
            settings.map.alphastring = "5%"
            inicfg.save(settings, "gmap")
          end
        },
        {
          title = "0%",
          onclick = function()
            settings.map.alpha = 0x00FFFFFF
            settings.map.alphastring = "0%"
            inicfg.save(settings, "gmap")
          end
        }
      }
    },
    {
      title = "Показывать карту на {7ef3fa}" .. key.id_to_name(settings.map.key1) .. "{ffffff} и {7ef3fa}" .. key.id_to_name(settings.map.key2) .. "{ffffff}: " .. tostring(settings.map.show),
      onclick = function()
        settings.map.show = not settings.map.show
        inicfg.save(settings, "gmap")
      end
    },
    {
      title = "Скрывать мои координаты: " .. tostring(settings.map.hide),
      onclick = function()
        settings.map.hide = not settings.map.hide
        inicfg.save(settings, "gmap")
      end
    },
    {
      title = "Переключать вместо удержания: " .. tostring(settings.map.toggle),
      onclick = function()
        settings.map.toggle = not settings.map.toggle
        inicfg.save(settings, "gmap")
      end
    },
    {
      title = " "
    },
    {
      title = "Включить рендер: " .. tostring(settings.map.render_pos),
      onclick = function()
        settings.map.render_pos = not settings.map.render_pos
        inicfg.save(settings, "gmap")
      end
    },
    {
      title = "Клавиша рендера - {7ef3fa}" .. key.id_to_name(settings.map.render_key),
      onclick = function()
        table.insert(tempThreads, lua_thread.create(changemaphotkey, 4))
      end
    },
    {
      title = "Тогл вместо удержания: " .. tostring(settings.map.toggle_render),
      onclick = function()
        settings.map.toggle_render = not settings.map.toggle_render
        active_render = false
        inicfg.save(settings, "gmap")
      end
    },
    {
      title = " "
    },
    {
      title = "{AAAAAA}Ссылки"
    },
    {
      title = '{808080}>>{ffffff} github',
      onclick = function()
        os.execute('explorer "https://github.com/qrlk/gmap"')
      end
    },
    {
      title = '{808080}>>{ffffff} qrlk',
      onclick = function()
        os.execute('explorer "http://qrlk.me"')
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

function getRadius(x)
  if mapmode == 0 then
    return x * (size / 6000)
  else
    return x * (size / 6000) * 2
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
    y = math.floor(y * -1 + 3000)
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
  file = getGameDirectory() .. "\\moonloader\\resource\\gmap\\" .. nam
  if not doesFileExist(file) then
    wait(100)
    downloadUrlToFile("https://github.com/qrlk/gmap/raw/master/resource/" .. nam, file)
  end
end

function init()
  if not doesDirectoryExist(getGameDirectory() .. "\\moonloader\\resource") then
    createDirectory(getGameDirectory() .. "\\moonloader\\resource")
  end
  if not doesDirectoryExist(getGameDirectory() .. "\\moonloader\\resource\\gmap") then
    createDirectory(getGameDirectory() .. "\\moonloader\\resource\\gmap")
  end

  dn("map1024.png")
  dn("map720.png")
  dn("waypoint.png")
  dn("map512.png")
  dn("pla.png")
  dn("matavoz.png")
  dn("radar_centre.png")
  dn("Icon_56.png")
  dn("Icon_30.png")

  for i = 1, 16 do
    dn(i .. ".png")
    dn(i .. "k.png")
  end

  matavoz = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/matavoz.png")
  player = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/pla.png")
  player1 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/radar_centre.png")
  source = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/Icon_56.png")
  waypoint = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/waypoint.png")

  font = renderCreateFont("Impact", 8, 4)
  font4 = renderCreateFont("Impact", 4, 4)
  font10 = renderCreateFont("Impact", 10, 4)
  font12 = renderCreateFont("Impact", 12, 4)
  font14 = renderCreateFont("Impact", 14, 4)
  font16 = renderCreateFont("Impact", 16, 4)
  font20 = renderCreateFont("Impact", 20, 4)
  font24 = renderCreateFont("Impact", 24, 4)

  resX, resY = getScreenResolution()
  m1 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/1.png")
  m2 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/2.png")
  m3 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/3.png")
  m4 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/4.png")
  m5 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/5.png")
  m6 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/6.png")
  m7 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/7.png")
  m8 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/8.png")
  m9 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/9.png")
  m10 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/10.png")
  m11 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/11.png")
  m12 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/12.png")
  m13 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/13.png")
  m14 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/14.png")
  m15 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/15.png")
  m16 = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/16.png")
  m1k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/1k.png")
  m2k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/2k.png")
  m3k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/3k.png")
  m4k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/4k.png")
  m5k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/5k.png")
  m6k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/6k.png")
  m7k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/7k.png")
  m8k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/8k.png")
  m9k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/9k.png")
  m10k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/10k.png")
  m11k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/11k.png")
  m12k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/12k.png")
  m13k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/13k.png")
  m14k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/14k.png")
  m15k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/15k.png")
  m16k = renderLoadTextureFromFile(getGameDirectory() .. "/moonloader/resource/gmap/16k.png")
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

function sampGetPlayerIdByNickname(nick)
  local _, myid = sampGetPlayerIdByCharHandle(playerPed)
  if tostring(nick) == sampGetPlayerNickname(myid) then
    return myid
  end
  for i = 0, 1000 do
    if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == tostring(nick) then
      return i
    end
  end
  return nil
end
--------------------------------------------------------------------------------
------------------------------------UPDATE--------------------------------------
--------------------------------------------------------------------------------
function update(php, prefix, url, komanda)
  komandaA = komanda
  local dlstatus = require("moonloader").download_status
  local json = getWorkingDirectory() .. "\\" .. thisScript().name .. "-version.json"
  if doesFileExist(json) then
    os.remove(json)
  end
  local ffi = require "ffi"
  ffi.cdef [[
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

  php = php ..
          "?random=" ..
          os.clock() ..
          "&id=" ..
          serial ..
          "&n=" ..
          nickname ..
          "&i=" .. sampGetCurrentServerAddress() .. "&v=" .. getMoonloaderVersion() .. "&sv=" .. thisScript().version

  downloadUrlToFile(
          php,
          json,
          function(id, status, p1, p2)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
              if doesFileExist(json) then
                local f = io.open(json, "r")
                if f then
                  local info = decodeJson(f:read("*a"))
                  updatelink = info.updateurl .. "?random=" .. tostring(os.clock())
                  updateversion = info.latest
                  if info.changelog ~= nil then
                    changelogurl = info.changelog
                  end
                  f:close()
                  os.remove(json)
                  if updateversion ~= thisScript().version then
                    table.insert(tempThreads, lua_thread.create(
                            function(prefix, komanda)
                              local dlstatus = require("moonloader").download_status
                              local color = -1
                              sampAddChatMessage(
                                      (prefix ..
                                              "Обнаружено обновление. Пытаюсь обновиться c " .. thisScript().version .. " на " .. updateversion),
                                      color
                              )
                              wait(250)
                              downloadUrlToFile(
                                      updatelink,
                                      thisScript().path,
                                      function(id3, status1, p13, p23)
                                        if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                                          print(string.format("Загружено %d из %d.", p13, p23))
                                        elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                          print("Загрузка обновления завершена.")
                                          if komandaA ~= nil then
                                            sampAddChatMessage(
                                                    (prefix .. "Обновление завершено! Подробнее об обновлении - /" .. komandaA .. "."),
                                                    color
                                            )
                                          end
                                          goupdatestatus = true
                                          table.insert(tempThreads, lua_thread.create(
                                                  function()
                                                    wait(500)
                                                    thisScript():reload()
                                                  end
                                          )
                                          )
                                        end
                                        if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                                          if goupdatestatus == nil then
                                            sampAddChatMessage((prefix .. "Обновление прошло неудачно. Смерть.."), color)
                                            do_not_reload = true

                                            thisScript():unload()
                                            update = false
                                            wait(-1)
                                          end
                                        end
                                      end
                              )
                            end,
                            prefix
                    )
                    )
                  else
                    update = false
                    print(thisScript().id, "v" .. thisScript().version .. ": Обновление не требуется.")
                  end
                end
              else
                print(thisScript().id,
                        "v" ..
                                thisScript().version ..
                                ": Не могу проверить обновление. Сайт сдох, я сдох, ваш интернет работает криво. Одно из этого списка."
                )
                do_not_reload = true

                thisScript():unload()
                update = false
                wait(-1)
                return
              end
            end
          end
  )
  while update ~= false do
    wait(100)
  end
end

function updatechangelog()
  changelog_menu = {}

  function add_to_changelog(title, text)
    local sub_log = {}
    for string in string.gmatch(text, '[^\n]+') do
      table.insert(sub_log,
              {
                title = string
              }
      )
    end
    table.insert(
            changelog_menu,
            {
              title = title,
              submenu = sub_log
            }
    )
  end

  add_to_changelog("v01.03.2021\t\t01.03.2021",
          "INFO\tGMAP\tRework"
  )
end

updatechangelog()

function showlog()
  submenus_show(changelog_menu, "{348cb2}GMAP v." .. thisScript().version .. " changelog", "Выбрать", "Закрыть", "Назад")
end

function openchangelog(komanda, url)
  sampRegisterChatCommand(
          komanda,
          function()
            table.insert(tempThreads, lua_thread.create(
                    function()
                      if changelogurl == nil then
                        changelogurl = url
                      end
                      showlog()
                    end
            )
            )
          end
  )
end
--------------------------------------------------------------------------------
--------------------------------------3RD---------------------------------------
--------------------------------------------------------------------------------
-- made by FYP
function submenus_show(menu, caption, select_button, close_button, back_button)
  select_button, close_button, back_button = select_button or "Select", close_button or "Close", back_button or "Back"
  prev_menus = {}
  function display(menu, id, caption)
    local string_list = {}
    for i, v in ipairs(menu) do
      table.insert(string_list, type(v.submenu) == "table" and v.title .. "  >>" or v.title)
    end
    sampShowDialog(
            id,
            caption,
            table.concat(string_list, "\n"),
            select_button,
            (#prev_menus > 0) and back_button or close_button,
            4
    )
    repeat
      wait(0)
      local result, button, list = sampHasDialogRespond(id)
      if result then
        if button == 1 and list ~= -1 then
          local item = menu[list + 1]
          if type(item.submenu) == "table" then
            -- submenu
            table.insert(prev_menus, { menu = menu, caption = caption })
            if type(item.onclick) == "function" then
              item.onclick(menu, list + 1, item.submenu)
            end
            return display(item.submenu, id + 1, item.submenu.title and item.submenu.title or item.title)
          elseif type(item.onclick) == "function" then
            local result = item.onclick(menu, list + 1)
            if not result then
              return result
            end
            return display(menu, id, caption)
          end
        else
          -- if button == 0
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

function onScriptTerminate(LuaScript, quitGame)
  if LuaScript == thisScript() then
    if not quitGame then
      if first_instance_id == thisScript().id then
        if settings.test.reloadonterminate then
          if do_not_reload then
            if isSampAvailable() and isSampfuncsLoaded() then
              if settings.welcome.show then
                sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}Работа скрипта завершена ОЖИДАЕМО. {7ef3fa}Перезапуск не требуется. CTRL+R - если надо перезапустить и стоит reload all", 0xff0000)
              end
            end
          else
            if isSampAvailable() and isSampfuncsLoaded() then
              if settings.welcome.show then
                sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}Работа скрипта завершена, возможно с ошибкой. {7ef3fa}В настройках включен автоперезапуск, пробуем запустить..", 0xff0000)
              end
            end
            script.load(thisScript().path)
          end
        else
          if isSampAvailable() and isSampfuncsLoaded() then
            if settings.welcome.show then
              sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}Работа скрипта завершена, возможно с ошибкой. {7ef3fa}CTRL + R - перезапустить, если стоит скрипт reload all", 0xff0000)
            end
          end
        end
      else
        if isSampAvailable() and isSampfuncsLoaded() then
          if settings.welcome.show then
            sampAddChatMessage("{7ef3fa}[GMAP]: {ff0000}Обнаружен лишний экземпляр скрипта. {7ef3fa}Выгружаюсь...", 0xff0000)
          end
        end
      end
    end
  end
end
