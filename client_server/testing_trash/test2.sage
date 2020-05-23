from sage.all import *
from hashlib import md5
import socket

sys.path.insert(1, 'math')
import auxmath
from shamir import Shamir

q = 128

f,g,F,G = auxmath.gen_NTRU_fgFG(251, q)
h = auxmath.h_from_fg(f,F,251,q)

k1 = (f*h-F)/q
k2 = (g*h-G)/q

A = matrix([f, -k1, g, -k2])
B = matrix([1, h, 0, q])
C = matrix([f, F, g, G])
print (A*B==C)