from sage.all import *
from hashlib import md5, sha1
import numpy as np
from time import time
import sys


def normilize_coeffs(f):
	normilized_coeffs = []
	for i in range(f.degree() + 1):
		normilized_coeffs.append(int(round(f[i])))
	R = f.parent()
	return R(normilized_coeffs)

def normilize_coeffs2(f, q):
	normilized_coeffs = []
	for i in range(f.degree() + 1):
		normilized_coeffs.append(f[i] % q)
	return Rx(normilized_coeffs)._polynomial

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


def key_generation(N, q, df, dg, B, t):
	B = 1
	while True:
		params = gen_NTRU_fgFG(N, q, df, dg) 
		if params != -1:
			f,g,F,G = params[0], params[1], params[2], params[3]
			break

	if t == 'standard':
		fs = F
	else:
		fs = g
	h = h_from_fg(f, fs, N, q)
	return [f, fs, h]


def H1(D):
	return bin(int(sha1(D.encode('utf-8')).hexdigest(), 16))

def H(D, N):
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

def norm(v):
	coefs = v.coefficients()
	n = 251
	sum1 = 0
	sum2 = 0
	# for vi in coefs[:n]:
	# 	sum1 += abs(vi)**2
	# norm = sum1**(1/2).n()
	for vi in coefs:
		sum1 += vi**2
		sum2 += vi
	sum2 = 1/n * (sum2 ** 2)
	return (sum1 - sum2).n()

N = 251
q = 128
df = 73
dg = 71
t = 'transpose'
D = '123123asd'

total = [0] * 20
cur = 0
nice = []

t1 = []
t2 = []
t10 = time()
t20 = time()
it = 0

users_count = int(sys.argv[1])
print(users_count)

while True:
	while True:
		it += 1
		global R1
		global phi
		global Rx
		R1.<x> = PolynomialRing(ZZ)
		phi = x**N - 1
		Rx = R1.quotient_by_principal_ideal(phi)

		B = []
		for i in range(users_count+1):
			B.append(key_generation(N, q, df, dg, 1, t))

		######

		r = randint(0, 77777)
		cur += 1
		s = 0

		m_default = H(D + str(r), N)
		m = m_default

		for i in range(1, users_count+1):
			x = Rx(normilize_coeffs(-1/q * m * B[i][1]))._polynomial % q
			y = Rx(normilize_coeffs(-1/q * m * B[i][0]))._polynomial % q
			si = (Rx(x*B[i][0])._polynomial % q + Rx(y*B[i][1])._polynomial % q) % q
			m = Rx(si * (B[i][2] - B[i-1][2]))._polynomial % q
			s = s + si

		x = Rx(normilize_coeffs(-1/q * m * B[0][1]))._polynomial % q
		y = Rx(normilize_coeffs(-1/q * m * B[0][0]))._polynomial % q
		s0 = (Rx(x*B[0][0])._polynomial % q + Rx(y*B[0][1])._polynomial % q) % q
		s = s + s0
		n = norm(s) + norm((s*B[0][2] - m_default) % q)

		#######


		if n < 0:
			total[0] += 1
			continue

		t1.append(time() - t10)
		t10 = time()

		b = sqrt(n)
		n = int(b) // 100 + 1
		total[n] += 1
		print (it, b, n, total)

		if b <= 310:
			t2.append(time() - t20)
			t20 = time()
			break

		if it % 100 == 0:
			print(it)
			print (np.array(t1).mean())
			print (np.array(t2).mean())
			print()

		if it > 5000:
			print(it)
			print (np.array(t1).mean())
			print (np.array(t2).mean())
			print()
			print (it, b, n, total)
			break
			break
