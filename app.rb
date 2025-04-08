require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'model/model.rb'
also_reload 'model/model.rb'

enable :sessions


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
  session_id = session[:id]

	groups = show_classes(session_id)
  slim(:"classes/index", locals:{groups:groups})
end

get('/classes/show/:id') do
  group_id = params[:id]
  members = show_class_members(group_id)
  slim(:"classes/show", locals: {members: members, group_id: group_id})
end

get('/class_members') do
  session_id = session[:id]
  db = get_db()
  
  members = inner_join_members(session_id) 
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

post('/classes/create') do
	userid = session[:id]
	groupname = params[:groupname]
	create_class(userid, groupname)
	redirect('/classes')
end

get('/class_members/new') do
  db = get_db()
  session_id =session[:id]
  groups = add_class_member_get(session_id)
  slim(:"class_members/new", locals:{groups:groups})
end

post('/class_members/create') do
  group_id = params[:group_id]
  fullname = params[:fullname]
  add_class_member_post(group_id, fullname)
  redirect("/classes/show/#{group_id}")
end

post('/class_members/:id/delete') do
  member_id = params[:id]
  group_id = params[:group_id] 
  delete_class_member(member_id)
  redirect("/classes/show/#{group_id}")
end

post('/classes/:id/delete') do
  group_id = params[:id]
  delete_class(group_id)
  redirect('/classes')
end


post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true

  session[:login_attempts] ||= 0
  session[:last_attempt_time] ||= Time.now

  # Check if the user needs to wait before trying again
  if session[:login_attempts] >= 3 && Time.now - session[:last_attempt_time] < 30
    return "Too many failed attempts. Please wait #{30 - (Time.now - session[:last_attempt_time]).to_i} seconds before trying again."
  end

  result = db.execute("SELECT * FROM users WHERE name = (?)", [username]).first

  if result.nil?
    session[:login_attempts] += 1
    session[:last_attempt_time] = Time.now
    "WRONG USERNAME!"
  else
    pwdigest = result["pwdigest"]
    id = result["id"]

    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      session[:username] = username
      session[:adminlevel] = result["adminlevel"]
      session[:login_attempts] = 0 # Reset attempts on successful login
      redirect('/classes')
    else
      session[:login_attempts] += 1
      session[:last_attempt_time] = Time.now
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

  db = SQLite3::Database.new('db/database.db')
  db.results_as_hash = true
  existing_user = db.execute("SELECT * FROM users WHERE name = ?", [name]).first

  if existing_user
    "Username already exists!"
  elsif password == password_confirm
    adminlevel = 2 if name == "admin"
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO 'users' (name, pwdigest, adminlevel) VALUES (?, ?, ?)", [name, password_digest, adminlevel])
    redirect('/')
  else
    "Passwords do not match! #{password} #{password_confirm}"
  end
end

get('/stats') do
  if session[:adminlevel] != 2
    redirect('/')
  end
  account_count = get_amount_of_users() # db.execute("SELECT COUNT(*) AS count FROM users").first['count']
  group_count = get_amount_of_groups() # db.execute("SELECT COUNT(*) AS count FROM 'group'").first['count']
  member_count = get_amount_of_members() #db.execute("SELECT COUNT(*) AS count FROM member_names").first['count']
  slim(:stats, locals: { account_count: account_count, group_count: group_count, member_count: member_count })
end

post('/classes/:id/random_name') do
  group_id = params[:id]
  db = get_db()
  # Fetch all members of the class
  members = select_members(group_id) 

  # Select a random member
  if members.any?
    random_member = members.sample['fullname']
  else
    random_member = 'No members in this class.'
  end

  # Render the same page with the random name
  members = render_members(group_id)
  slim(:"classes/show", locals: { members: members, group_id: group_id, random_member: random_member })
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