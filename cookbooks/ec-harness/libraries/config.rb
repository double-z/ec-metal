require 'fileutils'
require 'securerandom'

# Manages configuration
class Provisioner
  module Config

    def self.load_running_from_json!(filename, node)
      # create_directory!(filename)
      if File.exist?(filename)
        data = Chef::JSONCompat.from_json(open(filename).read)
        # puts data.inspect
        node.consume_attributes(
          'harness' => data['harness']
        )
      end
    rescue => e
      Chef::Log.warn "Could not read attributes from #{filename}: #{e}"
    end
  end
end
