from http.server import BaseHTTPRequestHandler, HTTPServer 
from hashlib import md5
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
votes_yes = []

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
	
		if action == 'get_info':
			params = TC.get_info()
			self.send(params)
			return

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
					votes_yes.append(u)
					continue
				TC.set_user_status(u, ['1', offered_username])
			Timer(10.0, self.vote_result, [offered_username]).start()
			self.send(b'ok')

		elif action == 'vote':
			answer = self.headers['Data']
			TC.set_user_status(user, ['0', ''])
			if answer == 'yes':
				votes_yes.append(user)
			self.send(b'ok')

		elif action == 'change':
			encoded = self.headers['Data']
			new_t = base64.b64decode(encoded).decode('utf-8')
			response = TC.change_t(int(new_t))
			self.send(response)


		# elif action == 'sign':
		# 	encoded = self.headers['Data']
		# 	params = base64.b64decode(encoded)
		# 	global hms
		# 	hms = pickle.loads(params)
		# 	print ('get sign')
		# 	self.send(b'ok')

		elif action == 'status':
			if id == None: self.send(pickle.dumps([-1, -1]))
			else:          self.send(pickle.dumps(TC.get_user_status(user)))
		
		else:
			print ('its ok')
			self.send(b'nice')

	def vote_result(self, args):
		offered_username = args[1]
		print (offered_username) # need fix, didnt test
		t = TC.t if TC.t_new == None else TC.t_new 
		if len(votes_yes) < TC.t:
			print ('Not enouth votes')
			for u in TC.active_users:
				TC.set_user_status(u, ['2', ''])
			sleep(3)
			for u in TC.active_users:
				TC.set_user_status(u, ['0', ''])
			return

		## add here cycle for r
		r = 0
		m0 = int(md5((offered_username+str(r)).encode('utf-8')).hexdigest(),16)
		s0 = 0
		h0 = TC.members[0].h

		# ?
		for username in votes_yes:
			h0, m0, s0 = TC.gen_partial_sign(h0, m0, s0, username)

		shares = [TC.get_user_shares(x) for x in votes_yes]
		data = pickle.dumps([h0, m0, s0] + shares)
		encoded = base64.b64encode(data)
		make_request(port=8081, action='generate', data=encoded)


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

