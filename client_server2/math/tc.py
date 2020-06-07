

# This file was *autogenerated* from the file math/tc.sage
from sage.all_cmdline import *   # import sage library

_sage_const_251 = Integer(251); _sage_const_1 = Integer(1); _sage_const_16 = Integer(16); _sage_const_0 = Integer(0); _sage_const_2 = Integer(2); _sage_const_3 = Integer(3); _sage_const_321 = Integer(321); _sage_const_128 = Integer(128); _sage_const_73 = Integer(73); _sage_const_71 = Integer(71); _sage_const_5 = Integer(5); _sage_const_1024 = Integer(1024)
from sage.all import *
import socketserver
import pickle
import time
from shamir import Shamir
from hashlib import sha1

N = _sage_const_251 
R1 = PolynomialRing(ZZ, names=('x',)); (x,) = R1._first_ngens(1)
phi = x**N - _sage_const_1 
Rx = R1.quotient_by_principal_ideal(phi)

### AUX MATH ###

def normilize_coeffs(f):
	normilized_coeffs = []
	for i in range(f.degree() + _sage_const_1 ):
		normilized_coeffs.append(int(round(f[i])))
	R = f.parent()
	return R(normilized_coeffs)

def H1(D):
	return bin(int(sha1(D.encode('utf-8')).hexdigest(), _sage_const_16 ))

def H(D, N, q):
	h1 = H1(D)
	i = _sage_const_0 
	h = ''
	while True:
		app = bin(i)[_sage_const_2 :]
		d = hex(int(h1 + app, _sage_const_2 ))
		h2 = sha1(d.encode('utf-8')).hexdigest()
		h += h2
		if len(h) > N * _sage_const_2 :
			break
	h = h[:N*_sage_const_2 ]
	coefs = []
	for j in range(_sage_const_0 , len(h), _sage_const_2 ):
		coefs.append(int(h[j:j+_sage_const_2 ], _sage_const_16 ))
	return Rx(coefs)._polynomial % q

def Inverse(f,N,q):
	(pgcd,u,v) = xgcd(f,phi)
	p_1 = inverse_mod(pgcd[_sage_const_0 ],q)
	u = p_1*u
	u = u.quo_rem(q)[_sage_const_1 ]
	return u

def h_from_fg(f,g,N,q):
	f_1 = Inverse(f,N,q)
	h = Rx(f_1*g)._polynomial % q
	return h

def Reverse(f,N):
	g = sum( f[i]*(x**(N-i)) for i in (ellipsis_range(_sage_const_1 ,Ellipsis,N-_sage_const_1 )) );
	return f[_sage_const_0 ] - g;

