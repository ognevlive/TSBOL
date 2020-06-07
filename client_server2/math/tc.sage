from sage.all import *
import socketserver
import pickle
import time
from shamir import Shamir
from hashlib import sha1

N = 251
R1.<x> = PolynomialRing(ZZ)
phi = x**N - 1
Rx = R1.quotient_by_principal_ideal(phi)

### AUX MATH ###

def normilize_coeffs(f):
	normilized_coeffs = []
	for i in range(f.degree() + 1):
		normilized_coeffs.append(int(round(f[i])))
	R = f.parent()
	return R(normilized_coeffs)

def H1(D):
	return bin(int(sha1(D.encode('utf-8')).hexdigest(), 16))

def H(D, N, q):
	h1 = H1(D)
	i = 0
	h = ''
	while True:
		app = bin(i)[2:]
		d = hex(int(h1 + app, 2))
		h2 = sha1(d.encode('utf-8')).hexdigest()
		h += h2
		if len(h) > N * 2:
			break
	h = h[:N*2]
	coefs = []
	for j in range(0, len(h), 2):
		coefs.append(int(h[j:j+2], 16))
	return Rx(coefs)._polynomial % q

def Inverse(f,N,q):
	(pgcd,u,v) = xgcd(f,phi)
	p_1 = inverse_mod(pgcd[0],q)
	u = p_1*u
	u = u.quo_rem(q)[1]
	return u

def h_from_fg(f,g,N,q):
	f_1 = Inverse(f,N,q)
	h = Rx(f_1*g)._polynomial % q
	return h

def Reverse(f,N):
	g = sum( f[i]*(x^(N-i)) for i in [1..N-1] );
	return f[0] - g;

