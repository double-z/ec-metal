require 'sinatra'

configure do
	  set :bind, '0.0.0.0'
end

$stdout.sync = true

get '/run' do
  content_type :txt
  IO.popen('/usr/bin/chef-provisioner-ctl provision_chef_platform')
end
