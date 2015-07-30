# stands up the bootstrap host or only host in Standalone configurations
context = ChefDK::ProvisioningData.context

include_recipe "ec-harness::#{node['harness']['provider']}"

machine_batch 'bootstrap_node' do
  action [:converge]

  # Only do the bootstrap node in this batch
  ecm_topo_chef.merged_topology.select { |k,v| k == ecm_topo_chef.bootstrap_node_name }.each do |vmname, config|

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
