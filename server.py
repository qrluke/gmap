#!/usr/bin/env python3
import sys
from sanic import Sanic
from sanic.response import json
from sanic_limiter import Limiter
from sanic.response import text
from sanic.exceptions import NotFound
from datetime import datetime
import json as js
import time
import urllib.parse

try:
    sys.argv[1]
    int(sys.argv[1])
except IndexError:
    print("usage: python3 server3.py [DELAY (MS)]")
    sys.exit(0)

DELAY = int(sys.argv[1])

data = {}


def get_remote_address(request):
    return request.ip


app = Sanic()
limiter = Limiter(app, global_limits=['1 per hour', '10 per day'], key_func=get_remote_address)

last_clear = 0

@limiter.limit("5000/minute")
@app.exception(NotFound)
async def test(request, exception):
    global last_clear
    start = time.time()

    info = js.loads(urllib.parse.unquote(request.path).replace("/", ""))
    ip = info["info"]["server"]
    room = info["info"]["room"]

    if ip not in data:
        data[ip] = {}
    if room not in data[ip]:
        data[ip][room] = {}
        data[ip][room]["players"] = {}

    if time.time() - last_clear > 300:
        last_clear = time.time()
        print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S || ')}[{ip}]: Запускаю очистку")
        for check_room in data[ip]:
            del_list = []
            for k, v in data[ip][check_room]["players"].items():
                if int(time.time()) - v["timestamp"] > 300:
                    del_list.append(k)
                    print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S || ')}[{ip} | {check_room}]: {k} будет удалён.")
            for item in del_list:
                del data[ip][check_room][item]
                print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S || ')}[{ip} | {check_room}]: Игрок {k} удален")

    if "sender" in info["data"]:
        data[ip][room]["players"].update({info["data"]['sender']['sender']: {
            'timestamp': time.time(),
            'heading': info["data"]['sender']['heading'],
            'health': info["data"]['sender']['health'],
            'x': info["data"]['sender']['pos']['x'],
            'y': info["data"]['sender']['pos']['y'],
            'z': info["data"]['sender']['pos']['z'],
        }})

    answer = {}

    answer["timestamp"] = time.time()
    answer["active"] = len(data[ip][room]["players"])
    answer["delay"] = DELAY

    if info["data"]['request'] == 1:
        answer["nicks"] = data[ip][room]["players"]

    if "sender" in info["data"]:
        print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f || ')}[{ip} | {room}]: Подготовлен ответ для {info['data']['sender']['sender']}. Обработка заняла: {(time.time() - start):.6f} с")
    else:
        print(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f || ')}[{ip} | {room}]: Отправлена информация о комнате. Обработка заняла: {(time.time() - start):.6f} с")

    return json(answer)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=40001, access_log = True)
