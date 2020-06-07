from http.server import BaseHTTPRequestHandler, HTTPServer 
from sage.all import *
import socketserver
import auxmath
from shamir import Shamir
from hashlib import md5
import pickle
import socket
import requests
import base64

class DC_():
	shares = []

	def send_req(self, command, payload=''):
		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
			sock.connect((HOST, PORT))
			command = command + ' '*(8-len(command))
			sock.sendall(bytes(command + payload, "utf-8"))
			data = sock.recv(64000)
		return data

	def make_request(data='', action=''):
		r = requests.post('http://localhost:8080', headers={'Action' : action})
		return r.content

	def get_info(self):
		response = self.make_request('get_info')
		self.t, self.n, self.q, self.p, self.h0, self.connected_users = pickle.loads(response)

	def gen_threshold_sign(self, h, m, s, shares):
		shaTSS = Shamir(self.t, self.n)
		k = shaTSS.SC(self.p, shares).list()[0]
		kk = bin(int(str(k)))[2:]
		R = m.parent()
		f_len = int(kk[:8], 2)
		fs_len = int(kk[8:16], 2)
		
		R = m.parent()
		f  = R([-1*int(x) for x in kk[16:16+f_len]])
		fs = R([-1*int(x) for x in kk[16+f_len:16+f_len+fs_len]])

		x = auxmath.normilize_coeffs(-(1/self.q)*m*fs)
		y = auxmath.normilize_coeffs(-(1/self.q)*m*f)
		s0 = x*f + y*fs
		s_res = R(s + s0)

		b = s_res * auxmath.normilize_coeffs2(s_res*self.h0 - m, self.q)

		print (b)
		print (b.norm(2))


	def add_shares(self, data):
		if len(self.shares) == self.t:
			return
		self.shares.append(pickle.loads(data))

	def __init__(self):
		self.get_info()

DC = DC_()

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
			print (content_length)

			encoded = base64.b64decode(post_data)
			data = pickle.loads(encoded)
			h, m, s, shares = data[0], data[1], data[2], data[3:]
			DC.gen_threshold_sign(h, m, s, shares)
			self.send(b'add_shares')
	
		elif action == 'add_shares':
			print ('add_shares')
			self.send(b'add_shares')
			#DC.add_shares(data)

host = 'localhost'
port = 8081
HTTPServer((host, port), HandleRequests).serve_forever()