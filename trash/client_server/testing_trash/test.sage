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
	# for vi in coefs[:n]:
	# 	sum1 += abs(vi)**2
	# norm = sum1**(1/2).n()
	for vi in coefs:
		sum1 += abs(vi)**2
		sum2 += abs(vi)
	sum2 = 1/n * sum2 ** 2
	norm = (sum1 - sum2)**(1/2).n()
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
			self.fs = self.G
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


	def add_member(self):
		f,g,F,G = auxmath.gen_NTRU_fgFG(self.NN, self.q)
		
		m = Member(f,g,F,G, self.NN)
		m.calculate_params(self.NN, self.q, self.T)
		m.eval_k()
		self.members.append(m)


	def gen_partial_sign(self):
		D = '123111'
		r = 0

		R1.<x> = PolynomialRing(ZZ)
		phi = x**self.NN - 1
		Rx = R1.quotient_by_principal_ideal(phi)

		while True:
			s = 0
			m = int(md5((D+str(r)).encode('utf-8')).hexdigest(),16)
			#h = self.members[0].h

			for i in range(1,3):
				h = self.members[i-1].h

				user = self.members[i]
				#print ('member %d' % i)

				x = auxmath.normilize_coeffs(Rx, (-1 * m * user.fs)/self.q)
				y = auxmath.normilize_coeffs(Rx, (-1 * m * user.f) /self.q)
				#x = Rx(auxmath.normilize_coeffs(-(1/self.q)*m*user.fs))._polynomial
				#y = Rx(auxmath.normilize_coeffs(-(1/self.q)*m*user.f))._polynomial

				s0 = auxmath.normilize_coeffs2(Rx(x*user.f)._polynomial + Rx(y*user.fs)._polynomial, self.q)

				m = auxmath.normilize_coeffs2(Rx(s0 * (user.h - h))._polynomial, self.q)
				#m = Rx(s0 * (auxmath.normilize_coeffs2(user.h - h, self.q)))._polynomial#, self.q)
				s = s0 + s
				#s = auxmath.normilize_coeffs2(s + s0, self.q)

			if s == 0:
				print ('s = 0!')
				continue
				exit()

			b = self.gen_threshold_sign(m, s, r, D)
			if r % 1000 == 0:
				print (r, b)

			if b < 500:
				print (b)
			
			if b < 310:
				print ('r = %d' % r)
				print ('b = %d' % b)
				return [D, r, s]

			r+=1

	def verify(self, D, r, s):
		R1.<x> = PolynomialRing(ZZ)
		phi = x**self.NN - 1
		Rx = R1.quotient_by_principal_ideal(phi)

		m = md5((D+bin(r)[2:]).encode('utf-8')).hexdigest()#.hexdigest(),16)
		h0 = self.members[0].h
		print (r)
		print (s)

		#b = (s.norm(2)**2 + auxmath.normilize_coeffs2(Rx(s*h0 - m)._polynomial, self.q).norm(2)**2)**0.5
		#print (b)
		print ('-'*20)


	def gen_threshold_sign(self, m, s, r, D):
		h0 = self.members[0].h
		f0 = self.members[0].f
		fs0 = self.members[0].fs

		R1.<x> = PolynomialRing(ZZ)
		phi = x**self.NN - 1
		Rx = R1.quotient_by_principal_ideal(phi)

		x = auxmath.normilize_coeffs(Rx, (-1 * m * fs0)/self.q)
		y = auxmath.normilize_coeffs(Rx, (-1 * m * f0) /self.q)
		#x = Rx(auxmath.normilize_coeffs(-(1/self.q)*m*fs0))._polynomial
		#y = Rx(auxmath.normilize_coeffs(-(1/self.q)*m*f0))._polynomial

		s0 = auxmath.normilize_coeffs2(Rx(x*f0)._polynomial + Rx(y*fs0)._polynomial, self.q)

		#s = auxmath.normilize_coeffs2(s + s0, self.q)
		s = s + s0

		m0 = int(md5((D+str(r)).encode('utf-8')).hexdigest(),16)
		#b = (s.norm(2)**2 + auxmath.normilize_coeffs2(Rx(s*h0 - m0)._polynomial, self.q).norm(2)**2)**0.5
		b = (norm(s)**2 + norm(auxmath.normilize_coeffs2(Rx(s*h0)._polynomial - m0, self.q))**2)**0.5
		return b


TC = TC_()
D, r, s = TC.gen_partial_sign()
print (s)
TC.verify(D, r, s)
TC.verify(D, 0, s)
TC.verify(D, 111110, s)
TC.verify(D, 222222222220, s)
