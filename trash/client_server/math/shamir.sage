def random_prime(k):
	while True:
		p = ZZ.random_element(2**k, 2**(k+1))
		if p.is_prime() == True:
			return p

class Shamir():
	
	def __init__(self, t, n):
		self._t = t
		self._n = n

		
	def GC(self, k):
		## (a) pick a prime p
		p = random_prime(k)
		assert p > self._n
		
		## (b) pick uniformly at random n distinct non-zero elements alpha from Zp*
		Zp = Zmod(p)
		alpha = []
		for i in range(self._n):
			alpha.append(Zp.random_element())
		
		return (p, alpha)
		# return x=(p, alpha)
		
		
	def DS(self, p, alpha, s):
		## generate t-1 uniformly random elements a=(a_1,...,a_(t-1)) from Zp
		Zp = Zmod(p)
		a = [s]
		for i in range(self._t - 1):
			a.append(Zp.random_element()) 
			
		# build the polynomial a(x)=s+a_1*x+...+a_(t-1)*x^(t-1) from Zp[x;t-1]
		F = FiniteField(p)
		P = F['x']
		ax = P(a)
		
		# generate shares sigma_i
		shares = []
		for i in range(self._n):
			sigma_i = ax(alpha[i]) % p
			shares.append([alpha[i], sigma_i])
		return shares
		
		
	def SC(self, p, shares):
		assert len(shares) == self._t
		F = FiniteField(p)
		P = F['x']
		return P.lagrange_polynomial(shares)
		

	def SG(self, sigma_i, p, H):
		r_i = randint(0, H)
		R = Integers(p)
		return R(sigma_i[0] * sigma_i[1] + r_i)

	# def ch_init(self, t_new, k, p):
	#     sigma_c = 2**(-self.n)
	#     appr = ((self.t+t_new)**(1/2)*2**((self.t+t_new)/2))
	#     g_cvp = log(appr, 2)
	#     sigma_F = t_new/self.t/k*(log(sigma_c**(-1/t_new)*self.*self.t, 2) + g_cvp + 1)
	#     alpha_noise = (1 - (1+sigma_F) / (t_new/self.t))
	#     H = floor(p**alpha_noise / 2)
	#     return H

		# shares_new = []
		# for share in shares:
		#     shares_new.append(shaTSS.SG(share, p, H))
		# return shares_new

	# def recover_after_change(self, t_new, p, H, shares_old, target):
	#     M = []
	#     for i in range(self.t+t_new):
	#         row = [0] * (self.t+t_new)
	#         if i < t_new:
	#             row[i] = p
	#         else:
	#             row[i] = H / p
	#             for j in range(t_new):
	#                 row[j] = shares_old[j][0] ** (i-t_new+1)
	#         M.append(row)

	#     M = matrix(QQ, M)
	#     c = Babai_CVP(M, target)
	#     R = Integers(p)
	#     recovered_s = R((p/H)*c[t_new])
	#     return recovered_s
