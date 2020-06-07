from http.server import BaseHTTPRequestHandler, HTTPServer 
from sage.all import *
import socketserver
from hashlib import md5
import pickle
import socket
import requests
import base64

sys.path.insert(1, 'math')
import auxmath
from shamir import Shamir

def Babai_CVP(Lattice, w):
	L = Lattice.LLL()
	vt = L.solve_left(vector(QQ, w))
	v = vector(ZZ, [0]*len(L[0]))
	for t, vi in zip(vt, L):
		v += round(t) * vi
	return v

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
		response = self.make_request('get_info_dc')
		self.t, self.n, self.q, self.p, self.h0, self.H, self.t_new = pickle.loads(response)

	def gen_threshold_sign(self, h, m, s, shares):
		self.get_info()
		shaTSS = Shamir(self.t, self.n)

		if self.t_new == None:
			k = shaTSS.SC(self.p, shares).list()[0]
		else:
			M = []
			for i in range(self.t+self.t_new):
				row = [0] * (self.t+self.t_new)
				if i < self.t_new:
					row[i] = self.p
				else:
					row[i] = self.H / self.p
					for j in range(self.t_new):
						row[j] = shares[j][0] ** (i-self.t_new+1)
				M.append(row)

			M = matrix(QQ, M)
			target = [x[1] for x in shares[:self.t_new]] + [0]*self.t
			c = Babai_CVP(M, target)
			R = Integers(self.p)
			k = R((self.p/self.H)*c[self.t_new])

		print (k)
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