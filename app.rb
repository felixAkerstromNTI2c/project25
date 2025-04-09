require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require_relative 'model/model.rb'
also_reload 'model/model.rb'
include Model

enable :sessions

# Displays the start page
get('/') do
    slim(:start)
end

# Displays the account creation form
get('/create_account') do
    slim(:register)
end

# Displays the login form
get('/login') do
    slim(:login)
end

# Displays all classes that belong to the logged-in user
#
# @see Model#show_classes
get('/classes') do
  session_id = session[:id]

	groups = show_classes(session_id)
  slim(:"classes/index", locals:{groups:groups})
end

# Displays members of a specific class
#
# @param [Integer] :id, the ID of the class
# @see Model#show_class_members
get('/classes/show/:id') do
  group_id = params[:id]
  members = show_class_members(group_id)
  slim(:"classes/show", locals: {members: members, group_id: group_id})
end

# Displays class members using an inner join with current user’s classes
#
# @see Model#inner_join_members
get('/class_members') do
  session_id = session[:id]
  db = get_db()
  
  members = inner_join_members(session_id) 
  slim(:"class_members/index", locals: { members: members })
end

# Displays the form for creating a new class
get('/classes/new') do
    slim(:"classes/new")
end


# Handles creation of a new class
#
# @see Model#create_class
post('/classes/create') do
	userid = session[:id]
	groupname = params[:groupname]
	create_class(userid, groupname)
	redirect('/classes')
end

# Displays form for adding a new class member
#
# @see Model#add_class_member_get
get('/class_members/new') do
  db = get_db()
  session_id =session[:id]
  groups = add_class_member_get(session_id)
  slim(:"class_members/new", locals:{groups:groups})
end

# Handles creation of a new class member
#
# @param [Integer] :group_id, the ID of the group
# @param [String] :fullname, the name of the new member
# @see Model#add_class_member_post
post('/class_members/create') do
  group_id = params[:group_id]
  fullname = params[:fullname]
  add_class_member_post(group_id, fullname)
  redirect("/classes/show/#{group_id}")
end

# Deletes a class member
#
# @param [Integer] :id, the ID of the member
# @param [Integer] :group_id, the ID of the group the member belongs to
# @see Model#delete_class_member
post('/class_members/:id/delete') do
  member_id = params[:id]
  group_id = params[:group_id] 
  delete_class_member(member_id)
  redirect("/classes/show/#{group_id}")
end

# Deletes a class
#
# @param [Integer] :id, the ID of the class
# @see Model#delete_class
post('/classes/:id/delete') do
  group_id = params[:id]
  delete_class(group_id)
  redirect('/classes')
end

# Handles user login
#
# @param [String] :username, the entered username
# @param [String] :password, the entered password
# @see Model#select_names
post('/login') do
  username = params[:username]
  password = params[:password]
  db = get_db()

  session[:login_attempts] ||= 0
  session[:last_attempt_time] ||= Time.now

  
  if session[:login_attempts] >= 2 && Time.now - session[:last_attempt_time] < 10
    return "Too many failed attempts. Please wait #{10 - (Time.now - session[:last_attempt_time]).to_i} seconds before trying again."
  end

  result = select_names(username) 

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
      session[:login_attempts] = 0
      redirect('/classes')
    else
      session[:login_attempts] += 1
      session[:last_attempt_time] = Time.now
      "WRONG PASSWORD!"
    end
  end
end

# Logs the user out and clears the session
get('/logout') do
  session.clear
  redirect('/')
end
  
# Handles account creation
#
# @param [String] :username, the desired username
# @param [String] :password, the password
# @param [String] :confirm_password, confirmation of the password
# @see Model#new_account
# @see Model#select_names
post('/create_account') do
  adminlevel = 1
  name = params[:username]
  password = params[:password]
  password_confirm = params[:confirm_password]

  db = get_db()
  existing_user = select_names(name)

  if existing_user
    "Username already exists!"
  elsif password == password_confirm
    adminlevel = 2 if name.include?("admin")
    password_digest = BCrypt::Password.create(password)
    new_account(name, password_digest, adminlevel)
    redirect('/')
  else
    "Passwords do not match! #{password} #{password_confirm}"
  end
end

# Displays statistics about accounts, groups, and members
#
# Only accessible to admin users
# @see Model#get_amount_of_users
# @see Model#get_amount_of_groups
# @see Model#get_amount_of_members
get('/stats') do
  if session[:adminlevel] != 2
    redirect('/')
  end
  account_count = get_amount_of_users() 
  group_count = get_amount_of_groups() 
  member_count = get_amount_of_members() 
  slim(:stats, locals: { account_count: account_count, group_count: group_count, member_count: member_count })
end

# Picks a random member from a class and redisplays the class page
#
# @param [Integer] :id, the ID of the class
# @see Model#select_members
post('/classes/:id/random_name') do
  group_id = params[:id]
  db = get_db()

  members = select_members(group_id) 

  if members.any?
    random_member = members.sample['fullname']
  else
    random_member = 'No members in this class.'
  end

  members = render_members(group_id)
  slim(:"classes/show", locals: { members: members, group_id: group_id, random_member: random_member })
end

