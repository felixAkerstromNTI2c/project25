require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

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
  	db = SQLite3::Database.new("db/database.db")
	db.results_as_hash = true
	groups = db.execute("SELECT * FROM 'group' WHERE userid = #{session[:id]}")

    slim(:"classes/index", locals:{groups:groups})
end

get('/classes/new') do
    slim(:"classes/new")
end

post('/classes/new') do
	userid = session[:id]
	groupname = params[:groupname]
	db = SQLite3::Database.new("db/database.db")
	db.execute("INSERT INTO 'group' (groupname, userid) VALUES (?,?)", [groupname,userid])
	redirect('/classes')
end

post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new('db/database.db')
    db.results_as_hash = true
    #result = db.execute("SELECT * FROM 'users'")
    #p result
    #p username
    result = db.execute("SELECT * FROM users WHERE name = (?)",[username]).first
    #p result
    pwdigest = result["pwdigest"]
    id = result["id"]
  
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/classes')
    else
      "WRONG PASSWORD!"
    end
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