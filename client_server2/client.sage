import requests
import pickle
import base64
import threading
from hashlib import md5, sha1
from http.server import BaseHTTPRequestHandler, HTTPServer 
from time import sleep
from random import randint

sys.path.insert(1, 'math')
import auxmath

N = 251
R1.<x> = PolynomialRing(ZZ)
phi = x**N - 1
Rx = R1.quotient_by_principal_ideal(phi)

def H1(D):
    return bin(int(sha1(D.encode('utf-8')).hexdigest(), 16))

def H(D, N, q):
    print ('!')
    print (D, N, q)
    print (D)
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


def norm(v, N):
    coefs = v.coefficients()
    sum1 = 0
    sum2 = 0
    for vi in coefs:
        sum1 += vi**2
        sum2 += vi
    sum2 = 1/N * (sum2 ** 2)
    return (sum1 - sum2).n()

def normilize_coeffs(f):
    normilized_coeffs = []
    for i in range(f.degree() + 1):
        normilized_coeffs.append(int(round(f[i])))
    R = f.parent()
    return R(normilized_coeffs)

def make_request(auth, data='', action=''):
    if (len(auth) == 0):
        print ('Login first')
        return None
    r = requests.post('http://localhost:8080', auth=auth, headers={'Action' : action, 'Data' : data})
    return r.content

def print_menu():
    print (30 * "-"  + "MENU" + 30 * "-")
    print ("1. Login")
    print ("2. Info about users")
    print ("3. Connect")
    print ("4. Disconnect")
    print ("5. Offer user to kick")
    print ("6. Change t")
    print ("7. Verify")
    print ("8. Exit")
    print (67 * "-")

class User():
    def __init__(self, login='root', password='toor'):
        a = str(randint(1, 1111))
        self.auth = (a, a)

    def login(self):
        login = input("Login: ")
        password = input("Password: ")
        self.auth = (login, password)

    def info_about_users(self):
        response = make_request(self.auth, action='get_info_client')
        if response != None:
            self.t, self.n, self.connected_users = pickle.loads(response)
            print ('Current connected users: %d (%s)' % (len(self.connected_users.split(',')), self.connected_users))
            print ('Users nedeed to sign: %d' % self.t)
            print ('Maximum users: %d' % self.n)

    def connect(self):
        response = make_request(self.auth, action='connect')
        if response != None:
            params = pickle.loads(response)
            if len(params) == 1:
                print ("Can't connect, %s" % params[0])
                return
            self.f, self.fs, self.h, self.shares, self.h0, self.N, self.q = params[0], params[1], params[2], params[3], params[4], params[5], params[6]
            print ('f: %s' % str(self.f))
            print ('fs: %s' % str(self.fs))
            print ('h: %s' % str(self.h))
            print ('shares: %s' % str(self.shares))
            print ('h0: %s' % str(self.h0))
            print ('N: %s' % str(self.N))
            print ('q: %s' % str(self.q))

    def disconnect(self):
        response = make_request(self.auth, action='disconnect')

    def gen_partial_sign(self, h, m, s):
        R1.<x> = PolynomialRing(ZZ)
        phi = x**self.N - 1
        Rx = R1.quotient_by_principal_ideal(phi)

        x = Rx(normilize_coeffs(-1/self.q * m * self.fs))._polynomial % self.q
        y = Rx(normilize_coeffs(1/self.q * m * self.f))._polynomial % self.q

        si = (Rx(x*self.f)._polynomial % self.q + Rx(y*self.fs)._polynomial % self.q) % self.q
        m = Rx(si * (self.h - h))._polynomial % self.q
        s = s + si
        return self.h, m, s

    def offer(self):
        username = input("Enter offered username: ")
        encoded = base64.b64encode(username.encode())
        response = make_request(self.auth, action='offer', data=encoded)
        print (response)
        #r = 0
        # m0 = int(md5((username+str(r)).encode('utf-8')).hexdigest(),16)
        # s0 = 0
        # h0 = self.h0
        # m, s = self.gen_partial_sign(h0, m0, s0, username, 0)
        # print (m, s)
        # params = base64.b64encode(pickle.dumps([self.h, m, s]))
        # encoded = base64.b64encode(username.encode() + ';'.encode() + params)
        # response = make_request(self.auth, action='offer', data=encoded)
        # print (response)

    def check_status(self):
        response = make_request(self.auth, action='status')
        params = pickle.loads(response)
        status, data = int(params[0]), params[1]

        if status == 1:
            answer = input('\nDo u wonna kick %s?' % data)
            response = make_request(self.auth, action='vote', data=answer.encode())
        elif status == 2:
            print ('\nNot enouth votes for kick')
        elif status == 3: # sign, not used now
            h_, m_, s_ = data[0], data[1], data[2]
            h, m, s = self.gen_partial_sign(h_, m_, s_)
            encoded = base64.b64encode(pickle.dumps([self.h, m, s]))
            response = make_request(self.auth, action='sign', data=encoded)
        elif status == 4:
            print ('not implemented')

    def change(self):
        t_new = input("Enter new t: ")
        encoded = base64.b64encode(t_new.encode())
        response = make_request(self.auth, action='change', data=encoded)
        print (response)

    def encode_msg(self, D, r):
        print (D)
        return H(D + str(r), self.N, self.q)
            
    def verify(self):
        response = make_request(self.auth, action='verify')
        params = pickle.loads(response)
        s, D, r = params[0], params[1], params[2]
        m = self.encode_msg(D, r)
        n = norm(s, self.N) + norm((s*self.h0 - m) % self.q, self.N)
        b = sqrt(n)
        print (b)



loop = True       
user = User()
user.connect() # autoconnect

class ServerThread(threading.Thread):
   def run(self):
        while loop:
            sleep(3)
            user.check_status()
     
thread1 = ServerThread()
thread1.start()

while loop:
    print_menu()
    choice = int(input("Enter your choice [1-5]: "))
    
    if choice==1:     
        user.login()
    elif choice==2:
        user.info_about_users()
    elif choice==3:
        user.connect()
    elif choice==4:
        user.disconnect()
    elif choice==5:
        user.offer()
    elif choice==6:
        user.change()
    elif choice==7:
        user.verify()
    elif choice==8:
        loop = False
    else:
        print("Wrong option selection. Enter any key to try again..")
