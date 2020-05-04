from passlib.apps import custom_app_context as pwd_context
from flask_httpauth import HTTPBasicAuth
import flask
from flask import render_template
from flask_sqlalchemy import SQLAlchemy
import sys

sys.path.insert(1, 'prototype')
import tc

#TC = tc.TC_()

n = 5

app = flask.Flask(__name__)
app.config["DEBUG"] = True
db = SQLAlchemy(app)
auth = HTTPBasicAuth()


class User(db.Model):
	__tablename__ = 'users'
	id = db.Column(db.Integer, primary_key = True)
	username = db.Column(db.String(32), index = True)
	password_hash = db.Column(db.String(128))
	
	def hash_password(self, password):
		self.password_hash = pwd_context.encrypt(password)

	def verify_password(self, password):
		return pwd_context.verify(password, self.password_hash)

@auth.verify_password
def verify_password(username, password):
	user = User.query.filter_by(username = username).first()
	if not user or not user.verify_password(password):
		return False
	g.user = user
	return True

@app.route('/', methods=['GET'])
def home():
	return render_template('home.html', n = n)

@app.route('/api/users', methods = ['POST'])
def new_user():
	username = request.json.get('username')
	password = request.json.get('password')
	if username is None or password is None:
		abort(400) # missing arguments
	if User.query.filter_by(username = username).first() is not None:
		abort(400) # existing user
	user = User(username = username)
	user.hash_password(password)
	db.session.add(user)
	db.session.commit()
	return jsonify({ 'username': user.username }), 201, {'Location': url_for('get_user', id = user.id, _external = True)}

@app.route('/api/resource')	
@auth.login_required
def get_resource():
	return jsonify({ 'data': 'Hello, %s!' % g.user.username })


app.run()
