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
		password_digest = dbcooper.execute("SELECT password FROM users WHERE username = ?", username)
		password_digest = BCrypt::Password.new(password_digest.join)
		if password_digest == password
			session[:user] = username
			redirect('/logged_in/')
		else
		redirect('/fail')
		end
	end

	get('/logged_in/') do
		username = session[:user]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		list_all = dbcooper.execute("SELECT * FROM list")
		users_all = dbcooper.execute("SELECT * FROM users")
		title = dbcooper.execute("SELECT title FROM list").join
		session[:title] = title
		slim(:logged_in, locals:{ list_all: list_all, user_all: users_all})
	end

	post('/create') do
		username = session[:user]
		if username == nil
			redirect('/fail')
		end
		title = params["title"].capitalize
		text = params["text"]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		userid = dbcooper.execute("SELECT id FROM users WHERE username = ?", username).join
		all_titles = dbcooper.execute("SELECT title FROM list")
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

	get('/fail') do
		slim(:fail)
	end


	get('/logged_in/:title') do
		username = session[:user]
		title = params[:title]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		list_all = dbcooper.execute("SELECT * FROM list")
		users_all = dbcooper.execute("SELECT * FROM users")
		comments_all = dbcooper.execute("SELECT * FROM comments") 
		post_id = dbcooper.execute("SELECT id FROM list WHERE title=?", title)
		session[:post_id] = post_id
		if comments_all[0][1] == nil
			slim(:post, locals:{ list_all: list_all, user_all: users_all, post_id: post_id})
		else
			poster_name = dbcooper.execute("SELECT username FROM users WHERE id=?", comments_all[post_id[0][0].to_i - 1][2])
			slim(:post, locals:{ list_all: list_all, user_all: users_all, comments_all:comments_all, post_id: post_id, poster_name:poster_name})
		end
	end

	post('/comment') do
		title = params[:title]
		username = session[:user]
		comment = params["comment"]
		post_id = session[:post_id]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		list_all = dbcooper.execute("SELECT * FROM list")
		users_all = dbcooper.execute("SELECT * FROM users")
		poster_id = dbcooper.execute("SELECT id FROM users WHERE username=?", username)
		dbcooper.execute("INSERT INTO comments ('comment', 'poster_id', 'post_id') VALUES (?,?,?)", [comment, poster_id, post_id])
		slim(:post, locals:{ list_all: list_all, user_all: users_all, post_id: post_id})
	end





	post('/logout') do
		session[:user] = nil
		redirect('/')
	end	


         
