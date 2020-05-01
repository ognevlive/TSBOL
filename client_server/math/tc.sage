from sage.all import *
import socketserver
import auxmath
import pickle
from shamir import Shamir

class Member:
	shares = []
	status = ['0', '']
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
	p = -1

	members = []
	#users_count = [range(1, n+1)]
	active_users = {}

	def __init__(self):
		for i in range(self.n + 1):
			print (i)
			self.add_member() 
		f_bin  = ''.join(['0' * (self.NN - len(self.members[0].f.list()))]  + [bin(abs(x))[2:] for x in  self.members[0].f.list()])
		fs_bin = ''.join(['0' * (self.NN - len(self.members[0].fs.list()))] + [bin(abs(x))[2:] for x in self.members[0].fs.list()])
		self.share_secret()

	def get_free_id(self):
		for i in range(1, self.n+1):
			if i not in self.active_users.values():
				return i
		return -1

	def add_member(self):
		f,g,F,G = auxmath.gen_NTRU_fgFG(self.NN, self.q)
		m = Member(f,g,F,G, self.NN)
		m.calculate_params(self.NN, self.q, self.T)
		m.eval_k()
		self.members.append(m)

	def get_new_member_params(self, username):
		id = self.get_free_id()
		if id == -1:
			print ('All clients already connected')
			return pickle.dumps(['server full'])

		f = self.members[id].f
		h = self.members[id].h
		fs = self.members[id].fs
		h0 = self.members[0].h
		shares = self.members[id].shares
		self.active_users.update({username : id})
		print (self.active_users)
		return pickle.dumps([f, fs, h, shares, h0, self.NN, self.q])

	def delete_user(self, username):
		del self.active_users[username]
		#for key, value in dict(self.active_users).items():
		#    if value == username:
		#        del self.active_users[key]

	def share_secret(self):
		shaTSS = Shamir(self.t, self.n)
		self.p, alpha = shaTSS.GC(128)
		shares = shaTSS.DS(self.p, alpha, self.members[0].k)
		for i in range(1, self.n+1):
			self.members[i].shares = shares[i-1]
		print ('secret generated')

	def get_info(self):
		print (self.active_users)
		return pickle.dumps([self.t, self.n, self.q, self.p, self.members[0].h, ', '.join(self.active_users.keys())])
		#return pickle.dumps([self.q, self.members[0].h, self.p, self.t, self.n, self.NN])

	def get_user_status(self, username):
		id = self.active_users[username]
		return self.members[id].status

	def set_user_status(self, username, status):
		id = self.active_users[username]
		self.members[id].status = status

	def get_user_shares(self, username):
		id = self.active_users[username]
		return self.members[id].shares


	def gen_partial_sign(self, h0, m0, s0, username):
		id = self.active_users[username]
		user = self.members[id]
		x = auxmath.normilize_coeffs(-(1/self.q)*m0*user.fs)
		y = auxmath.normilize_coeffs(-(1/self.q)*m0*user.f)
		s = x*user.f + y*user.fs
		
		m = auxmath.normilize_coeffs2(s * (user.h - h0), self.q)
		s = s + s0
		h = user.h
		return h, m, s

# TC = TC_()

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