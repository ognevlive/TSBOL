

# This file was *autogenerated* from the file math/dc.sage
from sage.all_cmdline import *   # import sage library

_sage_const_8 = Integer(8); _sage_const_64000 = Integer(64000); _sage_const_0 = Integer(0); _sage_const_2 = Integer(2); _sage_const_16 = Integer(16); _sage_const_1 = Integer(1); _sage_const_200 = Integer(200); _sage_const_3 = Integer(3); _sage_const_8081 = Integer(8081)
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
			command = command + ' '*(_sage_const_8 -len(command))
			sock.sendall(bytes(command + payload, "utf-8"))
			data = sock.recv(_sage_const_64000 )
		return data

	def make_request(data='', action=''):
		r = requests.post('http://localhost:8080', headers={'Action' : action})
		return r.content

	def get_info(self):
		response = self.make_request('get_info')
		self.t, self.n, self.q, self.p, self.h0, self.connected_users = pickle.loads(response)

	def gen_threshold_sign(self, h, m, s, shares):
		shaTSS = Shamir(self.t, self.n)
		k = shaTSS.SC(self.p, shares).list()[_sage_const_0 ]
		kk = bin(int(str(k)))[_sage_const_2 :]
		R = m.parent()
		f_len = int(kk[:_sage_const_8 ], _sage_const_2 )
		fs_len = int(kk[_sage_const_8 :_sage_const_16 ], _sage_const_2 )
		
		R = m.parent()
		f  = R([-_sage_const_1 *int(x) for x in kk[_sage_const_16 :_sage_const_16 +f_len]])
		fs = R([-_sage_const_1 *int(x) for x in kk[_sage_const_16 +f_len:_sage_const_16 +f_len+fs_len]])

		x = auxmath.normilize_coeffs(-(_sage_const_1 /self.q)*m*fs)
		y = auxmath.normilize_coeffs(-(_sage_const_1 /self.q)*m*f)
		s0 = x*f + y*fs
		s_res = R(s + s0)

		b = s_res * auxmath.normilize_coeffs2(s_res*self.h0 - m, self.q)

		print (b)
		print (b.norm(_sage_const_2 ))


	def add_shares(self, data):
		if len(self.shares) == self.t:
			return
		self.shares.append(pickle.loads(data))

	def __init__(self):
		self.get_info()

DC = DC_()

class HandleRequests(BaseHTTPRequestHandler):
	def _set_headers(self):
		self.send_response(_sage_const_200 )
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
			h, m, s, shares = data[_sage_const_0 ], data[_sage_const_1 ], data[_sage_const_2 ], data[_sage_const_3 :]
			DC.gen_threshold_sign(h, m, s, shares)
			self.send(b'add_shares')
	
		elif action == 'add_shares':
			print ('add_shares')
			self.send(b'add_shares')
			#DC.add_shares(data)

host = 'localhost'
port = _sage_const_8081 
HTTPServer((host, port), HandleRequests).serve_forever()

