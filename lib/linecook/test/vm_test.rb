require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/template'

module Linecook
  module Test
    module VmTest
      include FileTest
      include ShellTest
      
      VMNAMES = (ENV['VMNAME'] || 'vbox').split(':')
      VMNAME  = VMNAMES.first
      
      attr_reader :vm_options
      
      def setup
        super
        @vm_options = {}
      end
      
      def hostname
        vm_options[:hostname] ||= VMNAME
      end
      
      def ssh_dir
        vm_options[:ssh_dir] ||= user_dir
      end
      
      def ssh_config_file
        vm_options[:ssh_config_file] ||= 'config/ssh'
      end
      
      def remote_user_dir
        vm_options[:remote_user_dir] ||= "."
      end
      
      def remote_method_dir
        vm_options[:remote_method_dir] ||= begin
          relative_path = method_dir.index(user_dir) == 0 ? 
            method_dir[user_dir.length, method_dir.length - user_dir.length] :
            method_name
          
          File.join(remote_user_dir, relative_path)
        end
      end
      
      def ssh(cmd)
        Dir.chdir(ssh_dir) do
          sh("ssh -q -F '#{ssh_config_file}' '#{hostname}' -- #{cmd}")
        end
      end
      
      def scp(sources, target)
        sources = [sources] unless sources.kind_of?(Array)
        
        Dir.chdir(ssh_dir) do
          sh("2>&1 scp -q -r -F '#{ssh_config_file}' '#{sources.join("' '")}' '#{hostname}:#{target}'")
        end
      end
      
      def vm_setup(options=vm_options)
        @vm_options = options
        
        ssh outdent(%Q{
          sh <<SETUP
          rm -rf '#{remote_method_dir}'
          mkdir -p '#{remote_method_dir}'
          SETUP
        })
      end
      
      def vm_teardown
        ssh outdent(%Q{
          sh <<TEARDOWN
          rm -rf '#{remote_method_dir}'
          rmdir "$(dirname '#{remote_method_dir}')" > /dev/null 2>&1
          TEARDOWN
        })
      end
      
      def with_vm(options={})
        current = @vm_options
        
        begin
          vm_setup(options)
          yield
        ensure
          vm_teardown if options[:teardown]
          @vm_options = current
        end
      end
      
      def with_each_vm(options={}, &block)
        hosts = options[:hostnames] || VMNAMES
        
        hosts.each do |host|
          opts = options.merge(:hostname => host)
          with_vm(opts, &block)
        end
      end
      
      def assert_remote_script(script, options={})
        options = {
          :shell       => '/bin/sh',
          :script_name => 'assert_remote_script.sh',
          :exit_status => 0
        }.merge(options)
        
        shell = options[:shell]
        script_name = options[:script_name]
        exit_status = options[:exit_status]
        
        script_path = prepare(script_name) do |io|
          io << Template.build(REMOTE_SCRIPT_TEMPLATE,
            :shell       => shell,
            :script_name => script_name,
            :commands    => CommandParser.new(options).parse(outdent(script)),
            :remote_dir  => remote_method_dir
          )
        end
        
        result = ssh "#{shell} < '#{script_path}' 2>&1"
        assert_equal exit_status, $?.exitstatus, result
      end
      
      REMOTE_SCRIPT_TEMPLATE = <<-SCRIPT
cd '<%= remote_dir %>'
if [ $? -ne 0 ]; then exit 1; fi

# Write script commands to a file, to allow debugging
cat > '<%= script_name %>' <<'DOC'
#!<%= shell %>

assert_status_equal () {
  expected=$1; actual=$2; lineno=$3
  
  if [ $actual -ne $expected ]
  then 
    echo "[$0:$lineno] exit status $actual (expected $expected)"
    exit 1
  fi
}

assert_output_equal () {
  expected=$(cat); actual=$1; lineno=$2
  
  if [ "$actual" != "$expected" ]
  then
    echo "[$0:$lineno] unequal output"
    echo -e "$expected" > "$0_$2_expected.txt"
    echo -e "$actual"   > "$0_$2_actual.txt"
    diff "$0_$2_expected.txt" "$0_$2_actual.txt"
    exit 1
  fi
}

assert_equal () {
  assert_status_equal $1 $? $3 && 
  assert_output_equal "$2" $3
}
<% commands.each do |cmd, output, status| %>

assert_equal <%= status %> "$(
<%= cmd %>
)" $LINENO <<stdout
<%= output %>
stdout
<% end %>
DOC

# Now run the test script
<%= shell %> '<%= script_name %>'
SCRIPT
    end
  end
end