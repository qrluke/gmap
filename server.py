from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
from io import BytesIO

nicks = {}
vehicles = {}
capture = {}
granted = ["James_Bond", "Luis_Kovalev", "Angelo_Mancini", "Knoerty_Ceonich", "Korzus_Xentrix", "Dominic_Chambers", "Hercule_Puaro", "Cecilio_Benavides","Dell_Fill", "Anthony_Salerno","Dean_Crow","Vittore_Deltoro", "James_Bond665", "Mauricio_Cedra", "Fernando_Guardado"]
class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)
        if body.decode("utf-8") in granted:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'Granted!')
        else:
            self.send_response(423)

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)
        self.send_response(200)
        self.end_headers()
        response = BytesIO()
        print(body.decode("utf-8"))
        info = json.loads(body.decode("utf-8"))

        if "sender" in info:
            if info["sender"]["sender"] not in nicks:
                nicks.update({info["sender"]["sender"]:{'timestamp':time.time(), 'heading': info["sender"]["heading"], 'health': info["sender"]["health"], 'x':info["sender"]["pos"]["x"], 'y':info["sender"]["pos"]["y"],'z':info["sender"]["pos"]["z"]}})
            else:
                if nicks[info["sender"]["sender"]]["timestamp"] < time.time():
                    nicks.update({info["sender"]["sender"]:{'timestamp':time.time(), 'heading': info["sender"]["heading"], 'health': info["sender"]["health"], 'x':info["sender"]["pos"]["x"], 'y':info["sender"]["pos"]["y"],'z':info["sender"]["pos"]["z"]}})
                    #print(nicks)
        if "vehicles" in info:
            inf = info["vehicles"]
            for a in inf:
                if a and a["id"] not in vehicles:
    
                    if "health" in a:
                        vehicles.update({a["id"]:{'timestamp':time.time(), 'heading': a["heading"], 'engine': a["engine"], 'health': a["health"], 'healthstamp': time.time(), 'x':a["pos"]["x"], 'y':a["pos"]["y"],'z':a["pos"]["z"]}})
                    else:
                        vehicles.update({a["id"]:{'timestamp':time.time(), 'heading': a["heading"], 'engine': a["engine"], 'x':a["pos"]["x"], 'health': "xz", 'healthstamp': time.time(), 'y':a["pos"]["y"],'z':a["pos"]["z"]}})
                else:
                    if vehicles[a["id"]]["timestamp"] < time.time():
                        if "health" in a:
                            print("novoe")

                            vehicles.update({a["id"]:{'timestamp':time.time(), 'heading': a["heading"], 'engine': a["engine"],  'health': a["health"], 'healthstamp': time.time(), 'x':a["pos"]["x"], 'y':a["pos"]["y"],'z':a["pos"]["z"]}})
                        else:
                            print("staroe")
                            vehicles.update({a["id"]:{'timestamp':time.time(), 'heading': a["heading"], 'engine': a["engine"], 'health': vehicles[a["id"]]["health"],'healthstamp': vehicles[a["id"]]["healthstamp"], 'x':a["pos"]["x"], 'y':a["pos"]["y"],'z':a["pos"]["z"]}})
        if "timeleft_type" in info:
            if "time" not in capture:
                capture["time"] = time.time()
                capture["type"] = info["timeleft_type"]
            else:
                if capture["type"] == info["timeleft_type"]:
                    if capture["type"] == 25:
                        if time.time() - capture["time"] > 3600:
                            capture["time"] = time.time()
                    elif capture["type"] == 10:
                        if time.time() - capture["time"] > 3600:
                            capture["time"] = time.time()
                    elif capture["type"] == 2:
                        if time.time() - capture["time"] > 100:
                            capture["time"] = time.time()
                    elif capture["type"] == 0:
                        if time.time() - capture["time"] > 3600:
                            capture["time"] = time.time()
                else:
                    if time.time() - capture["time"] > 60:
                        capture["time"] = time.time()
                        capture["type"] = info["timeleft_type"]
        answer = {}
        answer["nicks"] = nicks
        answer["vehicles"] = vehicles
        answer["capture"] = capture
        answer["timestamp"] = time.time()
        response.write(str.encode(json.dumps(answer)))
        print(json.dumps(answer))
        self.wfile.write(response.getvalue())

def dict_to_binary(the_dict):
    str = (the_dict)
    binary = ' '.join(format(ord(letter), 'b') for letter in str)
    return binary

httpd = HTTPServer(('', 8999), SimpleHTTPRequestHandler)
httpd.serve_forever()
    
