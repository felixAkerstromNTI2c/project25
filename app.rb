require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

def get_db()
  db = SQLite3::Database.new("db/database.db")
  db.results_as_hash = true
  return db
end

get('/') do
    slim(:start)
end

get('/create_account') do
    slim(:register)
end

get('/login') do
    slim(:login)
end

get('/classes') do
  db = get_db()
	
	groups = db.execute("SELECT * FROM 'group' WHERE userid = #{session[:id]}")

  slim(:"classes/index", locals:{groups:groups})
end

get('/classes/show/:id') do
  group_id = params[:id]
  db = get_db()
  
  members = db.execute("SELECT * FROM 'member_names' WHERE id IN (SELECT member_id FROM 'group_members' WHERE group_id = ?)", [group_id])
  slim(:"classes/show", locals: {members: members, group_id: group_id})
end

get('/class_members') do
  db = get_db()
  
  members = db.execute("
    SELECT group.groupname, member_names.fullname
    FROM group_members
    INNER JOIN 'group' ON group_members.group_id = group.id
    INNER JOIN member_names ON group_members.member_id = member_names.id
    WHERE group.userid = ?", [session[:id]])
  slim(:"class_members/index", locals: { members: members })
  #members = db.execute("SELECT * FROM 'member_names'") # Realtionstabellen mellan grupper och medlemmar är inte implementerad i databasen än.
  # members = db.execute("SELECT * FROM 'member_names' INNER JOIN 'group' ON member_names.id = group.id WHERE group.userid = #{session[:id]}")
  # slim(:"class_members/index", locals:{members:members})
end

get('/classes/new') do
    slim(:"classes/new")
end

get('/classes/edit') do
  slim(:"classes/edit")
end

get('/class_members/show/:id') do

end

post('/classes/create') do
	userid = session[:id]
	groupname = params[:groupname]
	db = get_db()
	db.execute("INSERT INTO 'group' (groupname, userid) VALUES (?,?)", [groupname,userid])
	redirect('/classes')
end

get('/class_members/new') do
  db = get_db()
  
  groups = db.execute("SELECT * FROM 'group' WHERE userid = #{session[:id]}")
  slim(:"class_members/new", locals:{groups:groups})
end

post('/class_members/create') do
  group_id = params[:group_id]
  # member_id = params[:memberid]
  fullname = params[:fullname]
  # id = params[:groupid]
  db = get_db()
  db.execute("INSERT INTO 'member_names' (fullname) VALUES (?)", [fullname])
  # Get the last inserted class_member_id
  member_id = db.last_insert_row_id

  # Insert the relationship into the junction table
  db.execute("INSERT INTO group_members (group_id, member_id) VALUES (?, ?)", [group_id, member_id])
  redirect("/classes/show/#{group_id}")
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE name = (?)", [username]).first

  if result.nil?
    "WRONG USERNAME!"
  else
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:username] = username
      redirect('/classes')
    else
      "WRONG PASSWORD!"
    end
  end
end

get('/logout') do
  session.clear
  redirect('/')
end
  

post('/create_account') do
  adminlevel = 1
  name = params[:username]
  password = params[:password]
  password_confirm = params[:confirm_password]
  if password == password_confirm
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/database.db')
    db.execute("INSERT INTO 'users' (name,pwdigest,adminlevel) VALUES (?,?,?)",[name, password_digest,adminlevel])
    redirect('/')
  else
    
    "Lösenorden matchade inte! #{password} #{password_confirm}"
  end
end



get('/group/:id') do



end



# username = params["username"]
# password = params["password"]
# pasword_confirmation = params["confirm_password"]

# result = db.execute("SELECT id FROM users WHERE name=?", name)

# if result.empty?
# if password == confirm_password
#     pwdigest = BCrypt::password.create(password)
#     p password_digest
#     db.execute("INSERT INTO 'users' (username, pwdigest) VALUES (?,?)", [username, pwdigest])
#     redirect("/")
# else
#     set_error("Passwords don't match")
#     redirect("/error")
# end
# else
# set_error("/Username alreaady exists")
# redirect("/error")
# end