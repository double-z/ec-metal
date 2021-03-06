# encoding: utf-8
#
# Author:: Irving Popovetsky (<irving@getchef.com>)
# Copyright:: Copyright (c) 2014 Opscode, Inc.
#
# All Rights Reserved
#

topology = TopoHelper.new(ec_config: node['private-chef'])

package 'rsync'

execute 'rsync-from-bootstrap' do
  command "rsync -avz -e ssh --exclude chef-server-running.json root@#{topology.bootstrap_host_name}:/etc/opscode/ /etc/opscode"
  action :run
  not_if { node.name == topology.bootstrap_node_name }
end

# Intentionally bomb out before running reconfigure, so it can be done manually
if node['private-chef']['lemme_doit'] == true
  ruby_block 'p-c-c bomb' do
    block do
      exit 1
    end
    #only_if 'ls /tmp/private-chef-perform-upgrade'
  end
end


ruby_block 'p-c-c reconfigure' do
  block do
    begin
      tries ||= 2
      if node['osc-install']
        cmd = Mixlib::ShellOut.new('/opt/chef-server/bin/chef-server-ctl reconfigure', live_stream: STDOUT)
      else
        cmd = Mixlib::ShellOut.new('/opt/opscode/bin/private-chef-ctl reconfigure', live_stream: STDOUT)
      end
      cmd.run_command
      if cmd.error?
        cmd.error!
      else
        ::File.open("/var/log/p-c-c-reconfigure-#{Time.now.strftime("%Y%m%d_%H%M%S")}.log", 'w') { |lf| lf.write(cmd.stdout) }
        puts '--- BEGIN private-chef-ctl reconfigure output ---'
        puts cmd.stdout
        puts '--- END private-chef-ctl reconfigure output ---'
      end
    rescue Exception => e
      ::File.open("/var/log/p-c-c-reconfigure-#{Time.now.strftime("%Y%m%d_%H%M%S")}.log", 'w') { |lf| lf.write(cmd.stdout) }
      puts "#{e} Previous private-chef-ctl reconfigure failed, sleeping for 30 and trying again"
      sleep 30
      unless (tries -= 1).zero?
        retry
      else
        raise 'private-chef-ctl reconfigure failed and retries exceeded'
      end
    end
  end
  # Contentious change, but we should no longer baby the upgrade process:
  not_if 'ls /tmp/private-chef-perform-upgrade'
  not_if { node['osc-upgrade'] }
  notifies :create, 'wait_for_ha_master[p-c-c reconfigure]', :immediately if topology.is_ha?
  notifies :create, 'wait_for_server_ready[p-c-c reconfigure]', :immediately
end

wait_for_ha_master 'p-c-c reconfigure' do
  action :nothing
  only_if { node.name == topology.bootstrap_node_name }
end

wait_for_server_ready 'p-c-c reconfigure' do
  action :nothing
  only_if { node.name == topology.bootstrap_node_name }
  not_if 'ls /tmp/private-chef-perform-upgrade'
end

# OC-11297
execute 'fix-migration-state' do
  command '/opt/opscode/embedded/bin/bundle exec bin/partybus init'
  cwd '/opt/opscode/embedded/service/partybus'
  environment 'PATH' => '/opt/opscode/embedded/bin:/bin:/sbin:/usr/bin:/usr/sbin'
  action :run
  not_if 'ls /var/opt/opscode/upgrades/migration-level'
  not_if 'ls /tmp/private-chef-perform-upgrade'
  not_if { node['osc-install'] || node['osc-upgrade'] }
end

# Analytics file copy needed on EC11.1.8 and older
execute 'copy-webui_priv.pem' do
  command 'cp /etc/opscode/webui_priv.pem /etc/opscode-analytics'
  action :run
  only_if { node['private-chef']['analytics_installer_file'] }
  not_if 'test -f /etc/opscode-analytics/webui_priv.pem'
  not_if { node['osc-install'] || node['osc-upgrade'] }
end

# If anything is still down, wait for things to settle
log "Running upgrades for #{node.name}, bootstrap is #{topology.bootstrap_node_name}" do
  only_if { File.exists?('/tmp/private-chef-perform-upgrade') }
  not_if { node['osc-install'] || node['osc-upgrade'] }
end

# after 1.2->1.4 upgrade postgresql won't be running, but WHY?
execute 'p-c-c-start' do
  command '/opt/opscode/bin/private-chef-ctl start postgresql'
  action :run
  only_if { node.name == topology.bootstrap_node_name }
  only_if '/opt/opscode/bin/private-chef-ctl status | grep postgres | grep ^down'
  only_if 'ls /tmp/private-chef-perform-upgrade'
  not_if { node['osc-install'] || node['osc-upgrade'] }
  retries 1
