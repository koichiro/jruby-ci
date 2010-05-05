require 'appengine-rack'
AppEngine::Rack.configure_app(          
    :application => "jruby-ci",           
    :precompilation_enabled => true,
    :version => "4")
require 'jrubyci'
run Sinatra::Application
