"""Isolated, fictional upstream responses."""

import json
import os
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        self.respond()

    def do_POST(self):
        self.respond()

    def respond(self):
        if self.path.startswith("/slow"):
            time.sleep(13)
        status = (
            int(self.path.split("/")[2].split("?")[0]) if self.path.startswith("/status/") else 200
        )
        body = json.dumps(
            {
                "path": self.path,
                "method": self.command,
                "headers": dict(self.headers),
                "body": self.rfile.read(int(self.headers.get("Content-Length", "0"))).decode(),
                "generation": os.environ.get("GENERATION", "first"),
            }
        ).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header(
            "Set-Cookie", "fixture=not-a-secret; Path=/; HttpOnly; Secure; SameSite=Strict"
        )
        self.end_headers()
        try:
            self.wfile.write(body)
        except BrokenPipeError:
            pass


class IPv6Server(ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        super().server_bind()


v6 = os.environ.get("IPV6_ONLY") == "true"
server = IPv6Server if v6 else ThreadingHTTPServer
server(
    ("::" if v6 else "0.0.0.0", int(os.environ.get("STUB_PORT", "8000"))), Handler
).serve_forever()
