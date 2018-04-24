require 'sinatra'
class App < Sinatra::Base
enable :sessions
require 'open-uri'
require 'json'
require 'addressable'
require 'uri'
require 'sqlite3'
require 'bcrypt'
require 'slim'

	get ('/') do
		slim(:index)
	end

	get('/register') do
		slim(:register)
	end

	post('/register') do	
		username = params["username"]
		password = params["password"]
		cryptpassword = BCrypt::Password.create(password)
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		namelist = dbcooper.execute("SELECT username FROM users")
		namelist.each do |x|
			if username == x.join
				redirect('/fail')
			end
		end
		dbcooper.execute("INSERT INTO users('username','password') VALUES(?,?)", [username,cryptpassword.to_s])
		redirect('/logged_in/')
	end


	post('/login')	do
		username = params["username"]
		password = params["password"]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		password_digest = dbcooper.execute("SELECT password FROM users WHERE username = '#{username}'")
		password_digest = BCrypt::Password.new(password_digest.join)
		if password_digest == password
			session[:user] = username
			redirect('/logged_in/')
		else
		redirect('/fail')
		end
	end

	get('/logged_in/') do
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		username = session[:user]
		p username
		userid = dbcooper.execute("SELECT id FROM users WHERE username 	= '#{username}'").join
		info = dbcooper.execute("SELECT info FROM list WHERE userid = '#{userid}'")
		info_id = dbcooper.execute("SELECT id FROM list WHERE userid = '#{userid}'")
		slim(:to, locals:{ info:info, info_id:info_id})
	end

	post('/create') do
		username = session[:user]
		newinfo = params["newinfo"]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		userid = dbcooper.execute("SELECT id FROM users WHERE username = '#{username}'").join
		dbcooper.execute("INSERT INTO list ('info', 'userid') VALUES (?,?)", [newinfo, userid])
		redirect('/logged_in/')
	end

	post('/logout') do
		session[:user] = nil
		redirect('/')
	end	


end           
