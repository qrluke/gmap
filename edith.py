from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
from io import BytesIO

nicks = {}
granted = ["James_Bond", "Vittore_Deltoro", "James_Bond665", "Mauricio_Cedra"]
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
        if info[0]["sender"] not in nicks:
            nicks.update({info[0]["sender"]:{'timestamp':time.time(), 'heading': info[0]["heading"], 'health': info[0]["health"], 'x':info[0]["pos"]["x"], 'y':info[0]["pos"]["y"],'z':info[0]["pos"]["z"]}})
            print(nicks)
        else:
            print(nicks[info[0]["sender"]]["timestamp"])
            if nicks[info[0]["sender"]]["timestamp"] < time.time():
                nicks.update({info[0]["sender"]:{'timestamp':time.time(), 'heading': info[0]["heading"], 'health': info[0]["health"], 'x':info[0]["pos"]["x"], 'y':info[0]["pos"]["y"],'z':info[0]["pos"]["z"]}})
                print(nicks)

        response.write(str.encode(json.dumps(nicks)))
        self.wfile.write(response.getvalue())

def dict_to_binary(the_dict):
    str = (the_dict)
    binary = ' '.join(format(ord(letter), 'b') for letter in str)
    return binary

httpd = HTTPServer(('localhost', 1488), SimpleHTTPRequestHandler)
httpd.serve_forever()
