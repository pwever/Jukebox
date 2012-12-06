require 'rubygems'
require 'sinatra'
require 'app.rb'

enable :logging, :dump_errors, :raise_errors

run Sinatra::Application
