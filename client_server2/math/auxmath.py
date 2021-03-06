

# This file was *autogenerated* from the file math/auxmath.sage
from sage.all_cmdline import *   # import sage library

_sage_const_251 = Integer(251); _sage_const_128 = Integer(128); _sage_const_73 = Integer(73); _sage_const_71 = Integer(71); _sage_const_1 = Integer(1); _sage_const_0 = Integer(0); _sage_const_2 = Integer(2)
from sage.all import *

#P.<x> = PolynomialRing(ZZ);

NN = _sage_const_251 
q = _sage_const_128 
df = _sage_const_73 
dg = _sage_const_71 
T = 'transpose'

R1 = PolynomialRing(ZZ, names=('x',)); (x,) = R1._first_ngens(1)
phi = x**NN - _sage_const_1 
Rx = R1.quotient_by_principal_ideal(phi)

# def gen_fg(R, d):
#     print (d)
#     while True:
#         f = R.random_element()._polynomial
#         coef = f.coefficients()
#         l = len([x for x in coef if x == 1])
#         if l == d:
#             print (f)
#             return f

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

def gen_p(f, Rx):
    test = _sage_const_1 
    for i in range(_sage_const_2 , NN):
        test *= Rx(f(x**i))
        test = test.mod(ffff)
    return test._polynomial


def poly_mult(f, g):
    res = _sage_const_0 
    for i in range(NN):
        res += f[i]*g[i]
    return res

def conv(f,g):
    tmp = (f * g) % (x**NN-_sage_const_1 )
    res = _sage_const_0 
    for i in range(NN):
        res += tmp[i]
    return res

def Reverse(f,N):
    g = sum( f[i]*(x**(N-i)) for i in (ellipsis_range(_sage_const_1 ,Ellipsis,N-_sage_const_1 )) );
    exit()
    return f[_sage_const_0 ] - g;

def Inverse(f,N,q):
    (pgcd,u,v) = xgcd(f,phi)
    p_1 = inverse_mod(pgcd[_sage_const_0 ],q)
    u = p_1*u
    u = u.quo_rem(q)[_sage_const_1 ]
    return u

# #Compute the polynomial k used to reduce F,G
# #(See the end of Appendix A in "NTRUSign: Digital Signatures using the NTRU Lattice")
def Compute_k(f,g,F,G,N):
    #FB = 1/F
    #GB = 1/G
    #fb = 1/f
    #gb = 1/g
    FB = Reverse(F,N)
    GB = Reverse(G,N)
    fb = Reverse(f,N)
    gb = Reverse(g,N)
    print (type(fb))
    print (type(F))
    exit()
    num = (fb*F+gb*G).quo_rem(phi)[_sage_const_1 ]
    den = (f*fb+g*gb).quo_rem(phi)[_sage_const_1 ]
    (a,iden,iphi) = xgcd(den,phi)
    k0 = (num*iden).quo_rem(phi)[_sage_const_1 ]
    k = sum( (k0[i]//a[_sage_const_0 ])*x**i for i in (ellipsis_range(_sage_const_0 ,Ellipsis,N-_sage_const_1 ))  )
    k = k.change_ring(ZZ)
    return k

def gen_NTRU_fgFG(NN, q):
    f = gen_f(Rx, df)
    g = gen_f(Rx, dg)
    f_res = f.resultant(phi)
    g_res = g.resultant(phi)
    Rf, rho_f, iphi = xgcd(f,phi)
    Rg, rho_g, iphi = xgcd(g,phi)
    _,alpha,beta = xgcd(Rf[_sage_const_0 ], Rg[_sage_const_0 ])
    F = -q*beta*rho_g;
    G = q*alpha*rho_f;
    k = Compute_k(f,g,F,G,NN)

    while (k!= _sage_const_0 ):
        F = (F - k*f).quo_rem(phi)[_sage_const_1 ]
        G = (G - k*g).quo_rem(phi)[_sage_const_1 ]
        k = Compute_k(f,g,F,G,NN)
    fg = f*G % phi
    gf = g*F % phi
    if(fg - gf != q):
        print ('error')
        return -_sage_const_1 
    return f,g,F,G

def h_from_fg(f,g,N,q):
    f_1 = Inverse(f,N,q)
#    one = f.parent().one()
#    print (f * f_1 % phi % q == one)
    #h = ((f_1*g).quo_rem(phi)[1]).quo_rem(q)[1]
    h = (f_1*g) % phi % q
    return h

def normilize_coeffs(R, f):
    normilized_coeffs = []
    for i in range(f.degree() + _sage_const_1 ):
        normilized_coeffs.append(int(round(f[i])))
    return R(normilized_coeffs)._polynomial

def normilize_coeffs2(f, q):
#    phi = x**N - 1
    R = f.parent()
    normilized_coeffs = []
    for i in range(f.degree() + _sage_const_1 ):
        normilized_coeffs.append(f[i] % q)
    return R(normilized_coeffs)

def normilize_coeffs3(f):
    R = f.parent()
    normilized_coeffs = []
    for i in range(f.degree() + _sage_const_1 ):
        normilized_coeffs.append(_sage_const_1 /_sage_const_2 )#f[i] - int(round(f[i])))
    return R(normilized_coeffs)

