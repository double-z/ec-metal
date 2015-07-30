# encoding: utf-8
# in clusters stands up the remaining backends and frontends in parallel

context = ChefDK::ProvisioningData.context

include_recipe "ec-harness::#{node['harness']['provider']}"

machine_batch 'remaining_ec_servers' do
  action [:converge]

  ecm_topo_chef.merged_topology.each do |vmname, config|

    # skip the bootstrap node in this batch
    next if vmname == ecm_topo_chef.bootstrap_node_name

    # puts "=================================================="
    # puts "=================================================="
    # puts "=================================================="
    # puts "VMNAME: #{vmname}"
    # pp "CONFIG:"
    # pp " #{config}"
    # puts "=================================================="
    # puts "=================================================="
    # puts "=================================================="
    # puts "ec_config"
    # pp ecm_topo_chef.ec_config
    # puts "=================================================="
    # puts "=================================================="
    # puts "=================================================="
    # puts "include"
    # pp ecm_topo_chef.include_layers
    # puts "=================================================="
    # puts "=================================================="
    # puts "=================================================="
    # puts "privatechef_attributes"
    # pp privatechef_attributes
    # puts "=================================================="
    # puts "=================================================="
    # puts "=================================================="

    machine vmname do
      machine_options machine_options_for_provider(vmname, config)
      attribute 'private-chef', privatechef_attributes
      attribute 'root_ssh', node['harness']['root_ssh'].to_hash
      attribute 'osc-install', node['harness']['osc_install']
      attribute 'osc-upgrade', node['harness']['osc_upgrade']
      attribute 'harness', node['harness']
      add_machine_options(
        convergence_options: context.convergence_options
      )
      recipe 'private-chef::default'
      # recipe 'private-chef::hostname'
      # recipe 'private-chef::hostsfile'
      # recipe 'private-chef::rhel'
      # recipe 'private-chef::provision'
      # recipe 'private-chef::bugfixes' if node['harness']['apply_ec_bugfixes'] == true
      # recipe 'private-chef::drbd' if ecm_topo_chef.is_backend?(vmname)
      # recipe 'private-chef::provision_phase2'
      # recipe 'private-chef::reporting' if node['harness']['reporting_package']
      # recipe 'private-chef::manage' if node['harness']['manage_package'] &&
      #   ecm_topo_chef.is_frontend?(vmname)
      # recipe 'private-chef::pushy' if node['harness']['pushy_package']
      # recipe 'private-chef::tools'
      # recipe 'private-chef::loadbalancer' if ecm_topo_chef.is_frontend?(vmname) &&
      #   node['harness']['provider'] == 'ec2'

      converge true
    end
  end
end
