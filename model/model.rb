# get db
def get_db()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    return db
end

def show_classes(session_id)
    db = get_db()
    return db.execute("SELECT * FROM 'group' WHERE userid = #{session_id}")
end

def login_post(username, password)
    return db.execute("SELECT * FROM users WHERE name = (?)", [username]).first
end

# users
def add_class_member_get(session_id)
    db.execute("SELECT * FROM 'group' WHERE userid = #{session_id}")
end

# classes
def create_class(userid, groupname)
    db = get_db()
	db.execute("INSERT INTO 'group' (groupname, userid) VALUES (?,?)", [groupname,userid])
end

def show_class_members(group_id)
    db = get_db()
    
    return db.execute("SELECT * FROM 'member_names' WHERE id IN (SELECT member_id FROM 'group_members' WHERE group_id = ?)", [group_id])


end
# members
def add_class_member_post(group_id, fullname)
  db = get_db()
  db.execute("INSERT INTO 'member_names' (fullname) VALUES (?)", [fullname])
  member_id = db.last_insert_row_id
  db.execute("INSERT INTO group_members (group_id, member_id) VALUES (?, ?)", [group_id, member_id])
end

def delete_class_member(id)
    db = get_db()
  
  # Delete the member from the group_members table
  db.execute("DELETE FROM group_members WHERE member_id = ?", [id])
end

def delete_class(group_id)
    db = get_db()

  # Delete all relationships in the group_members table
  db.execute("DELETE FROM group_members WHERE group_id = ?", [group_id])

  # Optionally, delete all members associated with the group
  db.execute("DELETE FROM member_names WHERE id IN (SELECT member_id FROM group_members WHERE group_id = ?)", [group_id])

  # Delete the class itself
  db.execute("DELETE FROM 'group' WHERE id = ?", [group_id])
end

def get_amount_of_users()
    db = get_db()
    user_count = db.execute("SELECT COUNT(*) AS count FROM users").first['count']
    return user_count
end

def get_amount_of_groups()
    db = get_db()
    group_count = db.execute("SELECT COUNT(*) AS count FROM 'group'").first['count']
    return group_count
end

def inner_join_members(session_id)
    db = get_db()
    # Perform an inner join to get group names and member names
    return db.execute("
    SELECT group.groupname, member_names.fullname
    FROM group_members
    INNER JOIN 'group' ON group_members.group_id = group.id
    INNER JOIN member_names ON group_members.member_id = member_names.id
    WHERE group.userid = ?", session_id)
end


def get_amount_of_members()
    db = get_db()
    member_count = db.execute("SELECT COUNT(*) AS count FROM member_names").first['count']
    return member_count
end

def select_members(group_id)
    db = get_db()
    return db.execute("SELECT fullname FROM member_names WHERE id IN (SELECT member_id FROM group_members WHERE group_id = ?)", [group_id])
end

def render_members(group_id)
    db = get_db()
    return db.execute("SELECT * FROM member_names WHERE id IN (SELECT member_id FROM group_members WHERE group_id = ?)", [group_id])
end
