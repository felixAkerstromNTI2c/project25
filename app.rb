require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

get('/') do
    slim(:start)
end

get('/login') do
    slim(:login)
end

get('/classes') do
    slim(:classes)
end

