require "spec_helper"
require "serverspec"

package = "zabbix_agent"
service = "zabbix_agent"
config  = "/etc/zabbix_agent/zabbix_agent.conf"
user    = "zabbix_agent"
group   = "zabbix_agent"
ports   = [PORTS]
log_dir = "/var/log/zabbix_agent"
db_dir  = "/var/lib/zabbix_agent"

case os[:family]
when "freebsd"
  config = "/usr/local/etc/zabbix_agent.conf"
  db_dir = "/var/db/zabbix_agent"
end

describe package(package) do
  it { should be_installed }
end

describe file(config) do
  it { should be_file }
  its(:content) { should match Regexp.escape("zabbix_agent") }
end

describe file(log_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(db_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/zabbix_agent") do
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
