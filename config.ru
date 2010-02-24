require 'appengine-rack'
AppEngine::Rack.configure_app(          
    :application => "jruby-ci",           
    :precompilation_enabled => true,
    :version => "2")
require 'jrubyci'
run Sinatra::Application
