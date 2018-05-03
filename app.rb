require 'sinatra'
require 'open-uri'
require 'json'
require 'addressable'
require 'uri'
require 'sqlite3'
require 'bcrypt'
require 'slim'

class App < Sinatra::Base
	enable :sessions

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
		redirect('/')
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
		if session[:user]
			username = session[:user]
			dbcooper = SQLite3::Database.new("db/forum.sqlite")
			list_all = dbcooper.execute("SELECT * FROM list")
			users_all = dbcooper.execute("SELECT * FROM users")
			title = dbcooper.execute("SELECT title FROM list").join
			session[:title] = title
			user_id = dbcooper.execute("SELECT id FROM users WHERE username=?", username).join
			session[:user_id] = user_id
			slim(:logged_in, locals:{ list_all: list_all, users_all: users_all})
		else
			redirect('/fail')
		end
	end

	post('/create') do
		if session[:user]
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
		else
			redirect('/fail')
		end
	end


	get('/reposti') do
		slim(:reposti)
	end

	get('/fail') do
		slim(:fail)
	end


	get('/logged_in/:title') do
		if session[:user]
		username = session[:user]
		title = params[:title]
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		list_all = dbcooper.execute("SELECT * FROM list")
		users_all = dbcooper.execute("SELECT * FROM users")
		comments_all = dbcooper.execute("SELECT * FROM comments") 
		post_id = dbcooper.execute("SELECT id FROM list WHERE title=?", title)
		if comments_all[0][1] == nil
			slim(:post, locals:{ list_all: list_all, users_all: users_all, post_id: post_id})
		else
			comments = dbcooper.execute("SELECT comment FROM comments WHERE post_id=?", post_id)
			poster_id = dbcooper.execute("SELECT id FROM users WHERE username=?", username)
			slim(:post, locals:{ list_all: list_all, users_all: users_all, comments_all:comments_all, post_id: post_id, poster_id:poster_id, comments:comments})
		end
		else
			redirect('/fail')
		end
	end

	post('/comment') do
		if session[:user]
			title = params[:title]
			username = session[:user]
			comment = params["comment"]
			if comment[0] == nil
				redirect('/fail')
			else
				post_id = params[:post_id]
				dbcooper = SQLite3::Database.new("db/forum.sqlite")
				list_all = dbcooper.execute("SELECT * FROM list")
				users_all = dbcooper.execute("SELECT * FROM users")
				comments_all = dbcooper.execute("SELECT * FROM comments") 
				poster_id = dbcooper.execute("SELECT id FROM users WHERE username=?", username)
				dbcooper.execute("INSERT INTO comments ('comment', 'poster_id', 'post_id') VALUES (?,?,?)", [comment, poster_id, post_id])
				redirect('/logged_in/'+title)
			end	
		else
			redirect('/fail')
		end
	end

	get('/friend_list/') do
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		dbcooper.results_as_hash = true
		friends_with = dbcooper.execute("SELECT * FROM relations WHERE user_1 = ? OR user_2 = ?", [session[:user_id], session[:user_id]])
		if session[:user]
			friends = []
			friends_with.each do |pair|
				pair.delete_if {|k,v| v.to_i == session[:user_id].to_i}
				friend_id = pair.first[1]
				p friend_id
				friend_name = dbcooper.execute("SELECT username FROM users WHERE id=?", [friend_id]).first["username"]
				p friend_name
				friends << {id:friend_id, name:friend_name}
			end
			p friends
			slim(:friend_list, locals:{friends: friends})
		else
			redirect('/fail')
		end
	end





	post('/logout') do
		session[:user] = nil
		redirect('/')
	end	
end
