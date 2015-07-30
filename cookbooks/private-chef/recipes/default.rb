topology = TopoHelper.new(ec_config: node['private-chef'])

puts "RECIPE RUN LIST"
puts 'private-chef::hostname'
puts 'private-chef::hostsfile'
puts 'private-chef::rhel'
puts 'private-chef::provision'
puts 'private-chef::bugfixes' if node['harness']['apply_ec_bugfixes'] == true
puts 'private-chef::drbd' if topology.is_backend?(node.name)
puts 'private-chef::provision_phase2'
puts 'private-chef::reporting' if node['harness']['reporting_package']
puts 'private-chef::manage' if node['harness']['manage_package'] &&
        topology.is_frontend?(node.name)
puts 'private-chef::pushy' if node['harness']['pushy_package']
puts 'private-chef::tools'
puts 'private-chef::loadbalancer' if topology.is_frontend?(node.name) &&
        node['harness']['provider'] == 'ec2'
puts "DONE RECIPE RUN LIST"

puts "INCLUDING RECIPES"
include_recipe 'private-chef::hostname'
include_recipe 'private-chef::hostsfile'
include_recipe 'private-chef::rhel'
include_recipe 'private-chef::provision'
include_recipe 'private-chef::bugfixes' if node['harness']['apply_ec_bugfixes'] == true
include_recipe 'private-chef::drbd' if topology.is_backend?(node.name)
include_recipe 'private-chef::provision_phase2'
include_recipe 'private-chef::reporting' if node['harness']['reporting_package']
include_recipe 'private-chef::manage' if node['harness']['manage_package'] &&
        topology.is_frontend?(node.name)
include_recipe 'private-chef::pushy' if node['harness']['pushy_package']
include_recipe 'private-chef::tools'
include_recipe 'private-chef::loadbalancer' if topology.is_frontend?(node.name) &&
        node['harness']['provider'] == 'ec2'
puts "DONE INCLUDING RECIPES"