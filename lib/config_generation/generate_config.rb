# This is a base class that's inherited from by other classes in the directory
# It creates a config file for ec-metal to consume and is driven by the 'generate_config' rake task
# It's behavior is modified by several env vars

class GenerateConfig

  def initialize(args, file_name)
    @options = args
    @config = {}
    modify_config()
    # TODO(jmink) Error handling?
    File.open(file_name, 'w') do |file|
      file.write JSON.pretty_generate @config
    end
  end


  def modify_config()
    set_provider_data()

    # TODO(jmink) handle upgrade packages correctly
    # TODO(jmink) Error handling
    @config["default_package"] = ENV['ECM_TARGET_PACKAGE_NAME']
    @config["manage_package"] = ENV['ECM_DEPENDENT_PACKAGE_NAME'] unless ENV['ECM_DEPENDENT_PACKAGE_NAME'].nil?

    @config[:packages] = {}
    set_topology()

    # TODO(jmink) Deal with any weird open source bits & ensure upgrade is set up correctly
  end

  def set_provider_data()
    raise "Unimplemented.  Should be overwritten in child class"
  end

  def set_topology()
    @config[:layout] = { :topology => @options.topology }
    case @options.topology
    when 'ha'
      generate_full_topology(:num_backends => 2, :num_frontends => 1)
    when 'standalone'
      # TOOD(jmink)
      generate_standalone_topology()
    when 'tier'
      generate_full_topology(:num_backends => 1, :num_frontends => 1)
    end
  end

  # adding this just to get something end to end in CI
  def generate_standalone_topology()
    name = 'pwcsta'
    # Define provider agnostic layout
    @config[:layout] = { :topology => @options.topology,
      :api_fqdn => 'api.opscode.aws',
      :manage_fqdn => 'manage.opscode.aws',
      :analytics_fqdn => 'analytics.opscode.aws',
      :standalones => {
        "#{name}-standalone" => {
          :hostname => "#{name}-standalone.centos.aws",
          :ebs_optimized => true,
          :instance_type => 'm3.xlarge'
        }
      }
    }
  end


  # Differences between HA & tiered:
  # HA has a seperate backend VIP
  # Tiered has a backend VIP section, which just points to the single backend

  # Lower priority:
  # Figure out how to get a unique ip for the backend VIP (HA only)
  # Irving has the most context on this (https://chef.leankit.com/Boards/View/97159481#workflow-view)

  # EC2 notes:
  # Look at example files for defaults
  # Think about using smaller instances/test (near term)
  # http://docs.getchef.com/enterprise/install_server_be.html

  def generate_full_topology(options)
    @config[:layout] = { :topology => @options.topology,
      :api_fqdn => 'api.opscode.piab',
      :manage_fqdn => 'manage.opscode.piab',
      :analytics_fqdn => 'analytics.opscode.piab',
      :backends => {},
      :frontends => {}
      }

      options[:num_backends].times do |n|
        backend = generate_backend(n)
        backend[:bootstrap] = true if n == 0
        @config[:layout][:backends]["backend#{n}"] = backend
      end

      options[:num_frontends].times do |n|
        @config[:layout][:frontends]["frontend#{n}"] = generate_frontend(n)
      end

      if options[:num_backends] > 1
        vip = { :hostname => "backend.opscode.piab",
                :ipaddress => "33.33.33.20" }
      else
        backend_name = @config[:layout][:backends].keys.first
        vip = @config[:layout][:backends][backend_name]
      end

      @config[:layout][:backend_vip] = {
        :hostname => vip[:hostname],
        :ipaddress => vip[:ipaddress],
        # TODO(jmink) figure out a smarter way to determine devices
        :device => "eth0",
        :heartbeat_device => "eth1"
       }

      provider_specific_config_modification()
  end

  # @returns a hash which represents the nth backend
  def generate_backend(n)
    raise "Unimplemented.  Should be overwritten in child class"
  end

  # @returns a hash which represents the nth frontend
  def generate_frontend(n)
    raise "Unimplemented.  Should be overwritten in child class"
  end

  # modifies @config in any way required for that specific provider
  def provider_specific_config_modification()
    raise "Unimplemented.  Should be overwritten in child class"
  end
end