end

# per https://github.com/opscode/chef-docs/pull/428
execute 'stop_service_on_bootstrap_ec11_to_cs12_upgrade' do
  command '/opt/opscode/bin/chef-server-ctl stop'
  action :run
  only_if { node.name == topology.bootstrap_node_name }
  only_if 'ls /tmp/private-chef-perform-upgrade'
  only_if 'ls /tmp/upgrading_ec11_to_cs12'
end

ruby_block 'p-c-c upgrade' do
  block do
    begin
      tries ||= 2
      cmd = Mixlib::ShellOut.new('/opt/opscode/bin/private-chef-ctl upgrade', live_stream: STDOUT)
      cmd.run_command
      if cmd.error?
        cmd.error!
      else
        ::File.open("/var/log/p-c-c-upgrade-#{Time.now.strftime("%Y%m%d_%H%M%S")}.log", 'w') { |lf| lf.write(cmd.stdout) }
        puts '--- BEGIN private-chef-ctl upgrade output ---'
        puts cmd.stdout
        puts '--- END private-chef-ctl upgrade output ---'
      end
    rescue Exception => e
      ::File.open("/var/log/p-c-c-upgrade-#{Time.now.strftime("%Y%m%d_%H%M%S")}.log", 'w') { |lf| lf.write(cmd.stdout) }
      puts "#{e} Previous private-chef-ctl upgrade failed, sleeping for 30 and trying again"
      sleep 30
      unless (tries -= 1).zero?
        retry
      else
        raise 'private-chef-ctl upgrade failed and retries exceeded'
      end
    end
  end
  only_if 'ls /tmp/private-chef-perform-upgrade'
  not_if { node['osc-install'] || node['osc-upgrade'] }
  notifies :create, "wait_for_ha_master[p-c-c upgrade]", :immediately if topology.is_ha?
end

wait_for_ha_master 'p-c-c upgrade' do
  action :nothing
  only_if { node.name == topology.bootstrap_node_name }
  notifies :run, "execute[start_services_on_bootstrap_ec11_to_cs12_upgrade]", :immediately
end

# restart services which are still stopped
execute 'start_services_on_bootstrap_ec11_to_cs12_upgrade' do
  command '/opt/opscode/bin/chef-server-ctl start'
  action :run
  only_if { node.name == topology.bootstrap_node_name }
  only_if 'ls /tmp/private-chef-perform-upgrade'
  only_if 'ls /tmp/upgrading_ec11_to_cs12'
  notifies :create, "wait_for_server_ready[p-c-c upgrade]", :immediately
end

wait_for_server_ready 'p-c-c upgrade' do
  action :nothing
  only_if { node.name == topology.bootstrap_node_name }
end


ruby_block 'p-c-c osc upgrade' do
  block do
    begin
      tries ||= 2
      cmd = Mixlib::ShellOut.new('yes | /opt/opscode/bin/private-chef-ctl upgrade', live_stream: STDOUT)
      cmd.run_command
      if cmd.error?
        cmd.error!
      else
        ::File.open("/var/log/p-c-c-upgrade-#{Time.now.strftime("%Y%m%d_%H%M%S")}.log", 'w') { |lf| lf.write(cmd.stdout) }
        puts '--- BEGIN private-chef-ctl upgrade output ---'
        puts cmd.stdout
        puts '--- END private-chef-ctl upgrade output ---'
      end
    rescue Exception => e
      ::File.open("/var/log/p-c-c-upgrade-#{Time.now.strftime("%Y%m%d_%H%M%S")}.log", 'w') { |lf| lf.write(cmd.stdout) }
      puts "#{e} Previous private-chef-ctl upgrade failed, sleeping for 30 and trying again"
      sleep 30
      unless (tries -= 1).zero?
        retry
      else
        raise 'private-chef-ctl upgrade failed and retries exceeded'
      end
    end
  end
  only_if { node['osc-upgrade'] }
end

execute 'p-c-c-cleanup' do
  command '/opt/opscode/bin/private-chef-ctl cleanup'
  action :run
  only_if 'ls /tmp/private-chef-perform-upgrade'
  case node['platform_family']
  when 'rhel'
    only_if 'rpm -q private-chef |grep private-chef-11'
  when 'debian'
    only_if 'dpkg -l |grep private-chef.*11'
  end
  not_if { node['osc-install'] }
end

file '/tmp/private-chef-perform-upgrade' do
  action :delete
end

file '/tmp/upgrading_ec11_to_cs12' do
  action :delete
end
