# in clusters stands up the remaining backends and frontends in parallel

context = ChefDK::ProvisioningData.context

include_recipe "ec-harness::#{node['harness']['provider']}"

machine_batch 'remaining_ec_servers' do
  action [:converge]

  ecm_topo_chef.merged_topology.each do |vmname, config|

    # skip the bootstrap node in this batch
    next if vmname == ecm_topo_chef.bootstrap_node_name

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
      converge true
    end
  end
end