def Compute_k(f,g,F,G,N):
	FB = Reverse(F,N)
	GB = Reverse(G,N)
	fb = Reverse(f,N)
	gb = Reverse(g,N)
	num = (fb*F+gb*G).quo_rem(phi)[1]
	den = (f*fb+g*gb).quo_rem(phi)[1]
	(a,iden,iphi) = xgcd(den,phi)
	k0 = (num*iden).quo_rem(phi)[1]
	k = sum( (k0[i]//a[0])*x^i for i in [0..N-1]  )
	k = k.change_ring(ZZ)
	return k

def gen_f(R, df):
	f = R.random_element()._polynomial
	coefs = [abs(x) for x in f.coefficients()]
	coefs_count = len(coefs)
	for i in range(coefs_count):
		if coefs[i] == 0:
			coefs[i] = -1
		else:
			coefs[i] = 0
	for i in range(df):
		while True:
			a = randint(0, coefs_count - 1)
			if coefs[a] != 1:
				coefs[a] = 1
				break
	return R(coefs)._polynomial

def gen_NTRU_fgFG(N, q, df, dg):
	f = gen_f(Rx, df)
	g = gen_f(Rx, dg)
	f_res = f.resultant(phi)
	g_res = g.resultant(phi)
	Rf, rho_f, iphi = xgcd(f,phi)
	Rg, rho_g, iphi = xgcd(g,phi)
	_,alpha,beta = xgcd(Rf[0], Rg[0])
	F = -q*beta*rho_g;
	G = q*alpha*rho_f;
	k = Compute_k(f,g,F,G,N)

	while (k!= 0):
		F = (F - k*f).quo_rem(phi)[1]
		G = (G - k*g).quo_rem(phi)[1]
		k = Compute_k(f,g,F,G,N)
	fg = f*G % phi
	gf = g*F % phi
	if(fg - gf != q):
		return -1
	return f,g,F,G

### MEMBER ###

class Member:
	shares = []
	status = ['0', '']
	signed = False
	def __init__(self, N, q, df, dg, T):
		while True:
			params = gen_NTRU_fgFG(N, q, df, dg) 
			if params != -1:
				self.f,g,F,G = params[0], params[1], params[2], params[3]
				break

		if T == 'standard':
			self.fs = F
		else:
			self.fs = g
		self.h = h_from_fg(self.f, self.fs, N, q)

		
	def eval_k(self, q):
		# save unsigned values, remember it
		f_bin  = ''.join([bin(abs(x))[2:] for x in  self.f.list()])
		fs_bin = ''.join([bin(abs(x))[2:] for x in self.fs.list()])
		#h_bin  = ''.join([bin(abs(x))[2:] for x in self.h.list()])
		self.T = int(time.time())
		self.k = int(bin(len(f_bin))[2:] + bin(len(fs_bin))[2:] + f_bin + fs_bin + bin(self.T)[2:], 2)
		
	def update_ms(self, m, s):
		self.m = m
		self.s = s

### TC ###

class TC_():
	N = 251
	NORM_BOUND = 321
	q = 128
	df = 73
	dg = 71
	t = 2
	n = 5
	T = 'transpose'
	p = -1
	H = None
	t_new = None

	members = []
	#users_count = [range(1, n+1)]
	active_users = {}

	def __init__(self):
		for i in range(self.n + 1):
			print (i)
			self.add_member() 
		self.share_secret()

	def get_free_id(self):
		for i in range(1, self.n+1):
			if i not in self.active_users.values():
				return i
		return -1

	def add_member(self):
		m = Member(self.N, self.q, self.df, self.dg, self.T)
		m.eval_k(self.q)
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
		return pickle.dumps([f, fs, h, shares, h0, self.N, self.q])

	def delete_user(self, username):
		del self.active_users[username]
	
	def share_secret(self):
		self.k = 1024
		self.shaTSS = Shamir(self.t, self.n)
		self.p, alpha = self.shaTSS.GC(self.k)
		self.T = self.members[0].T
		print ('T: %d' % self.T)
		print ('k ' + str(self.members[0].k))
		shares = self.shaTSS.DS(self.p, alpha, self.members[0].k)
		for i in range(1, self.n+1):
			self.members[i].shares = shares[i-1]
		print ('secret generated')

	def change_t(self, t_new):
		if t_new > self.n or t_new <= self.t:
			return b'invalid new t'

		sigma_c = 2**(-self.n)
		appr = ((self.t+t_new)**(1/2)*2**((self.t+t_new)/2))
		g_cvp = log(appr, 2)
		sigma_F = t_new/self.t/self.k*(log(sigma_c**(-1/t_new)*self.n*self.t, 2) + g_cvp + 1)
		alpha_noise = (1 - (1+sigma_F) / (t_new/self.t))
		H = floor(self.p**alpha_noise / 2)
		for i in range(1, self.n+1):
			alpha = self.members[i].shares[0]
			sigma = self.members[i].shares[1]
			self.members[i].shares[1] = self.shaTSS.SG([alpha, sigma], self.p, H)
			#self.members[i].status = ['4', ]
		self.t_new = t_new
		self.H = H
		print (t_new)
		return b'ok'


	def get_info_client(self):
		print (self.active_users)
		return pickle.dumps([self.t, self.n, ', '.join(self.active_users.keys())])
		#return pickle.dumps([self.q, self.members[0].h, self.p, self.t, self.n, self.NN])

	def get_info_dc(self):
		#print ([self.t, self.n, self.q, self.N, self.p, self.members[0].h, self.H, self.t_new])
		return pickle.dumps([self.t, self.n, self.N, self.q, self.T, self.p, self.members[0].h, self.H, self.t_new])

	def get_user_status(self, username):
		id = self.active_users[username]
		return self.members[id].status

	def set_user_status(self, username, status):
		id = self.active_users[username]
		self.members[id].status = status

	def get_user_shares(self, username):
		id = self.active_users[username]
		return self.members[id].shares


	def gen_partial_sign(self, h, m, s, username):
		id = self.active_users[username]
		user = self.members[id]

		x = Rx(normilize_coeffs(-1/self.q * m * user.fs))._polynomial % self.q
		y = Rx(normilize_coeffs(1/self.q * m * user.f))._polynomial % self.q

		si = (Rx(x*user.f)._polynomial % self.q + Rx(y*user.fs)._polynomial % self.q) % self.q
		m = Rx(si * (user.h - h))._polynomial % self.q
		s = s + si
		return user.h, m, s

	def encode_msg(self, D, r):
		return H(D + str(r), self.N, self.q)

