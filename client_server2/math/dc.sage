from http.server import BaseHTTPRequestHandler, HTTPServer 
from sage.all import *
import socketserver
from shamir import Shamir
from hashlib import md5
import pickle
import socket
import requests
import base64

### AUXMATH ###

def norm(v, N):
	coefs = v.coefficients()
	sum1 = 0
	sum2 = 0
	for vi in coefs:
		sum1 += vi**2
		sum2 += vi
	sum2 = 1/N * (sum2 ** 2)
	return (sum1 - sum2).n()

def normilize_coeffs(f):
	normilized_coeffs = []
	for i in range(f.degree() + 1):
		normilized_coeffs.append(int(round(f[i])))
	R = f.parent()
	return R(normilized_coeffs)

def Babai_CVP(Lattice, w):
	L = Lattice.LLL()
	vt = L.solve_left(vector(QQ, w))
	v = vector(ZZ, [0]*len(L[0]))
	for t, vi in zip(vt, L):
		v += round(t) * vi
	return v

### DC ###

class DC_():
	shares = []
	f = fs = None

	def __init__(self):
		self.get_info()
		
	def get_info(self):
		response = self.make_request('get_info_dc')
		self.t, self.n, self.N, self.q, self.T, self.p, self.h0, self.H, self.t_new = pickle.loads(response)

	def make_request(data='', action=''):
		r = requests.post('http://localhost:8080', headers={'Action' : action})
		return r.content

	def gen_threshold_sign(self, h, m, s, i, shares):
		self.get_info()
		shaTSS = Shamir(self.t, self.n)

		if i == 0:
			print ('UPDATE')
			print ('UPDATE')
			print ('UPDATE')
			print ('UPDATE')
			self.fs = None
			self.f = None
			print (shares)

		# if self.t_new == None:
		# 	k = shaTSS.SC(self.p, shares).list()[0]
		# else:
		# 	M = []
		# 	for i in range(self.t+self.t_new):
		# 		row = [0] * (self.t+self.t_new)
		# 		if i < self.t_new:
		# 			row[i] = self.p
		# 		else:
		# 			row[i] = self.H / self.p
		# 			for j in range(self.t_new):
		# 				row[j] = shares[j][0] ** (i-self.t_new+1)
		# 		M.append(row)

		# 	M = matrix(QQ, M)
		# 	target = [x[1] for x in shares[:self.t_new]] + [0]*self.t
		# 	c = Babai_CVP(M, target)
		# 	R = Integers(self.p)
		# 	k = R((self.p/self.H)*c[self.t_new])

		R1.<x> = PolynomialRing(ZZ)
		phi = x**self.N - 1
		Rx = R1.quotient_by_principal_ideal(phi)

		if self.f == None or self.fs == None:
			k = shaTSS.SC(self.p, shares).list()[0]
			kk = bin(int(str(k)))[2:]
			f_len = int(kk[:8], 2)
			fs_len = int(kk[8:16], 2)
			print (k)
			self.f  = Rx([-1*int(x) for x in kk[16:16+f_len]])._polynomial
			self.fs = Rx([-1*int(x) for x in kk[16+f_len:16+f_len+fs_len]])._polynomial
			T  = int(kk[16+f_len+fs_len:], 2)
			print (T)
			if T != self.T:
				return -1

		x = Rx(normilize_coeffs(-1/self.q * m * self.fs))._polynomial % self.q
		y = Rx(normilize_coeffs(1/self.q * m * self.f))._polynomial % self.q

		s0 = (Rx(x*self.f)._polynomial % self.q + Rx(y*self.fs)._polynomial % self.q) % self.q
		s = s + s0
		return s

		# n = norm(s, self.N) + norm((s*self.h0 - m) % self.q, self.N)
		# if n < 0:
		# 	return 10**10
		# b = sqrt(n)
		# print (b)
		# return b



# class DC_():
# 	shares = []

# 	def send_req(self, command, payload=''):
# 		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
# 			sock.connect((HOST, PORT))
# 			command = command + ' '*(8-len(command))
# 			sock.sendall(bytes(command + payload, "utf-8"))
# 			data = sock.recv(64000)
# 		return data

# 	def make_request(data='', action=''):
# 		r = requests.post('http://localhost:8080', headers={'Action' : action})
# 		return r.content

# 	def get_info(self):

# 		### FIX
# 		response = self.make_request('get_info')
# 		self.t, self.n, self.q, self.p, self.h0, self.connected_users = pickle.loads(response)

# 	def gen_threshold_sign(self, h, m, s, shares):
# 		shaTSS = Shamir(self.t, self.n)
# 		k = shaTSS.SC(self.p, shares).list()[0]
# 		kk = bin(int(str(k)))[2:]
# 		f_len = int(kk[:8], 2)
# 		fs_len = int(kk[8:16], 2)

# 		R1.<x> = PolynomialRing(ZZ)
# 		phi = x**self.N - 1
# 		Rx = R1.quotient_by_principal_ideal(phi)
		
# 		f  = Rx([-1*int(x) for x in kk[16:16+f_len]])
# 		fs = Rx([-1*int(x) for x in kk[16+f_len:16+f_len+fs_len]])

# 		x = Rx(normilize_coeffs(-1/q * m * fs))._polynomial % self.q
# 		y = Rx(normilize_coeffs(1/q * m * f))._polynomial % self.q

# 		s0 = (Rx(x*f)._polynomial % self.q + Rx(y*fs)._polynomial % self.q) % self.q
# 		s = s + s0

# 		n = norm(s, self.N) + norm((s*self.h0 - m) % self.q, self.N)
# 		if n < 0:
# 			print ('need regenerate')
# 		b = sqrt(n)
# 		print (b)


# 	def add_shares(self, data):
# 		if len(self.shares) == self.t:
# 			return
# 		self.shares.append(pickle.loads(data))

# 	def __init__(self):
# 		self.get_info()

# DC = DC_()

# class HandleRequests(BaseHTTPRequestHandler):
# 	def _set_headers(self):
# 		self.send_response(200)
# 		self.send_header('Content-type', 'text/html')
# 		self.end_headers()

# 	def send(self, data):
# 		self._set_headers()
# 		self.wfile.write(data)

# 	def do_POST(self):
# 		action = self.headers['Action']
	
# 		if action == 'generate':
# 			print ('generate')
# 			content_length = int(self.headers['Content-Length'])
# 			post_data = self.rfile.read(content_length)

# 			encoded = base64.b64decode(post_data)
# 			data = pickle.loads(encoded)
# 			h, m, s, shares = data[0], data[1], data[2], data[3:]
# 			DC.gen_threshold_sign(h, m, s, shares)
# 			self.send(b'add_shares')
	
# 		elif action == 'add_shares':
# 			print ('add_shares')
# 			self.send(b'add_shares')
# 			#DC.add_shares(data)

# host = 'localhost'
# port = 8081
# HTTPServer((host, port), HandleRequests).serve_forever()