from sage.all import *
from hashlib import md5, sha1
import socket

sys.path.insert(1, 'math')
import auxmath
from shamir import Shamir

N = 251
R1.<x> = PolynomialRing(ZZ)
phi = x**N - 1
Rx = R1.quotient_by_principal_ideal(phi)

def normilize_coeffs(f):
	normilized_coeffs = []
	for i in range(f.degree() + 1):
		normilized_coeffs.append(int(round(f[i])))
	return Rx(normilized_coeffs)._polynomial

def normilize_coeffs2(f, q):
	normilized_coeffs = []
	for i in range(f.degree() + 1):
		normilized_coeffs.append(f[i] % q)
	return Rx(normilized_coeffs)._polynomial

def normilize_coeffs3(f):
	R = f.parent()
	normilized_coeffs = []
	for i in range(f.degree() + 1):
		normilized_coeffs.append(1/2)#f[i] - int(round(f[i])))
	return R(normilized_coeffs)


def Inverse(f,N,q):
	(pgcd,u,v) = xgcd(f,phi)
	p_1 = inverse_mod(pgcd[0],q)
	u = p_1*u
	u = u.quo_rem(q)[1]
	return u

def h_from_fg(f,g,N,q):
	f_1 = Inverse(f,N,q)
	h = (f_1*g) % phi % q
	return h

def Reverse(f,N):
	g = sum( f[i]*(x^(N-i)) for i in [1..N-1] );
	return f[0] - g;

def Compute_k(f,g,F,G,N):
	#FB = 1/F
	#GB = 1/G
	#fb = 1/f
	#gb = 1/g
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
		print ('error')
		return -1
	return f,g,F,G


def key_generation(N, q, df, dg, B, t):
	B = 1
	f,g,F,G = gen_NTRU_fgFG(N, q, df, dg)

	if t == 'standard':
		fs = F
	else:
		fs = g
	h = h_from_fg(f, fs, N, q)
	#print (matrix(Rx, 2, 2, [f, F, g, G]).det())

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
	return Rx(coefs)._polynomial

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

def balancedmod(f,q):
	''' reduces every coefficient of a Zx polynomial f modulo q
		with additional balancing, so the result coefficients are integers in interval [-q/2, +q/2]
		more specifically: for an odd q [-(q-1)/2, +(q-1)/2], for an even q [-q/2, +q/2-1]. 

		returns Zx reduced polynomial'''

	Zx.<x> = ZZ[]
	g = list(((f[i] + q//2) % q) - q//2 for i in range(N))
	return Zx(g)

N = 251
q = 128
df = 73
dg = 71
t = 'transpose'
B0 = key_generation(N, q, df, dg, 1, t)

D = '123123asd'
r = 0
s = 0

f = B0[0]
g = B0[1]
h = B0[2]

#	return [f, fs, h]
m_default = H(D + str(r), N)
m = m_default

x = normilize_coeffs(-1 * m * g / q)
y = normilize_coeffs(m * f / q)

e1 = -1 * balancedmod(x, q)
e2 = -1 * balancedmod(y, q)

s = Rx(e1 * f)._polynomial + Rx(e2 * g)._polynomial

t = s * h % q

print (s)
b = sqrt((s.norm(2))**2 + ((t-m).norm(2))**2).n()
print (b)

exit()

si = x*B1[0] + y*B1[1]

m = (si * (B1[2] - B0[2])) % q

s = s + si

#####

x = normilize_coeffs(- (1/q) * m * B0[1])
y = normilize_coeffs((1/q) * m * B0[0])

si = x*B0[0] + y*B0[1]

s = s + si

b = sqrt(((s.norm(2))**2 + ((s*B0[2] - m_default) % q)))
print (b)
b = sqrt(s.norm(2)**2 + ((s*B0[2] - m_default) % q).norm(2)**2)
print (b)

exit()

