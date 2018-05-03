require 'sinatra'
require 'open-uri'
require 'json'
require 'addressable'
require 'uri'
require 'sqlite3'
require 'bcrypt'
require 'slim'
require_relative 'modules.rb'

#class App < Sinatra::Base
	enable :sessions
	include Users

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
			slim(:logged_in, locals:{ list_all: list_all, users_all: users_all, username:username})
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
			commenter_id = dbcooper.execute("SELECT poster_id FROM comments WHERE post_id=?", post_id)
			poster_id = dbcooper.execute("SELECT id FROM users WHERE username=?", username)
			slim(:post, locals:{ list_all: list_all, users_all: users_all, comments_all:comments_all, post_id: post_id, poster_id:poster_id, comments:comments, commenter_id:commenter_id, username:username})
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
		username = session[:user]
		if session[:user]
			friends = Users::get_friends(session[:user_id])
			new_friend = 1
			session[:friends] = friends
			slim(:friend_list, locals:{friends: friends, new_friend:new_friend, username:username})
		else
			redirect('/fail')
		end
	end

	post('/search') do
		friends = session[:friends]
		username = params["username"]
		if username == session[:user]
			redirect('/fail')
		else
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		new_friend = dbcooper.execute("SELECT username FROM users WHERE username =?",[username])
		username = session[:user]
		slim(:friend_list, locals:{friends:friends, new_friend:new_friend, username:username})
		end
	end

	post('/add') do
		added_friend = params[:added_friend]
		friends = Users::get_friends(session[:user_id])
		friends.each do |friend|
					p added_friend
					p friend[:name]	
					if added_friend.to_s == friend[:name].to_s
						redirect('/fail')
						return
					end
				end
		dbcooper = SQLite3::Database.new("db/forum.sqlite")
		added_friend_id = dbcooper.execute("SELECT id FROM users WHERE username =?",[added_friend])
		dbcooper.execute("INSERT INTO relations ('user_1', 'user_2') VALUES (?,?)", [session[:user_id], added_friend_id])
		new_friend = 1
		redirect('/friend_list/')
	end




	post('/logout') do
		session[:user] = nil
		redirect('/')
	end	
#end
