from sage.all import *

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
        print (P.lagrange_polynomial(shares))
        