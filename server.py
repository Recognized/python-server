import os
import http.server
import socketserver

PORT = 38917
ERROR_CODE = os.environ.get("ERROR_CODE")


class ErrorHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        if ERROR_CODE:
            code = int(ERROR_CODE)
            self.send_error(code, f"Forced error {code}")
        else:
            super().do_GET()

    def do_POST(self):
        if ERROR_CODE:
            code = int(ERROR_CODE)
            self.send_error(code, f"Forced error {code}")
        else:
            self.send_error(501, "Not Implemented")


socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("0.0.0.0", PORT), ErrorHandler) as httpd:
    print(f"Serving on port {PORT}")
    if ERROR_CODE:
        print(f"ERROR_CODE={ERROR_CODE} — all requests will return HTTP {ERROR_CODE}")
    httpd.serve_forever()
