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
      system "VBoxManage -q startvm #{vmname} --type #{type}"
    end
    
    def stop
      system "VBoxManage -q controlvm #{vmname} poweroff"
    end
    
    def reset(snapshot)
      system "VBoxManage -q snapshot #{vmname} restore #{snapshot.upcase}"
    end
    
    def snapshot(snapshot)
      `VBoxManage -q snapshot #{vmname} delete #{snapshot.upcase}`
      system "VBoxManage -q snapshot #{vmname} take #{snapshot.upcase}"
    end
    
    def ssh(cmd=nil, options={})
      options = {
        :port => 2222,
        :user => 'vbox',
        :keypath => DEFAULT_KEYPATH
      }.merge(options)
      
      # To prevent ssh errors, protect the private key
      FileUtils.chmod(0600, options[:keypath])
      `ssh -p #{options[:port]} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i #{options[:keypath]} #{options[:user]}@localhost #{cmd}`
    end
    
    def ssh!(cmd=nil, options={})
      options = {
        :port => 2222,
        :user => 'vbox',
        :keypath => DEFAULT_KEYPATH
      }.merge(options)
      
      # To prevent ssh errors, protect the private key
      FileUtils.chmod(0600, options[:keypath])
      
      ssh = "ssh -p #{options[:port]} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i #{options[:keypath]} #{options[:user]}@localhost #{cmd}"
      
      # Patterned after vagrant/ssh.rb (circa 0.6.6)
      # Some hackery going on here. On Mac OS X Leopard (10.5), exec fails
      # (GH-51). As a workaround, we fork and wait. On all other platforms, we
      # simply exec.
      
      platform = RUBY_PLATFORM.to_s.downcase
      pid = nil
      pid = fork if platform.include?("darwin9") || platform.include?("darwin8")
      Kernel.exec(ssh)  if pid.nil?
      Process.wait(pid) if pid
    end
    
    def share(path)
      path = File.expand_path(path)
      name = Time.now.strftime("vbox-#{File.basename(path)}-%Y%m%d%H%M%S")
      
      system "VBoxManage sharedfolder add '#{vmname}' --name '#{name}' --hostpath '#{path}' --transient"
      ssh "sudo mount -t vboxsf -o uid=1000,gid=100 '#{name}' /vbox"
    end
  end
end