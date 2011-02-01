require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/template'
require 'linecook/utils'

module Linecook
  module Test
    module VmTest
      include FileTest
      include ShellTest
      
      DEFAULT_VM_NAME = ENV['LINECOOK_VM_NAME'] || 'vbox'
      
      attr_reader :hostname
      
      def setup
        super
        @hostname = DEFAULT_VM_NAME
      end
      
      def ssh_config_file
        @ssh_config_file ||= 'config/ssh'
      end
      
      def hostnames
        @hostnames ||= begin
          hostnames = []
          
          if File.exists?(ssh_config_file)
            File.open(ssh_config_file) do |io|
              io.each_line do |line|
                next unless line =~ /Host (\w+)/
                hostnames << $1 
              end
            end
          end
          
          hostnames
        end
      end
      
      def remote_method_dir
        @remote_method_dir ||= begin
          method_dir.index(user_dir) == 0 ? 
          method_dir[user_dir.length + 1, method_dir.length - user_dir.length] :
          method_name
        end
      end
      
      def ssh(cmd)
        # -T: 'Pseudo-terminal will not be allocated because stdin is not a terminal.'
        # -q: 'Warning: Permanently added '[localhost]:2222' (RSA) to the list of known hosts.'
        sh("ssh -q -T -F '#{ssh_config_file}' '#{hostname}' -- #{cmd}")
      end
      
      def scp(sources, target)
        sources = [sources] unless sources.kind_of?(Array)
        sh("2>&1 scp -q -r -F '#{ssh_config_file}' '#{sources.join("' '")}' '#{hostname}:#{target}'")
      end
      
      def vm_setup(hostname=VMNAME)
        @hostname = hostname
        
        ssh outdent(%Q{
          <<SETUP
          rm -rf '#{remote_method_dir}'
          mkdir -p '#{remote_method_dir}'
          SETUP
        })
      end
      
      def vm_teardown
        ssh outdent(%Q{
          <<TEARDOWN
          rm -rf '#{remote_method_dir}'
          rmdir "$(dirname '#{remote_method_dir}')" > /dev/null 2>&1
          TEARDOWN
        })
      end
      
      def with_vm(host=hostname, options={})
        current = @hostname
        
        begin
          vm_setup(host)
          yield
        ensure
          vm_teardown if options[:teardown]
          @hostname = current
        end
      end
      
      def with_each_vm(options={}, &block)
        hostnames.each do |hostname|
          with_vm(hostname, options, &block)
        end
      end
      
      def assert_remote_script(script, options={})
        options = {
          :script_name => 'assert_remote_script.sh',
          :exit_status => 0
        }.merge(options)
        
        script_name = options[:script_name]
        exit_status = options[:exit_status]
        
        script_path = prepare(script_name) do |io|
          io << Template.build(REMOTE_SCRIPT_TEMPLATE,
            :script_name => script_name,
            :commands    => CommandParser.new(options).parse(outdent(script)),
            :remote_dir  => remote_method_dir
          )
        end
        
        result = ssh "< '#{script_path}' 2>&1"
        assert_equal exit_status, $?.exitstatus, result
      end
      
      REMOTE_SCRIPT_TEMPLATE = <<-SCRIPT
cd '<%= remote_dir %>'
if [ $? -ne 0 ]; then exit 1; fi

# Write script commands to a file, to allow debugging
cat > '<%= script_name %>' <<'DOC'
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
chmod +x '<%= script_name %>'
'./<%= script_name %>'
SCRIPT
    end
  end
end