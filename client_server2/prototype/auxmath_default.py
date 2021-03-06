

# This file was *autogenerated* from the file auxmath.sage
from sage.all_cmdline import *   # import sage library

_sage_const_40 = Integer(40); _sage_const_1000 = Integer(1000); _sage_const_1 = Integer(1); _sage_const_0 = Integer(0); _sage_const_350 = Integer(350); _sage_const_2 = Integer(2)
from sage.all import *

RRR = RealField(_sage_const_40 );
P = PolynomialRing(ZZ, names=('x',)); (x,) = P._first_ngens(1);


#Generates a random polynomial of degree and norm bounded by N and no
def Rand_Pol_Fixed_Norm(N,no):
    v = vector(ZZ,N);
    for i in range(N):
        v[i] = randint(-_sage_const_1000 *no,_sage_const_1000 *no);
    norm = v*v;
    for i in range(N):
        v[i] = (v[i]*no)//isqrt(norm);
    f = sum(v[i]*x**i for i in range(N));
    return f;


#For fixed f,g,N,q, generates the NTRU polynomials F,G associated by f,g
def Derivation_FG(f,g,N,q):
    phi = x**N+_sage_const_1 ;
    (R_f, rho_f, iphi) = xgcd(f,phi);
    (R_g, rho_g, iphi) = xgcd(g,phi);
    assert(R_f.degree() == _sage_const_0 );
    assert(R_g.degree() == _sage_const_0 );
    (pgcd,alpha,beta) = xgcd(R_f[_sage_const_0 ],R_g[_sage_const_0 ]);
    if (pgcd != _sage_const_1 ):
        print ("pgcd =", pgcd)
        print ("The GCD of R_f and R_g is different of 1.")
    assert(pgcd == _sage_const_1 );
    F = -q*beta*rho_g;
    G = q*alpha*rho_f;
    k = Compute_k(f,g,F,G,N);
    iter = _sage_const_0 ;
    while (k!= _sage_const_0 ):
        F = (F - k*f).quo_rem(phi)[_sage_const_1 ];
        G = (G - k*g).quo_rem(phi)[_sage_const_1 ];
        k = Compute_k(f,g,F,G,N);
    return(F,G);


#Tests if f,g can generate a NTRU lattice
def Test(f,g,N,q):
    phi = x**N+_sage_const_1 ;
    (R_f, rho_f, iphi) = xgcd(f,phi);
    (R_g, rho_g, iphi) = xgcd(g,phi);
    assert(R_f.degree() == _sage_const_0 );
    assert(R_g.degree() == _sage_const_0 );
    (pgcd,alpha,beta) = xgcd(R_f[_sage_const_0 ],R_g[_sage_const_0 ]);
    if (pgcd != _sage_const_1 ):
        return False;
    return True;


#Returns f(1/x) mod (x^N+1)
def Reverse(f,N):
    g = sum( f[i]*(x**(N-i)) for i in (ellipsis_range(_sage_const_1 ,Ellipsis,N-_sage_const_1 )) );
    return f[_sage_const_0 ] - g;


