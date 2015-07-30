# Policyfile.rb - Describe how you want Chef to build your system.
#
# For more information on the Policyfile feature, visit
# https://github.com/opscode/chef-dk/blob/master/POLICYFILE_README.md

# A name that describes what the system you're building with Chef does.
name "private-chef"

# Where to find external cookbooks:
default_source :community

# run_list: chef-client will run these recipes in the order specified.
run_list "private-chef::default"

# Specify a custom source for a single cookbook:
# cookbook "development_cookbook", path: "../cookbooks/development_cookbook"
cookbook "private-chef", path: "./cookbooks/private-chef"
cookbook "ec-common", path: "./cookbooks/ec-common"
cookbook "apt", path: "./vendor/cookbooks/apt"
cookbook "aws", path: "./vendor/cookbooks/aws"
cookbook "chef-client", path: "./vendor/cookbooks/chef-client"
cookbook "chef_handler", path: "./vendor/cookbooks/chef_handler"
cookbook "cron", path: "./vendor/cookbooks/cron"
cookbook "docker", path: "./vendor/cookbooks/docker"
cookbook "ec-tools", path: "./vendor/cookbooks/ec-tools"
cookbook "hostsfile", path: "./vendor/cookbooks/hostsfile"
cookbook "logrotate", path: "./vendor/cookbooks/logrotate"
cookbook "lvm", path: "./vendor/cookbooks/lvm"
cookbook "windows", path: "./vendor/cookbooks/windows"
cookbook "yum", path: "./vendor/cookbooks/yum"
cookbook "yum-elrepo", path: "./vendor/cookbooks/yum-elrepo"
cookbook "yum-epel", path: "./vendor/cookbooks/yum-epel"
