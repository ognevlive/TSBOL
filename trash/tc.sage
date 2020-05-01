from sage.all import *
import configreader
import socketserver
import auxmath
import pickle
from shamir import Shamir

class Member:
	shares = []
	def __init__(self, f,g,F,G,NN):
		self.f = f
		self.g = g
		self.F = F
		self.G = G
		self.NN = NN
	
	def calculate_params(self, N, q, T = 'transpose'):
		if T == 'standard':
			self.fs = self.F
		elif T == 'transpose':
			self.fs = self.g
		self.h = auxmath.h_from_fg(self.f,self.g,N,q)
		
	def eval_k(self):
		# save unsigned values, remember it
		f_bin  = ''.join([bin(abs(x))[2:] for x in  self.f.list()])
		fs_bin = ''.join([bin(abs(x))[2:] for x in self.fs.list()])
		h_bin  = ''.join([bin(abs(x))[2:] for x in self.h.list()])
		self.k = int(bin(len(f_bin))[2:] + bin(len(fs_bin))[2:] + f_bin + fs_bin + h_bin, 2)
		
	def update_ms(self, m, s):
		self.m = m
		self.s = s


class TC_():
	NN = 251
	q = 128
	df = 73
	dg = 71
	t = 2
	n = 3
	T = 'transpose'

	members = []
	users_count = 0

	def __init__(self):
		for i in range(self.n + 1):
			print (i)
			self.add_member() 
		f_bin  = ''.join(['0' * (self.NN - len(self.members[0].f.list()))]  + [bin(abs(x))[2:] for x in  self.members[0].f.list()])
		fs_bin = ''.join(['0' * (self.NN - len(self.members[0].fs.list()))] + [bin(abs(x))[2:] for x in self.members[0].fs.list()])
		self.share_secret()

	def add_member(self):
		f,g,F,G = auxmath.gen_NTRU_fgFG(self.NN, self.q)
		m = Member(f,g,F,G, self.NN)
		m.calculate_params(self.NN, self.q, self.T)
		m.eval_k()
		self.members.append(m)

	def get_new_member_params(self):
		if self.users_count == n:
			print ('All clients already connected')
			return pickle.dumps([-1, -1, -1])
		self.users_count += 1
		f = self.members[self.users_count].f
		h = self.members[self.users_count].h
		fs = self.members[self.users_count].fs
		h0 = self.members[0].h
		shares = self.members[self.users_count].shares
		return pickle.dumps([self.users_count, f, fs, h, shares, h0, self.NN, self.q])

	def share_secret(self):
		shaTSS = Shamir(self.t, self.n)
		self.p, alpha = shaTSS.GC(128)
		shares = shaTSS.DS(self.p, alpha, self.members[0].k)
		for i in range(1, self.n+1):
			self.members[i].shares = shares[i-1]
		print ('sended shaTSS')

	def get_info(self):
		return pickle.dumps([self.q, self.members[0].h, self.p, self.t, self.n, self.NN])


# class TCPHandler(socketserver.BaseRequestHandler):
# 	def handle(self):
# 		global TC
# 		self.data = self.request.recv(1024).strip()
# 		if len(self.data) < 6:
# 			print ("Invalid size of request's buffer")
# 		command, data = self.data[:8], self.data[8:]
# 		print(command, data)

# 		if b'connect' in command:
# 			response = TC.get_new_member_params()
# 		elif b'info' in command:
# 			response = TC.get_info()
# 		else:
# 			print ('Invalid command')

# 		self.request.sendall(response)

# if __name__ == "__main__":
# 	HOST, PORT = "localhost", 8844
# 	with socketserver.TCPServer((HOST, PORT), TCPHandler) as server:
# 		server.serve_forever()