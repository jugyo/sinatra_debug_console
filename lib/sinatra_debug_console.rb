# = sinatra_debug_console
#
# Debug console for sinatra
#
# == Notice
#
# Rack::Auth::Basic is used to authorization.
#
# == Usage
#
#     require 'sinatra_debug_console'
#     Sinatra::DebugConsole.config('admin', 'password')

get '/debug_console' do
  require_administrative_privileges
  haml <<HAML, :layout => false
%html
  %head
    %meta{:"http-equiv"=>"Content-Type", :content=>"text/html;charset=UTF-8"}
    %title console
    %script{:type=>"text/javascript", :src=>"http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"}
  %body
    #eval_text
      %textarea#text{:rows => 10, :style => 'width: 100%;'}
    #button
      %button{:onclick => 'eval_text()'} eval
    %pre#result{:style => 'color: green; background-color: black; padding: 8px; display: none;'}
    :javascript
      $(document).ready(function() {
        $("#text").focus();
      });

      function eval_text() {
        $("#result").show();
        $("#result").html('...');
        $("#result").load('/debug_console', {text: $('#text').val()});
      }
HAML
end

post '/debug_console' do
  require_administrative_privileges
  begin
    eval(params[:text]).inspect
  rescue Exception => e
    ([e.message] + e.backtrace).join("\n")
  end
end

module Sinatra
  module DebugConsole
    class << self
      def config(username, password)
        @username = username
        @password = password
      end

      def username
        @username
      end

      def password
        @password
      end
    end

    module Authorization

      def auth
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
      end

      def unauthorized!(realm = "sinatra_debug_console")
        header 'WWW-Authenticate' => %(Basic realm="#{realm}")
        throw :halt, [ 401, 'Authorization Required' ]
      end

      def bad_request!
        throw :halt, [ 400, 'Bad Request' ]
      end

      def authorized?
        request.env['REMOTE_USER']
      end

      def authorize(username, password)
        username == DebugConsole.username && password == DebugConsole.password
      end

      def require_administrative_privileges
        return if authorized?
        unauthorized! unless auth.provided?
        bad_request! unless auth.basic?
        unauthorized! unless authorize(*auth.credentials)
        request.env['REMOTE_USER'] = auth.username
      end

      def admin?
        authorized?
      end
    end
  end
end

include Sinatra::DebugConsole::Authorization