def Compute_k(f,g,F,G,N):
	FB = Reverse(F,N)
	GB = Reverse(G,N)
	fb = Reverse(f,N)
	gb = Reverse(g,N)
	num = (fb*F+gb*G).quo_rem(phi)[_sage_const_1 ]
	den = (f*fb+g*gb).quo_rem(phi)[_sage_const_1 ]
	(a,iden,iphi) = xgcd(den,phi)
	k0 = (num*iden).quo_rem(phi)[_sage_const_1 ]
	k = sum( (k0[i]//a[_sage_const_0 ])*x**i for i in (ellipsis_range(_sage_const_0 ,Ellipsis,N-_sage_const_1 ))  )
	k = k.change_ring(ZZ)
	return k

def gen_f(R, df):
	f = R.random_element()._polynomial
	coefs = [abs(x) for x in f.coefficients()]
	coefs_count = len(coefs)
	for i in range(coefs_count):
		if coefs[i] == _sage_const_0 :
			coefs[i] = -_sage_const_1 
		else:
			coefs[i] = _sage_const_0 
	for i in range(df):
		while True:
			a = randint(_sage_const_0 , coefs_count - _sage_const_1 )
			if coefs[a] != _sage_const_1 :
				coefs[a] = _sage_const_1 
				break
	return R(coefs)._polynomial

def gen_NTRU_fgFG(N, q, df, dg):
	f = gen_f(Rx, df)
	g = gen_f(Rx, dg)
	f_res = f.resultant(phi)
	g_res = g.resultant(phi)
	Rf, rho_f, iphi = xgcd(f,phi)
	Rg, rho_g, iphi = xgcd(g,phi)
	_,alpha,beta = xgcd(Rf[_sage_const_0 ], Rg[_sage_const_0 ])
	F = -q*beta*rho_g;
	G = q*alpha*rho_f;
	k = Compute_k(f,g,F,G,N)

	while (k!= _sage_const_0 ):
		F = (F - k*f).quo_rem(phi)[_sage_const_1 ]
		G = (G - k*g).quo_rem(phi)[_sage_const_1 ]
		k = Compute_k(f,g,F,G,N)
	fg = f*G % phi
	gf = g*F % phi
	if(fg - gf != q):
		return -_sage_const_1 
	return f,g,F,G

### MEMBER ###

class Member:
	shares = []
	status = ['0', '']
	signed = False
	def __init__(self, N, q, df, dg, T):
		while True:
			params = gen_NTRU_fgFG(N, q, df, dg) 
			if params != -_sage_const_1 :
				self.f,g,F,G = params[_sage_const_0 ], params[_sage_const_1 ], params[_sage_const_2 ], params[_sage_const_3 ]
				break

		if T == 'standard':
			self.fs = F
		else:
			self.fs = g
		self.h = h_from_fg(self.f, self.fs, N, q)

		
	def eval_k(self, q):
		# save unsigned values, remember it
		f_bin  = ''.join([bin(abs(x))[_sage_const_2 :] for x in  self.f.list()])
		fs_bin = ''.join([bin(abs(x))[_sage_const_2 :] for x in self.fs.list()])
		#h_bin  = ''.join([bin(abs(x))[2:] for x in self.h.list()])
		self.T = int(time.time())
		self.k = int(bin(len(f_bin))[_sage_const_2 :] + bin(len(fs_bin))[_sage_const_2 :] + f_bin + fs_bin + bin(self.T)[_sage_const_2 :], _sage_const_2 )
		
	def update_ms(self, m, s):
		self.m = m
		self.s = s

### TC ###

class TC_():
	N = _sage_const_251 
	NORM_BOUND = _sage_const_321 
	q = _sage_const_128 
	df = _sage_const_73 
	dg = _sage_const_71 
	t = _sage_const_2 
	n = _sage_const_5 
	T = 'transpose'
	p = -_sage_const_1 
	H = None
	t_new = None

	members = []
	#users_count = [range(1, n+1)]
	active_users = {}

	def __init__(self):
		for i in range(self.n + _sage_const_1 ):
			print (i)
			self.add_member() 
		self.share_secret()

	def get_free_id(self):
		for i in range(_sage_const_1 , self.n+_sage_const_1 ):
			if i not in self.active_users.values():
				return i
		return -_sage_const_1 

	def add_member(self):
		m = Member(self.N, self.q, self.df, self.dg, self.T)
		m.eval_k(self.q)
		self.members.append(m)

	def get_new_member_params(self, username):
		id = self.get_free_id()
		if id == -_sage_const_1 :
			print ('All clients already connected')
			return pickle.dumps(['server full'])

		f = self.members[id].f
		h = self.members[id].h
		fs = self.members[id].fs
		h0 = self.members[_sage_const_0 ].h
		shares = self.members[id].shares
		self.active_users.update({username : id})
		print (self.active_users)
		return pickle.dumps([f, fs, h, shares, h0, self.N, self.q])

	def delete_user(self, username):
		del self.active_users[username]
	
	def share_secret(self):
		self.k = _sage_const_1024 
		self.shaTSS = Shamir(self.t, self.n)
		self.p, alpha = self.shaTSS.GC(self.k)
		self.T = self.members[_sage_const_0 ].T
		print ('T: %d' % self.T)
		print ('k ' + str(self.members[_sage_const_0 ].k))
		shares = self.shaTSS.DS(self.p, alpha, self.members[_sage_const_0 ].k)
		for i in range(_sage_const_1 , self.n+_sage_const_1 ):
			self.members[i].shares = shares[i-_sage_const_1 ]
		print ('secret generated')

	def change_t(self, t_new):
		if t_new > self.n or t_new <= self.t:
			return b'invalid new t'

		sigma_c = _sage_const_2 **(-self.n)
		appr = ((self.t+t_new)**(_sage_const_1 /_sage_const_2 )*_sage_const_2 **((self.t+t_new)/_sage_const_2 ))
		g_cvp = log(appr, _sage_const_2 )
		sigma_F = t_new/self.t/self.k*(log(sigma_c**(-_sage_const_1 /t_new)*self.n*self.t, _sage_const_2 ) + g_cvp + _sage_const_1 )
		alpha_noise = (_sage_const_1  - (_sage_const_1 +sigma_F) / (t_new/self.t))
		H = floor(self.p**alpha_noise / _sage_const_2 )
		for i in range(_sage_const_1 , self.n+_sage_const_1 ):
			alpha = self.members[i].shares[_sage_const_0 ]
			sigma = self.members[i].shares[_sage_const_1 ]
			self.members[i].shares[_sage_const_1 ] = self.shaTSS.SG([alpha, sigma], self.p, H)
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
		return pickle.dumps([self.t, self.n, self.N, self.q, self.T, self.p, self.members[_sage_const_0 ].h, self.H, self.t_new])

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

		x = Rx(normilize_coeffs(-_sage_const_1 /self.q * m * user.fs))._polynomial % self.q
		y = Rx(normilize_coeffs(_sage_const_1 /self.q * m * user.f))._polynomial % self.q

		si = (Rx(x*user.f)._polynomial % self.q + Rx(y*user.fs)._polynomial % self.q) % self.q
		m = Rx(si * (user.h - h))._polynomial % self.q
		s = s + si
		return user.h, m, s

	def encode_msg(self, D, r):
		return H(D + str(r), self.N, self.q)