#Compute the polynomial k used to reduce F,G
#(See the end of Appendix A in "NTRUSign: Digital Signatures using the NTRU Lattice")
def Compute_k(f,g,F,G,N):
    RRR=RealField(_sage_const_350 );
    phi = (x**N+_sage_const_1 );
    FB = Reverse(F,N);
    GB = Reverse(G,N);
    fb = Reverse(f,N);
    gb = Reverse(g,N);
    num = (fb*F+gb*G).quo_rem(phi)[_sage_const_1 ];
    den = (f*fb+g*gb).quo_rem(phi)[_sage_const_1 ];
    (a,iden,iphi) = xgcd(den,x**N+_sage_const_1 );
    k0 = (num*iden).quo_rem(phi)[_sage_const_1 ];
    k = sum( (k0[i]//a[_sage_const_0 ])*x**i for i in (ellipsis_range(_sage_const_0 ,Ellipsis,N-_sage_const_1 ))  );
    k = k.change_ring(ZZ);
    return k;


def Rotate(v,k):
    w = list(v);
    for i in range(k):
        w.insert(_sage_const_0 ,-w.pop());
    return vector(w);


#Returns the Anticirculant matrix A_N(f) generated by, f, x^k.f, ..., x^((N-1)k).f
def AC(f,N,k):
    u = f.coefficients();
    while(len(u)<N):
        u.append(_sage_const_0 );
    A = matrix(ZZ,N);
    z = vector(u);
    for i in range(N):
        A[i] = z;
        z = Rotate(z,k);
    return A;


#Tests if f is invertible mod X^N+1 mod q
def Is_Invertible(f,N,q):
    (pgcd,u,v) = xgcd(f,x**N+_sage_const_1 );
    rep = gcd(pgcd,q);
    return (rep==_sage_const_1 );


#Computes the inverse of f mod X^N+1 mod q
def Inverse(f,N,q):
    (pgcd,u,v) = xgcd(f,x**N+_sage_const_1 );
    p_1 = inverse_mod(pgcd[_sage_const_0 ],q);
    u = p_1*u;
    u = u.quo_rem(q)[_sage_const_1 ];
    return u;


#Computes h = g/f mod X^N+1 mod q
def h_from_fg(f,g,N,q):
    phi = x**N+_sage_const_1 ;
    f_1 = Inverse(f,N,q);
    h = ((f_1*g).quo_rem(phi)[_sage_const_1 ]).quo_rem(q)[_sage_const_1 ];
    return h;


#Returns the NTRU secret basis generated by f,g
def NTRU_Secret_Basis(f,g,N,q):
    (F,G) = Derivation_FG(f,g,N,q);
    #print (f*G - g*F == q)
    print (f)
    print (g)
    print (F)
    print (G)
    A = AC(f,N,_sage_const_1 );
    B = AC(g,N,_sage_const_1 );
    C = AC(F,N,_sage_const_1 );
    D = AC(G,N,_sage_const_1 );
    E = block_matrix([[A,B],[C,D]]);
    return E;


#Returns the NTRU public basis generated by f,g
def NTRU_Public_Basis(f,g,N,q):
    phi = x**N+_sage_const_1 ;
    h = h_from_fg(f,g,N,q);
    A = identity_matrix(ZZ,N);
    B = AC(h,N,_sage_const_1 );
    C = zero_matrix(ZZ,N);
    D = q*identity_matrix(ZZ,N);
    E = block_matrix([[A,B],[C,D]]);
    return E;


#Push-button procedure for generating the public and private bases for a NTRU lattice
#The expected norms of f,g is hardcoded ('norm') but you can change it
def Keygen(N,q):
    norm = isqrt(q)//_sage_const_2 ;
    Rep = False;
    while(Rep==False):
        f = Rand_Pol_Fixed_Norm(N,norm);
        g = Rand_Pol_Fixed_Norm(N,norm);
        Rep = Test(f,g,N,q);
        if(Rep==True):
            Rep = Is_Invertible(f,N,q);
    Sk = NTRU_Secret_Basis(f,g,N,q);
    Pk = NTRU_Public_Basis(f,g,N,q);
    return (Sk,Pk);

def gen_NTRU_fgFG(N, q):
    norm = isqrt(q)//_sage_const_2 ;
    Rep = False;
    while(Rep==False):
        f = Rand_Pol_Fixed_Norm(N,norm);
        g = Rand_Pol_Fixed_Norm(N,norm);
        Rep = Test(f,g,N,q);
        if(Rep==True):
            Rep = Is_Invertible(f,N,q);
    (F,G) = Derivation_FG(f,g,N,q);
    return f,g,F,G

def Inverse(f,N,q):
    (pgcd,u,v) = xgcd(f,x**N+_sage_const_1 );
    p_1 = inverse_mod(pgcd[_sage_const_0 ],q);
    u = p_1*u;
    u = u.quo_rem(q)[_sage_const_1 ];
    return u;


#Computes h = g/f mod X^N+1 mod q
def h_from_fg(f,g,N,q):
    phi = x**N+_sage_const_1 ;
    f_1 = Inverse(f,N,q);
    h = ((f_1*g).quo_rem(phi)[_sage_const_1 ]).quo_rem(q)[_sage_const_1 ];
    return h;

def normilize_coeffs(f):
    R = f.parent()
    normilized_coeffs = []
    for i in range(f.degree()):
        normilized_coeffs.append(int(round(x[i].n())))
    return R(normilized_coeffs)

def normilize_coeffs2(f, q):
    R = f.parent()
    normilized_coeffs = []
    for i in range(f.degree()):
        normilized_coeffs.append(x[i].n() % q)
    return R(normilized_coeffs)
