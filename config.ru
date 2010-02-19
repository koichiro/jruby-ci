require 'appengine-rack'
AppEngine::Rack.configure_app(          
    :application => "jruby-ci",           
    :precompilation_enabled => true,
    :version => "1")
#run lambda { Rack::Response.new("Hello").finish }
require 'jrubyci'
run Sinatra::Application
