from sage.all import *
from hashlib import md5
import socket
import sys
import pickle
import auxmath

HOST, PORT = "localhost", 8844

class Client():
	def send_req(self, command, port, payload=b'', need_response=True):
		data = ''
		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
			sock.connect((HOST, port))
			command = command + ' '*(8-len(command))
			sock.sendall(bytes(command, "utf-8")  + payload)
			if need_response: data = sock.recv(64000)
		return data

	def get_params(self):
		data = self.send_req('connect', 8844)
		params = pickle.loads(data)
		self.f  = params[1]
		self.fs = params[2]
		self.h  = params[3]
		self.num = params[0]
		self.shares = params[4]
		self.h0 = params[5]
		global NN
		global q
		NN = params[6]
		q = params[7]

	def send_sign(self):
		data = pickle.dumps([self.m, self.s])
		print (self.m, self.s)
		self.send_req('th_gen', 8843, data, need_response=False)

	def send_shares(self):
		data = pickle.dumps(self.shares)
		self.send_req('shares', 8843, data, need_response=False)

	def __init__(self, need_init=True):
		if need_init:
			self.get_params()
			self.send_shares()


def gen_partial_sign(members, D, r):
	members[0].m = int(md5((D+str(r)).encode('utf-8')).hexdigest(),16)
	members[0].s = 0
	members[0].h = members[1].h0

	for i in range(1, 3):
	    h, f, fs = members[i].h, members[i].f, members[i].fs
	    h_prev, m_prev, s_prev = members[i-1].h, members[i-1].m, members[i-1].s

	    x = auxmath.normilize_coeffs(-(1/q)*m_prev*fs)
	    y = auxmath.normilize_coeffs(-(1/q)*m_prev*f)
	    s = x*f + y*fs
	    m = auxmath.normilize_coeffs2(s * (h - h_prev), q)
	    s = s + s_prev
	    
	    members[i].m = m
	    members[i].s = s


clients = [Client(False)]
for i in range(1, 4):
	print ('connect %d' % i)
	clients.append(Client())

gen_partial_sign(clients, "testmsg123_", 0)

clients[2].send_sign()



