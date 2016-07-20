test_name "Facts should resolve as expected in Debian 6 and 7"

@ip_regex = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/

#
# This test is intended to ensure that facts specific to an OS configuration
# resolve as expected in Debian 6 and 7.
#
# Facts tested: os, processors, networking, identity, kernel
#

confine :to, :platform => /debian-squeeze|debian-wheezy|debian-jessie/

agents.each do |agent|
  if agent['platform'] =~ /squeeze/
    codename   = 'squeeze'
    os_version = '6'
    os_kernel = '2.6'
  elsif agent['platform'] =~ /wheezy/
    codename   = 'wheezy'
    os_version = '7'
    os_kernel = '3.2'
  elsif agent['platform'] =~ /jessie/
    codename   = 'jessie'
    os_version = '8'
    os_kernel = '3.16'
  end

  if agent['platform'] =~ /x86_64/
    os_arch     = 'amd64'
    os_hardware = 'x86_64'
  else
    os_arch     = 'i386'
    os_hardware = 'i686'
  end

  step "Ensure the OS fact resolves as expected"
  expected_os = {
                  'os.architecture'         => os_arch,
                  'os.distro.codename'      => codename,
                  'os.distro.description'   => /Debian GNU\/Linux #{os_version}\.\d/,
                  'os.distro.id'            => 'Debian',
                  'os.distro.release.full'  => /#{os_version}\.\d/,
                  'os.distro.release.major' => os_version,
                  'os.distro.release.minor' => /\d/,
                  'os.family'               => 'Debian',
                  'os.hardware'             => os_hardware,
                  'os.name'                 => 'Debian',
                  'os.release.full'         => /#{os_version}\.\d/,
                  'os.release.major'        => os_version,
                  'os.release.minor'        => /\d/,
                }

  expected_os.each do |fact, value|
    assert_match(value, fact_on(agent, fact))
  end

  step "Ensure the Processors fact resolves with reasonable values"
  expected_processors = {
                          'processors.count'         => /[1-9]/,
                          'processors.physicalcount' => /[1-9]/,
                          'processors.isa'           => /unknown|#{os_hardware}/,
                          'processors.models'        => /"Intel\(R\).*"/
                        }

  expected_processors.each do |fact, value|
    assert_match(value, fact_on(agent, fact))
  end

  step "Ensure the Networking fact resolves with reasonable values for at least one interface"

  expected_networking = {
                          "networking.dhcp"     => @ip_regex,
                          "networking.ip"       => @ip_regex,
                          "networking.ip6"      => /[a-f0-9]+:+/,
                          "networking.mac"      => /[a-f0-9]{2}:/,
                          "networking.mtu"      => /\d+/,
                          "networking.netmask"  => /\d+\.\d+\.\d+\.\d+/,
                          "networking.netmask6" => /[a-f0-9]+:/,
                          "networking.network"  => @ip_regex,
                          "networking.network6" => /([a-f0-9]+)?:([a-f0-9]+)?/
                        }

  expected_networking.each do |fact, value|
    assert_match(value, fact_on(agent, fact))
  end

  step "Ensure a primary networking interface was determined."
  primary_interface = fact_on(agent, 'networking.primary')
  refute_empty(primary_interface)

  step "Ensure bindings for the primary networking interface are present."
  expected_bindings = {
                        "networking.interfaces.#{primary_interface}.bindings.0.address" => /\d+\.\d+\.\d+\.\d+/,
                        "networking.interfaces.#{primary_interface}.bindings.0.netmask" => /\d+\.\d+\.\d+\.\d+/,
                        "networking.interfaces.#{primary_interface}.bindings.0.network" => /\d+\.\d+\.\d+\.\d+/,
                        "networking.interfaces.#{primary_interface}.bindings6.0.address" => /[a-f0-9:]+/,
                        "networking.interfaces.#{primary_interface}.bindings6.0.netmask" => /[a-f0-9:]+/,
                        "networking.interfaces.#{primary_interface}.bindings6.0.network" => /[a-f0-9:]+/
                      }
  expected_bindings.each do |fact, value|
    assert_match(value, fact_on(agent, fact))
  end

  step "Ensure the identity fact resolves as expected"
  expected_identity = {
                        'identity.gid'        => '0',
                        'identity.group'      => 'root',
                        'identity.uid'        => '0',
                        'identity.user'       => 'root',
                        'identity.privileged' => 'true'
                      }

  expected_identity.each do |fact, value|
    assert_equal(value, fact_on(agent, fact))
  end

  step "Ensure the kernel fact resolves as expected"
  expected_kernel = {
                      'kernel'           => 'Linux',
                      'kernelrelease'    => os_kernel,
                      'kernelversion'    => os_kernel,
                      'kernelmajversion' => os_kernel
                    }

  expected_kernel.each do |fact, value|
    assert_match(value, fact_on(agent, fact))
  end
end