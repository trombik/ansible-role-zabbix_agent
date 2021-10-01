require "spec_helper"
require "serverspec"

package = "zabbix-agent"
service = "zabbix-agent"
config_dir = "/etc/zabbix"
user    = "zabbix"
group   = "zabbix"
ports   = [10_050]

case os[:family]
when "freebsd"
  service = "zabbix_agentd"
  package = "zabbix54-agent"
  config_dir = "/usr/local/etc/zabbix54"
end
config = "#{config_dir}/zabbix_agentd.conf"

describe package(package) do
  it { should be_installed }
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 640 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match Regexp.escape("Managed by ansible") }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/#{service}") do
    it { should be_file }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
