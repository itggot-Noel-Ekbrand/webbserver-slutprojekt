require 'sinatra'
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
		userid = dbcooper.execute("SELECT id FROM users WHERE username 	= ?", username).join
		info = dbcooper.execute("SELECT text FROM list WHERE userid = '#{userid}'").join
		title = dbcooper.execute("SELECT title FROM list WHERE userid = '#{userid}'")
		info_id = dbcooper.execute("SELECT id FROM list WHERE userid = '#{userid}'").join
		session[:title] = title
		slim(:logged_in, locals:{ info:info, info_id:info_id, title:title})
	end

	post('/create') do
		username = session[:user]
		title = params["title"]
		text = params["text"]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		userid = dbcooper.execute("SELECT id FROM users WHERE username = '#{username}'").join
		all_titles = dbcooper.execute("SELECT title FROM list")
		p all_titles[0][0]
		p title
		i = 0
		while i < all_titles.size
			if title == all_titles[i][i]
				redirect('/reposti')
			else
				i += 1
			end
		end
		dbcooper.execute("INSERT INTO list ('title', 'text', 'userid') VALUES (?,?,?)", [title, text, userid])
		redirect('/logged_in/')
	end


	get('/reposti') do
		slim(:reposti)
	end



	get('/logged_in/:title') do
		username = session[:user]
		title = params[:title]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		userid = dbcooper.execute("SELECT id FROM users WHERE username = '#{username}'").join
		poster_id = dbcooper.execute("SELECT userid FROM list WHERE title = '#{title}'").join
		poster_name = dbcooper.execute("SELECT username FROM users WHERE id='#{poster_id}'").join
		info = dbcooper.execute("SELECT text FROM list WHERE userid = '#{userid}'").join
		info_id = dbcooper.execute("SELECT id FROM list WHERE userid = '#{userid}'").join
		slim(:post, locals:{ info:info, info_id:info_id, userid:userid, poster_name:poster_name})
	end




	post('/logout') do
		session[:user] = nil
		redirect('/')
	end	


         
