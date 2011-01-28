require 'linecook/test/file_test'
require 'linecook/test/shell_test'

module Linecook
  module Test
    module VmTest
      include FileTest
      include ShellTest
      
      VM_TEST_DIR = ENV['VM_TEST_DIR'] || 'test'
      
      def vm_options
        @vm_options ||= {
          :ssh_config_file => File.expand_path('config/ssh', user_dir),
          :host            => 'vbox',
          :shell           => '/bin/sh',
          :heredoc         => 'SCRIPT',
          :vm_test_dir     => VM_TEST_DIR,
          :vm_class_dir    => File.join(VM_TEST_DIR, Linecook::Utils.underscore(self.class.to_s)),
          :vm_method_dir   => File.join(VM_TEST_DIR, Linecook::Utils.underscore(self.class.to_s), method_name)
        }
      end
      
      def ssh(cmd, options={})
        options = vm_options.merge(options)
        sh("ssh -q -F '#{options[:ssh_config_file]}' '#{options[:host]}' -- #{cmd}", options)
      end
      
      def scp(sources, target, options={})
        options = vm_options.merge(options)
        sources = [sources] unless sources.kind_of?(Array)
        sh("scp -q -r -F '#{options[:ssh_config_file]}' '#{sources.join("' '")}' '#{options[:host]}:#{target}'", options)
      end
      
      def setup_vm(options={})
        options = vm_options.merge(options)
        
        ssh outdent(%Q{
          #{options[:shell]} <<SETUP
          rm -r '#{options[:vm_method_dir]}'
          mkdir -p '#{options[:vm_method_dir]}'
          SETUP
        }), options
        
        options
      end
      
      def teardown_vm(options={})
        options = vm_options.merge(options)
        
        unless ENV["KEEP_OUTPUTS"] == "true"
          ssh outdent(%Q{
            #{options[:shell]} <<TEARDOWN
            dir='#{options[:vm_method_dir]}'
          
            rm -r "$dir"
            while [ $? -eq 0 ]; 
            do 
              dir=$(dirname "$dir")
              rmdir "$dir"
            done
            TEARDOWN
          }), options
        end
        
        options
      end
      
      def with_vm(options={})
        options = vm_options.merge(options)
        
        begin
          setup_vm(options)
          yield(options)
        ensure
          teardown_vm(options)
        end
      end
      
      def assert_remote_script(remote_script, options={})
        options = vm_options.merge(options)

        script = prepare('test.sh', Template.build(REMOTE_SCRIPT_TEMPLATE,
          :method_dir => options[:vm_method_dir],
          :shell => options[:shell],
          :heredoc => options[:heredoc],
          :commands =>  parse(remote_script, options),
          :test_script => 'test.sh'
        ))
        
        result = ssh %Q{#{options[:shell]} < #{script}}, options
        assert_equal((options[:exit_status] || 0), $?.exitstatus, result)
      end
      
      REMOTE_SCRIPT_TEMPLATE = <<-SCRIPT
#!<%= shell %>
cd '<%= method_dir %>'

# Copy the script to a file
cat > '<%= test_script %>' <<'<%= heredoc %>'
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
<%= heredoc %>

# Run the test script
<%= shell %> '<%= test_script %>'
SCRIPT
    end
  end
end