from http.server import BaseHTTPRequestHandler, HTTPServer 
from hashlib import md5
from sage.all import *
import sqlite3
import os
import base64
import sys
import pickle
import requests
import time
from time import sleep
from threading import Timer

sys.path.insert(1, 'math')
import tc
TC = tc.TC_()

users_db = 'users.db'
votes_yes = set()


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

def query(sql, params):
	conn = sqlite3.connect(users_db)
	cursor = conn.cursor()
	cursor.execute(sql, params)
	data = cursor.fetchall()
	conn.commit()
	conn.close()
	return data

def make_request(port, data='', action=''):
	r = requests.post('http://localhost:%d' % port, headers={'Action' : action}, data=data)
	return r.content


class HandleRequests(BaseHTTPRequestHandler):
	def _set_headers(self):
		self.send_response(200)
		self.send_header('Content-type', 'text/html')
		self.end_headers()

	def send(self, data):
		self._set_headers()
		self.wfile.write(data)

	def check_auth(self):
		if self.headers['Authorization'] == None:
			return False
		auth = self.headers['Authorization'][6:]
		login, password = base64.b64decode(auth).decode('utf-8').split(':')
		true_pass = query("SELECT password FROM users WHERE login = ?", (login,))
		if true_pass == []:
			print ('register new user %s' % login)
			query('INSERT INTO users values (?,?)', (login, password))
		elif true_pass[0][0] != password:
			return False
		return True

	def get_active_user(self):
		auth = self.headers['Authorization'][6:]
		login, _ = base64.b64decode(auth).decode('utf-8').split(':')
		return login

	def get_user_id(self):
		username = self.get_active_user()
		return TC.active_users.get(username)

	def do_POST(self):
		try:
			action = self.headers['Action']
		except:
			self.send(b'wait Action header')
	
		if action == 'get_info_client':
			params = TC.get_info_client()
			self.send(params)
			return

		### NEED USE
		elif action == 'get_info_dc':
			params = TC.get_info_dc()
			self.send(params)
			return

		if self.check_auth() == False:
			self.send(b'invalid credentials')
	
		user = self.get_active_user()
		if action == 'connect':
			if user in TC.active_users:
				self.send(pickle.dumps(['current user already connected']))
				return
			params = TC.get_new_member_params(user)
			self.send(params)

		elif action == 'disconnect':
			params = TC.delete_user(user)
			self.send(b'ok')

		elif action == 'offer':
			encoded = self.headers['Data']
			offered_username = base64.b64decode(encoded).decode('utf-8')
			if offered_username not in TC.active_users:
				self.send(b'invalid offered username')
				return
			
			for u in TC.active_users:
				if u == user:
					votes_yes.add(u)
					continue
				TC.set_user_status(u, ['1', offered_username])
			Timer(10.0, self.vote_result, [offered_username]).start()
			self.send(b'ok')

		elif action == 'vote':
			answer = self.headers['Data']
			TC.set_user_status(user, ['0', ''])
			if answer == 'yes':
				votes_yes.add(user)
			self.send(b'ok')

		elif action == 'change':
			encoded = self.headers['Data']
			new_t = base64.b64decode(encoded).decode('utf-8')
			response = TC.change_t(int(new_t))
			self.send(response)

		elif action == 'sign':
			encoded = self.headers['Data']
			params = base64.b64decode(encoded)
			global hms
			hms = pickle.loads(params)
			TC.members[self.get_user_id()].signed = True
			TC.set_user_status(user, ['0', ''])
			self.send(b'ok')

		elif action == 'status':
			if self.get_user_id() == None:
				self.send(pickle.dumps(['-1', '']))
			else:
				self.send(pickle.dumps(TC.get_user_status(user)))

		elif action == 'verify':
			self.send(pickle.dumps([TC.s, TC.D, TC.r]))

		else:
			print ('its ok')
			self.send(b'nice')

	def vote_result(self, offered_username):
		global votes_yes
		print ('vote: %s' % str(votes_yes))
		#t = TC.t if TC.t_new == None else TC.t_new 
		if len(votes_yes) < TC.t:
			print ('Not enouth votes')
			for u in TC.active_users:
				TC.set_user_status(u, ['2', ''])
			sleep(3)
			for u in TC.active_users:
				TC.set_user_status(u, ['0', ''])
			return

		# q = 128
		# N = 251

		# i = 0
		# while True:
		# 	i += 1
		# 	r = randint(0, 7777777)
		# 	m = TC.encode_msg(offered_username, r)
		# 	s = 0
		# 	h = TC.members[0].h
		# 	for username in votes_yes:
		# 		h, m, s = TC.gen_partial_sign(h, m, s, username)

		# 	R1.<x> = PolynomialRing(ZZ)
		# 	phi = x**N - 1
		# 	Rx = R1.quotient_by_principal_ideal(phi)
			
		# 	f  = TC.members[0].f
		# 	fs = TC.members[0].fs
		# 	h = TC.members[0].h

		# 	x = Rx(normilize_coeffs(-1/q * m * fs))._polynomial % q
		# 	y = Rx(normilize_coeffs(1/q * m * f))._polynomial % q

		# 	s0 = (Rx(x*f)._polynomial % q + Rx(y*fs)._polynomial % q) % q
		# 	s = s + s0

		# 	n = norm(s, N) + norm((s*h - m) % q, N)
		# 	if n < 0:
		# 		print ('need regenerate')
		# 		continue
		# 	b = sqrt(n)
		# 	if b < 400:
		# 		print ('WOW1 %d' % i)
		# 		print (b)
		# 	if b < 310:
		# 		print ('WOW2 %d' % i)
		# 		print (b)
		# 		s = s * 2
		# 		b = sqrt(norm(s, N) + norm((s*h - m) % q, N))
		# 		print (b)
		# 		s = s / 2
		# 		b = sqrt(norm(s, N) + norm((s*h - m) % q, N))
		# 		print (b)
		# 		exit()
