module Users
    def self.get_friends(user_id)
        dbcooper = SQLite3::Database.new("db/forum.sqlite")
		dbcooper.results_as_hash = true
		friends_with = dbcooper.execute("SELECT * FROM relations WHERE user_1 = ? OR user_2 = ?", [user_id, user_id])
			friends = []
			friends_with.each do |pair|
				pair.delete_if {|k,v| v.to_i == user_id.to_i}
				friend_id = pair.first[1]
				friend_name = dbcooper.execute("SELECT username FROM users WHERE id=?", [friend_id]).first["username"]
				friends << {id:friend_id, name:friend_name}
            end
            return friends
        end
    end