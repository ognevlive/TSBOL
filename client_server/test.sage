from sage.all import *
from hashlib import md5
import socket

sys.path.insert(1, 'math')
import auxmath
from shamir import Shamir

def modulo(h, u, N, q):
	R = h.parent()
	v = []
	for k in range(N):
		vk = 0
		for i in range(N):
			for j in range(N):
				if (i+j)%N == k:
					vk += h[i] * u[j] % q
		v.append(vk % q)
#	print (v)
	return R(v)

def norm(v):
	coefs = v.coefficients()
	n = len(coefs)
	sum1 = 0
	sum2 = 0
	for vi in coefs[:n]:
		sum1 += abs(vi)**2
	norm = sum1**(1/2).n()
	# for vi in coefs[:n]:
	# 	sum1 += abs(vi)**2
	# 	sum2 += vi
	# sum2 = 1/n * sum2 ** 2
	# norm = (sum1 - sum2)**(1/2).n()
	return norm


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
		self.h = auxmath.h_from_fg(self.f,self.fs,N,q)

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
	n = 4
	T = 'transpose'
	NNN = 310

	members = []
	#users_count = [range(1, n+1)]
	active_users = {}

	def __init__(self):
		for i in range(self.n + 1):
			print (i)
			self.add_member() 
		#f_bin  = ''.join(['0' * (self.NN - len(self.members[0].f.list()))]  + [bin(abs(x))[2:] for x in  self.members[0].f.list()])
		#fs_bin = ''.join(['0' * (self.NN - len(self.members[0].fs.list()))] + [bin(abs(x))[2:] for x in self.members[0].fs.list()])
		#self.share_secret()

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


	def gen_partial_sign(self):
		D = '77777'
		r = 0
		m = int(md5((D+bin(r)[2:]).encode('utf-8')).hexdigest(),16)
		s = 0
		h = self.members[0].h

		R1.<x> = PolynomialRing(ZZ)
		phi = x**self.NN - 1

		for i in range(1,3):
			print ('member %d' % i)
			user = self.members[i]

			x = auxmath.normilize_coeffs((-(1/self.q)*m*user.fs))
			y = auxmath.normilize_coeffs((-(1/self.q)*m*user.f)) 
			s0 = (x*user.f) + (y*user.fs)

			m = auxmath.normilize_coeffs2(s0 * (user.h - h), self.q)

			s = s + s0
			h = user.h	

		return [h,m,s]


	def gen_threshold_sign(self, h, m, s):
		h0 = self.members[0].h
		f0 = self.members[0].f
		fs0 = self.members[0].fs

		D = '77777'
		r = 0
		m0 = int(md5((D+bin(r)[2:]).encode('utf-8')).hexdigest(),16)

		x = auxmath.normilize_coeffs(-(1/self.q)*m*fs0)
		y = auxmath.normilize_coeffs(-(1/self.q)*m*f0)
		s0 = x*f0 + y*fs0

		s = s + s0

		b = (s.norm(2)**2 + auxmath.normilize_coeffs2((s*h0 - m0), self.q).norm(2)**2)**0.5
		print (b)
		print ('-' * 20)


		m0 = int(md5((D+bin(r)[2:]).encode('utf-8')).hexdigest(),16) ** 2
		s = s + 22 #* s
		b = (s.norm(2)**2 + auxmath.normilize_coeffs2((s*h0 - m0), self.q).norm(2)**2)**0.5
		print (b)


TC = TC_()
hms = TC.gen_partial_sign()
TC.gen_threshold_sign(hms[0], hms[1], hms[2])
