require 'puppet'
require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

# overriding puppet installation for the RedHat family distros due to
# puppet breakage >= 3.5
def install_puppet(host)
  host['platform'] =~ %r{(fedora|el)-(\d+)}
  if host['platform'] =~ %r{(fedora|el)-(\d+)}
    safeversion = '3.4.2'
    platform = Regexp.last_match(1)
    relver = Regexp.last_match(2)
    on host, "rpm -ivh http://yum.puppetlabs.com/puppetlabs-release-#{platform}-#{relver}.noarch.rpm"
    on host, "yum install -y puppet-#{safeversion}"
  else
    super()
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.before do
    Puppet::Util::Log.level = :warning
    Puppet::Util::Log.newdestination(:console)
  end

  c.before :suite do
    hosts.each do |host|
      unless ENV['RS_PROVISION'] == 'no' || ENV['BEAKER_provision'] == 'no'
        begin
          on host, 'puppet --version'
        rescue
          if host.is_pe?
            install_pe
          else
            install_puppet(host)
          end
        end
      end

      # Install module and dependencies
      puppet_module_install(source: proj_root, module_name: File.basename(proj_root).gsub(%r{^puppet-}, ''))

      install_module_from_forge('puppet-epel', '>= 3.0.0 < 4.0.0') if fact('os.family') == 'RedHat'
      install_module_from_forge('puppetlabs-apache', '>= 2.1.0 < 6.0.0')
    end
  end
end