#			print (b)

		#shares = [TC.get_user_shares(x) for x in votes_yes]
		print ('start sign')

		i = 0
		while True:
			r = randint(0, 7777777)
			m = m0 = TC.encode_msg(offered_username, r)
			s = 0
			h = TC.members[0].h
			
			shares = []
			for username in votes_yes:
				id = TC.active_users.get(username)
				member = TC.members[id]
				member.signed = False
				TC.set_user_status(username, ['3', [h, m, s]])
				while member.signed == False:
					pass
				h, m, s, share = hms[0], hms[1], hms[2], hms[3]
				shares.append(share)

			data = pickle.dumps([h, m, s, i] + shares)
			encoded = base64.b64encode(data)
			data = make_request(port=8081, action='generate', data=encoded)
			s = pickle.loads(data)
			if s == -1:
				print ('Invalid timestamp')
				votes_yes = set()
				return
			n = norm(s, TC.N) + norm((s*TC.members[0].h - m0) % TC.q, TC.N)
			if n < 0:
				continue
			b = sqrt(n)
			if b < 310:
				print (b)
				TC.s = s
				TC.D = offered_username
				TC.r = r
				break
			i+=1

		#TC.delete_user(offered_username)

		votes_yes = set()
		TC.share_secret()
		for username in TC.active_users.keys():
			if username == offered_username:
				continue
			id = TC.active_users.get(username)
			member = TC.members[id]
			TC.set_user_status(username, ['4', TC.members[id].shares])
		sleep(5)
		for username in TC.active_users.keys():
			id = TC.active_users.get(username)
			member = TC.members[id]
			TC.set_user_status(username, ['0', ''])


if os.path.exists(users_db) == False:
	conn = sqlite3.connect(users_db)
	cursor = conn.cursor()
	cursor.execute("""CREATE TABLE users
					  (login text, password text)
				   """)
	conn.close()


host = 'localhost'
port = 8080
HTTPServer((host, port), HandleRequests).serve_forever()

