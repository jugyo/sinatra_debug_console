# % ruby app.rb
# see http://localhost:4567/debug_console

require 'sinatra'
require 'sinatra_debug_console'
Sinatra::DebugConsole.config('admin', 'password')
