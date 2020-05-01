import requests
import pickle
import base64
import threading
from hashlib import md5
from http.server import BaseHTTPRequestHandler, HTTPServer 
from time import sleep
from random import randint

sys.path.insert(1, 'math')
import auxmath

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
    print ("6. Exit")
    print ("7. Exit")
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
        response = make_request(self.auth, action='get_info')
        if response != None:
            self.t, self.n, _, _, _, self.connected_users = pickle.loads(response)
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

    def gen_partial_sign(self, h0, m0, s0):
        x = auxmath.normilize_coeffs(-(1/self.q)*m0*self.fs)
        y = auxmath.normilize_coeffs(-(1/self.q)*m0*self.f)
        s = x*self.f + y*self.fs
        m = auxmath.normilize_coeffs2(s * (self.h - h0), self.q)
        s = s + s0
        return m, s

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
            h0, m0, s0 = pickle.dumps(data)
            m, s = self.gen_partial_sign(h0, m0, s0)
            encoded = base64.b64encode(pickle.dumps([self.h, m, s]))
            response = make_request(self.auth, action='sign', data=encoded)
            print (response)


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
        print ("Menu 5 has been selected")
        loop = False
    elif choice==7:
        print ("Menu 5 has been selected")
        loop = False
    else:
        print("Wrong option selection. Enter any key to try again..")
