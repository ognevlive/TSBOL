from http.server import BaseHTTPRequestHandler, HTTPServer 
from sage.all import *
import socketserver
from hashlib import md5
import pickle
import socket
import requests
import base64

sys.path.insert(1, 'math')
import dc
DC = dc.DC_()

class HandleRequests(BaseHTTPRequestHandler):
	def _set_headers(self):
		self.send_response(200)
		self.send_header('Content-type', 'text/html')
		self.end_headers()

	def send(self, data):
		self._set_headers()
		self.wfile.write(data)

	def do_POST(self):
		action = self.headers['Action']
	
		if action == 'generate':
			print ('generate')
			content_length = int(self.headers['Content-Length'])
			post_data = self.rfile.read(content_length)
			encoded = base64.b64decode(post_data)
			data = pickle.loads(encoded)
			h, m, s, shares = data[0], data[1], data[2], data[3:]
			b = DC.gen_threshold_sign(h, m, s, shares)
			self.send(pickle.dumps(b))
	
		elif action == 'add_shares':
			print ('add_shares')
			self.send(b'add_shares')
			#DC.add_shares(data)

host = 'localhost'
port = 8081
HTTPServer((host, port), HandleRequests).serve_forever()