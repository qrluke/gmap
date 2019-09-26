#!/usr/bin/python
# -*- coding: utf-8 -*-
from websocket_server import WebsocketServer
import json
import time
import io
nicks = {}
vehicles = {}
capture = {}


# Called for every client connecting (after handshake)

def new_client(client, server):
    print('Client connected')


# Called for every client disconnecting

def client_left(client, server):
    print('Client(%d) disconnected' % client['id'])


# Called when a client sends a message

def message_received(client, server, message):
    info = json.loads(message)
    if 'auth' in info:
        with io.open('whitelist.txt') as file:
            for line in file:
                if info['auth'] in line:
                    server.send_message(client, 'Granted!')
                    return
        server.send_message(client, 'Go away!')
    else:
        if 'sender' in info:
            if info['sender']['sender'] not in nicks:
                nicks.update({info['sender']['sender']: {
                    'timestamp': time.time(),
                    'heading': info['sender']['heading'],
                    'health': info['sender']['health'],
                    'x': info['sender']['pos']['x'],
                    'y': info['sender']['pos']['y'],
                    'z': info['sender']['pos']['z'],
                    }})
            else:
                if nicks[info['sender']['sender']]['timestamp'] \
                    < time.time():
                    nicks.update({info['sender']['sender']: {
                        'timestamp': time.time(),
                        'heading': info['sender']['heading'],
                        'health': info['sender']['health'],
                        'x': info['sender']['pos']['x'],
                        'y': info['sender']['pos']['y'],
                        'z': info['sender']['pos']['z'],
                        }})
        if 'vehicles' in info:
            inf = info['vehicles']
            for a in inf:
                if a and a['id'] not in vehicles:
                    if 'health' in a:
                        vehicles.update({a['id']: {
                            'timestamp': time.time(),
                            'heading': a['heading'],
                            'engine': a['engine'],
                            'health': a['health'],
                            'healthstamp': time.time(),
                            'x': a['pos']['x'],
                            'y': a['pos']['y'],
                            'z': a['pos']['z'],
                            }})
                    else:
                        vehicles.update({a['id']: {
                            'timestamp': time.time(),
                            'heading': a['heading'],
                            'engine': a['engine'],
                            'x': a['pos']['x'],
                            'health': 'xz',
                            'healthstamp': time.time(),
                            'y': a['pos']['y'],
                            'z': a['pos']['z'],
                            }})
                else:
                    if vehicles[a['id']]['timestamp'] < time.time():
                        if 'health' in a:
                            vehicles.update({a['id']: {
                                'timestamp': time.time(),
                                'heading': a['heading'],
                                'engine': a['engine'],
                                'health': a['health'],
                                'healthstamp': time.time(),
                                'x': a['pos']['x'],
                                'y': a['pos']['y'],
                                'z': a['pos']['z'],
                                }})
                        else:
                            vehicles.update({a['id']: {
                                'timestamp': time.time(),
                                'heading': a['heading'],
                                'engine': a['engine'],
                                'health': vehicles[a['id']]['health'],
                                'healthstamp': vehicles[a['id'
                                        ]]['healthstamp'],
                                'x': a['pos']['x'],
                                'y': a['pos']['y'],
                                'z': a['pos']['z'],
                                }})
        answer = {}
        answer['nicks'] = nicks
        answer['vehicles'] = vehicles
        answer['timestamp'] = time.time()
        server.send_message(client, str.encode(json.dumps(answer)))
        print ('Client(%d) said: %s' % (client['id'], message))


PORT = 9128
server = WebsocketServer(PORT, '0.0.0.0')
server.set_fn_new_client(new_client)
server.set_fn_client_left(client_left)
server.set_fn_message_received(message_received)
server.run_forever()
