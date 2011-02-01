require 'linecook/constants'

module Linecook
  class Vbox
    attr_reader :vm_name
    
    def initialize(vm_name=DEFAULT_VM_NAME)
      @vm_name = vm_name
    end
    
    def running?
      `VBoxManage -q list runningvms`.include?(vm_name)
    end
    
    def start(type='headless')
      "VBoxManage -q startvm #{vm_name} --type #{type}"
    end
    
    def stop
      "VBoxManage -q controlvm #{vm_name} poweroff"
    end
    
    def reset(snapshot)
      "VBoxManage -q snapshot #{vm_name} restore #{snapshot.upcase}"
    end
    
    def snapshot(snapshot)
      "VBoxManage -q snapshot #{vm_name} delete #{snapshot.upcase} > /dev/null;\n" + 
      "VBoxManage -q snapshot #{vm_name} take #{snapshot.upcase}"
    end
    
    def ssh(cmd=nil, options={})
      host        = options[:hostname] || DEFAULT_HOSTNAME
      config_file = options[:config_file] || DEFAULT_SSH_CONFIG_FILE
      "ssh #{options[:quiet] ? '-q ' : nil}-F '#{config_file}' '#{host}' -- #{cmd}"
    end
    
    def share(path, options={})
      path = File.expand_path(path)
      name = Time.now.strftime("vbox-#{File.basename(path)}-%Y%m%d%H%M%S")
      
      "VBoxManage sharedfolder add '#{vm_name}' --name '#{name}' --hostpath '#{path}' --transient;\n" +
      ssh("sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' /vbox", options)
    end
  end
end