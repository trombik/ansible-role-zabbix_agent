require "spec_helper"
require "serverspec"

# rubocop:disable Style/GlobalVars
$TLS_TYPE ||= "cert"
# rubocop:enable Style/GlobalVars

package = "zabbix-agent"
service = "zabbix-agent"
config_dir = "/etc/zabbix"
user    = "zabbix"
group   = "zabbix"
ports   = [10_050]
default_user = "root"
default_group = "root"
pid_dir = "/run/zabbix"
log_dir = "/var/log/zabbix-agent"
log_file = "#{log_dir}/zabbix_agentd.log"

case os[:family]
when "freebsd"
  service = "zabbix_agentd"
  package = "zabbix54-agent"
  config_dir = "/usr/local/etc/zabbix54"
  default_group = "wheel"
  pid_dir = "/var/run/zabbix"
when "openbsd"
  user = "_zabbix"
  group = "_zabbix"
  service = "zabbix_agentd"
  package = "zabbix-agent"
  config_dir = "/etc/zabbix"
  default_group = "wheel"
  pid_dir = "/var/run/zabbix"
end
config = "#{config_dir}/zabbix_agentd.conf"
conf_d_dir = "#{config_dir}/zabbix_agentd.conf.d"
pid_file = "#{pid_dir}/zabbix_agentd.pid"
ca_pub = "#{config_dir}/cert/ca.pub"
agent_pub = "#{config_dir}/cert/agent.pub"
agent_key = "#{config_dir}/cert/agent.key"
psk_dir = "#{config_dir}/psk"
psk_file = "#{psk_dir}/default.psk"

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

describe file(conf_d_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
end

describe file(pid_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

# XXX OpenBSD does not create, or use, PID file
if os[:family] != "openbsd"
  describe file(pid_file) do
    it { should exist }
    it { should be_file }
    it { should be_mode 664 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
  end
end

describe file(log_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(log_file) do
  it { should exist }
  it { should be_file }
  it { should be_mode 664 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match(/Starting Zabbix Agent/) }
  its(:content) { should match(/TLS support:\s+YES/) }
end

describe file("#{conf_d_dir}/foo.conf") do
  it { should exist }
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match Regexp.escape("Managed by ansible") }
  its(:content) { should match Regexp.escape("# foo.conf") }
end

describe file("#{conf_d_dir}/bar.conf") do
  it { should_not exist }
end

describe file(psk_dir) do
  it { should exist }
  it { should be_directory }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(psk_file) do
  it { should exist }
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  its(:content) { should match Regexp.escape("202bedb620721ba6126b1d0c1239044237397dc544a5c28095a5bb75925f471c") }
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

# rubocop:disable Style/GlobalVars
case $TLS_TYPE
# rubocop:enable Style/GlobalVars
when "cert"
  describe file ca_pub do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
    its(:content) { should match(/BEGIN CERTIFICATE/) }
  end

  describe file agent_pub do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
    its(:content) { should match(/BEGIN CERTIFICATE/) }
  end

  describe file agent_key do
    it { should exist }
    it { should be_file }
    it { should be_mode 600 }
    it { should be_owned_by user }
    it { should be_grouped_into group }
    its(:content) { should match(/BEGIN RSA PRIVATE KEY/) }
  end

  describe file config do
    its(:content) { should match(/TLSAccept=cert/) }
    its(:content) { should match(/TLSConnect=cert/) }
  end
when "psk"
  describe file config do
    its(:content) { should match(/TLSAccept=psk/) }
    its(:content) { should match(/TLSConnect=psk/) }
    its(:content) { should match(/TLSPSKIdentity=default/) }
  end
end
