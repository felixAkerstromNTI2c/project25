module Model
    
    def get_db()
      db = SQLite3::Database.new("db/database.db")
      db.results_as_hash = true
      return db
    end

    def before()
      if session[:id].nil?
        return false
      else
        return true
      end
    end

    def authorize_group_owner(group_id)
      db = get_db()
      result = db.execute("SELECT userid FROM 'group' WHERE id = ?", [group_id]).first
      return result && result['userid'] == session[:id]
    end

    def authorize_member_owner(member_id)
      return false if session[:id].nil?
      puts"Authorizing member owner with ID: #{member_id}"

      db = get_db()
      result = db.execute("
        SELECT \"group\".userid
        FROM group_members
        INNER JOIN \"group\" ON group_members.group_id = \"group\".id
        WHERE group_members.member_id = ?", [member_id]).first
      return result && result['userid'] == session[:id]
    end

    # result = db.execute("
    #   SELECT group.userid
    #   FROM group_members
    #   INNER JOIN 'group' ON group_members.group_id = group.id
    #   INNER JOIN member_names ON group_members.member_id = member_names.id
    #   WHERE member_names.id = ?", [member_id]).first
    #   return result && result['userid'] == session[:id]

    # Opens a connection to the SQLite3 database
    #
    # @return [SQLite3::Database] the database connection
    
  
    # Retrieves all classes for a given user
    #
    # @param [Integer] session_id, the ID of the logged-in user
    # @return [Array<Hash>] list of classes
    def show_classes(session_id)
      db = get_db()
      return db.execute("SELECT * FROM 'group' WHERE userid = #{session_id}")
    end
  
    # Retrieves user data for login validation
    #
    # @param [String] username, the entered username
    # @param [String] password, the entered password (unused here)
    # @return [Hash, nil] user row or nil
    def login_post(username, password)
      return db.execute("SELECT * FROM users WHERE name = (?)", [username]).first
    end
  
    # Retrieves all groups owned by the user
    #
    # @param [Integer] session_id, the ID of the logged-in user
    # @return [Array<Hash>] list of groups
    def add_class_member_get(session_id)
      db = get_db()
      db.execute("SELECT * FROM 'group' WHERE userid = #{session_id}")
    end
  
    # Creates a new class
    #
    # @param [Integer] userid, the ID of the user creating the class
    # @param [String] groupname, the name of the class
    def create_class(userid, groupname)
      db = get_db()
      db.execute("INSERT INTO 'group' (groupname, userid) VALUES (?, ?)", [groupname, userid])
    end
  
    # Retrieves all members of a specific class
    #
    # @param [Integer] group_id, the ID of the class
    # @return [Array<Hash>] list of members
    def show_class_members(group_id)
      db = get_db()
      return db.execute("SELECT * FROM 'member_names' WHERE id IN (SELECT member_id FROM 'group_members' WHERE group_id = ?)", [group_id])
    end
  
    # Adds a new class member and links them to the group
    #
    # @param [Integer] group_id, the ID of the group
    # @param [String] fullname, the full name of the new member
    def add_class_member_post(group_id, fullname)
      db = get_db()
      db.execute("INSERT INTO 'member_names' (fullname) VALUES (?)", [fullname])
      member_id = db.last_insert_row_id
      db.execute("INSERT INTO group_members (group_id, member_id) VALUES (?, ?)", [group_id, member_id])
    end
  
    # Deletes a class member from the group
    #
    # @param [Integer] id, the ID of the member to delete
    def delete_class_member(id)
      db = get_db()
      db.execute("DELETE FROM group_members WHERE member_id = ?", [id])
    end
  
    # Deletes a class and optionally its members
    #
    # @param [Integer] group_id, the ID of the class
    def delete_class(group_id)
      db = get_db()
  
      # Delete group-member relationships
      db.execute("DELETE FROM group_members WHERE group_id = ?", [group_id])
  
      # Optionally delete members (not safe if they belong to other groups!)
      db.execute("DELETE FROM member_names WHERE id IN (SELECT member_id FROM group_members WHERE group_id = ?)", [group_id])
  
      # Delete the class
      db.execute("DELETE FROM 'group' WHERE id = ?", [group_id])
    end
  
    # Gets the total number of users
    #
    # @return [Integer] number of users
    def get_amount_of_users()
      db = get_db()
      user_count = db.execute("SELECT COUNT(*) AS count FROM users").first['count']
      return user_count
    end
  
    # Gets the total number of groups
    #
    # @return [Integer] number of groups
    def get_amount_of_groups()
      db = get_db()
      group_count = db.execute("SELECT COUNT(*) AS count FROM 'group'").first['count']
      return group_count
    end
  
    # Gets the total number of members
    #
    # @return [Integer] number of members
    def get_amount_of_members()
      db = get_db()
      member_count = db.execute("SELECT COUNT(*) AS count FROM member_names").first['count']
      return member_count
    end
  
    # Gets all members joined with their class names for a user
    #
    # @param [Integer] session_id, the ID of the user
    # @return [Array<Hash>] list of member and class name pairs
    def inner_join_members(session_id)
      db = get_db()
      return db.execute("
        SELECT group.groupname, member_names.fullname
        FROM group_members
        INNER JOIN 'group' ON group_members.group_id = group.id
        INNER JOIN member_names ON group_members.member_id = member_names.id
        WHERE group.userid = ?", session_id)
    end
  
    # Gets only the fullnames of members in a specific group
    #
    # @param [Integer] group_id, the ID of the group
    # @return [Array<Hash>] list of member fullnames
    def select_members(group_id)
      db = get_db()
      return db.execute("SELECT fullname FROM member_names WHERE id IN (SELECT member_id FROM group_members WHERE group_id = ?)", [group_id])
    end
  
    # Gets full member rows for rendering a group
    #
    # @param [Integer] group_id, the ID of the group
    # @return [Array<Hash>] member data
    def render_members(group_id)
      db = get_db()
      return db.execute("SELECT * FROM member_names WHERE id IN (SELECT member_id FROM group_members WHERE group_id = ?)", [group_id])
    end
  
    # Creates a new user account
    #
    # @param [String] name, the desired username
    # @param [String] password_digest, the hashed password
    # @param [Integer] adminlevel, the user's permission level
    def new_account(name, password_digest, adminlevel)
      db = get_db()
      db.execute("INSERT INTO 'users' (name, pwdigest, adminlevel) VALUES (?, ?, ?)", [name, password_digest, adminlevel])
    end
  
    # Looks up a user by username
    #
    # @param [String] name, the username
    # @return [Hash, nil] user data or nil
    def select_names(name)
      db = get_db()
      return db.execute("SELECT * FROM users WHERE name = ?", [name]).first
    end
  
  end
  