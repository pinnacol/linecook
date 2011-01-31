module Linecook
  class Vbox
    DEFAULT_VM_NAME = ENV['LINECOOK_VM_NAME'] || 'vbox'
    DEFAULT_CONFIG_FILE = 'config/ssh'
    
    attr_reader :vmname
    
    def initialize(vmname=DEFAULT_VM_NAME)
      @vmname = vmname
    end
    
    def running?
      `VBoxManage -q list runningvms`.include?(vmname)
    end
    
    def start(type='headless')
      "VBoxManage -q startvm #{vmname} --type #{type}"
    end
    
    def stop
      "VBoxManage -q controlvm #{vmname} poweroff"
    end
    
    def reset(snapshot)
      "VBoxManage -q snapshot #{vmname} restore #{snapshot.upcase}"
    end
    
    def snapshot(snapshot)
      "VBoxManage -q snapshot #{vmname} delete #{snapshot.upcase} > /dev/null;\n" + 
      "VBoxManage -q snapshot #{vmname} take #{snapshot.upcase}"
    end
    
    def ssh(cmd=nil, options={})
      "ssh #{options[:quiet] ? '-q ' : nil}-F '#{options[:config_file]}' '#{options[:host]}' -- #{cmd}"
    end
    
    def share(path, options={})
      path = File.expand_path(path)
      name = Time.now.strftime("vbox-#{File.basename(path)}-%Y%m%d%H%M%S")
      
      "VBoxManage sharedfolder add '#{vmname}' --name '#{name}' --hostpath '#{path}' --transient;\n" +
      ssh("sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' /vbox", options)
    end
  end
end