require 'linecook/test/file_test'
require 'linecook/test/shell_test'

module Linecook
  module Test
    module VmTest
      include FileTest
      include ShellTest
      
      REMOTE_DIR = ENV['REMOTE_DIR'] || 'test'
      SSH_CONFIG_FILE = ENV['SSH_CONFIG_FILE'] || File.expand_path('config/ssh')
      DEFAULT_VM_OPTIONS = {
        :ssh_config_file => SSH_CONFIG_FILE,
        :host            => 'vbox',
        :remote_test_dir => REMOTE_DIR
      }
      
      attr_reader :vm_options
      
      def setup
        super
        @vm_options = DEFAULT_VM_OPTIONS.dup
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
      
      def remote_test_dir
        vm_options[:remote_test_dir]
      end
      
      def remote_class_dir
        vm_options[:remote_class_dir] ||= File.join(remote_test_dir, Linecook::Utils.underscore(self.class.to_s))
      end
      
      def remote_method_dir
        vm_options[:remote_method_dir] ||= File.join(remote_class_dir, method_name)
      end
      
      def vm_setup
        ssh outdent(%Q{
          sh <<SETUP
          rm -rf '#{remote_method_dir}'
          mkdir -p '#{remote_method_dir}'
          SETUP
        })
      end
      
      def vm_teardown
        unless ENV["KEEP_OUTPUTS"] == "true"
          ssh outdent(%Q{
            sh <<TEARDOWN
            dir='#{remote_method_dir}'
            base='#{remote_class_dir}'

            rm -r "$dir"
            while [ $? -eq 0 ]; 
            do 
              dir=$(dirname "$dir")
              rmdir "$dir"
            done
            TEARDOWN
          })
        end
      end
      
      def with_vm(options={})
        current = @vm_options
        
        begin
          @vm_options = DEFAULT_VM_OPTIONS.merge(options)
          vm_setup
          yield
        ensure
          vm_teardown
          @vm_options = current
        end
      end
      
      def assert_remote_script(remote_script, options={})
        caller[1] =~ Lazydoc::CALLER_REGEXP
        file, lineno = $1, $2.to_i
        
        options = {
          :shell       => '/bin/sh',
          :script_name => "line_#{lineno}.sh",
          :exit_status => 0
        }.merge(options)
        
        shell = options[:shell]
        script_name = options[:script_name]
        exit_status = options[:exit_status]
        
        script = prepare(script_name) do |io|
          io << Template.build(REMOTE_SCRIPT_TEMPLATE,
            :shell       => shell,
            :script_name => script_name,
            :commands    => parse(remote_script, options),
            :remote_dir  => remote_method_dir
          )
        end
        
        result = ssh "#{shell} < '#{script}'", options
        assert_equal exit_status, $?.exitstatus, result
      end
      
      REMOTE_SCRIPT_TEMPLATE = <<-SCRIPT
# Write script commands to a file, to allow debugging
cd '<%= remote_dir %>'
cat > '<%= script_name %>' <<'DOC'
#!/<%= shell %>

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