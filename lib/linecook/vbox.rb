module Linecook
  class Vbox
    DEFAULT_VM_NAME = ENV['LINECOOK_VM_NAME'] || 'vbox'
    DEFAULT_KEYPATH = File.expand_path('../../../templates/vbox/ssh/id_rsa', __FILE__)
    
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
      options = {
        :port => 2222,
        :user => 'vbox',
        :keypath => DEFAULT_KEYPATH
      }.merge(options)
      
      # To prevent ssh errors, protect the private key
      FileUtils.chmod(0600, options[:keypath])
      "ssh #{options[:quiet] ? '-q ' : nil}-p #{options[:port]} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i #{options[:keypath]} #{options[:user]}@localhost #{cmd}"
    end
    
    def share(path, options={})
      path = File.expand_path(path)
      name = Time.now.strftime("vbox-#{File.basename(path)}-%Y%m%d%H%M%S")
      
      "VBoxManage sharedfolder add '#{vmname}' --name '#{name}' --hostpath '#{path}' --transient;\n" +
      ssh("sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' /vbox", options)
    end
  end
end