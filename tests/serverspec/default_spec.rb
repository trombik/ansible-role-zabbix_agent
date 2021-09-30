require "spec_helper"
require "serverspec"

package = "zabbix_agent"
service = "zabbix_agentd"
config  = "/etc/zabbix_agent/zabbix_agent.conf"
user    = "zabbix_agent"
group   = "zabbix_agent"
ports   = [10050]

case os[:family]
when "freebsd"
  package = "zabbix54-agent"
  config = "/usr/local/etc/zabbix54/zabbix_agentd.conf"
end

describe package(package) do
  it { should be_installed }
end

describe file(config) do
  it { should be_file }
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
