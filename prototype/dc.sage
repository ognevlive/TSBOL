from sage.all import *
import socketserver
import auxmath
from shamir import Shamir
from hashlib import md5
import pickle
import socket

HOST, PORT = "localhost", 8844

class DC_():
	shares = []

	def send_req(self, command, payload=''):
		with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
			sock.connect((HOST, PORT))
			command = command + ' '*(8-len(command))
			sock.sendall(bytes(command + payload, "utf-8"))
			data = sock.recv(64000)
		return data

	def get_info(self):
		received = self.send_req('info')
		params = pickle.loads(received)
		self.q = params[0]
		self.h = params[1]
		self.p = params[2]
		self.t = params[3]
		self.n = params[4]
		self.NN = params[5]

	def gen_threshold_sign(self, data):
		params = pickle.loads(data)
		m = params[0]
		s = params[1]

		shaTSS = Shamir(self.t, self.n)
		k = shaTSS.SC(self.p, self.shares).list()[0]
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

		D = 'testmsg123_'
		m0 = int(md5((D+str(0)).encode('utf-8')).hexdigest(),16)

		print (s_res*self.h - m0)

		b = s_res * auxmath.normilize_coeffs2(s_res*self.h - m0, self.q)
		print (b)
		print (b.norm(2))



		D = 'testmsg123_'
		r = 100
		s = s_res + 100

		m = int(md5((D+str(r)).encode('utf-8')).hexdigest(),16)

		b = (s * auxmath.normilize_coeffs2(s*self.h - m, self.q)).norm(2)
		print (b)


	def add_shares(self, data):
		if len(self.shares) == self.t:
			return
		self.shares.append(pickle.loads(data))

	def __init__(self):
		self.get_info()

DC = DC_()

class TCPHandler(socketserver.BaseRequestHandler):
	def handle(self):
		global DC
		self.data = self.request.recv(32000).strip()
		if len(self.data) < 6:
			print ("Invalid size of request's buffer")
		command, data = self.data[:8], self.data[8:]
		print(command)

		if b'th_gen' in command:
			DC.gen_threshold_sign(data)
		if b'shares' in command:
			DC.add_shares(data)
		else:
			print ('Invalid command')

		#self.request.sendall(response)

if __name__ == "__main__":
	HOST, PORT = "localhost", 8843
	with socketserver.TCPServer((HOST, PORT), TCPHandler) as server:
		server.serve_forever()