require 'linecook/cookbook'
require 'linecook/package'
require 'linecook/test/file_test'
require 'linecook/test/shell_test'
require 'linecook/test/regexp_escape'
require 'linecook/utils'
require 'linecook/vbox'

module Linecook
  module Test
    include FileTest
    include ShellTest
    
    attr_writer :cookbook
    attr_writer :package
    
    def timestamp
      @timestamp ||= Time.now.strftime("%Y%m%d%H%M%S")
    end
    
    def cookbook_dir
      user_dir
    end
    
    def cookbook
      @cookbook ||= Cookbook.init(cookbook_dir)
    end
    
    def setup_package(env={})
      @package = Package.init(env, cookbook)
    end
    
    def package
      @package ||= setup_package
    end
    
    def setup_recipe(target_path='recipe')
      @recipe = package.reset.recipe(target_path)
    end
    
    def recipe
      @recipe ||= setup_recipe
    end
    
    def assert_recipe(expected, &block)
      recipe = setup_recipe
      assert_output_equal expected, recipe.result(&block)
      recipe
    end
    
    def assert_recipe_match(expected, &block)
      recipe = setup_recipe
      assert_alike expected, recipe.result(&block)
      recipe
    end
    
    def build(options={}, &block)
      options = {
        :env         => {},
        :target_path => 'recipe',
        :export_dir  => path('packages')
      }.merge(options)
      
      setup_package options[:env]
      
      if block_given?
        recipe = setup_recipe options[:target_path]
        recipe.result(&block)
      end
      
      package.build
      package
    end
    
    def script_test(script, options={}, &block)
      options = {
        :config_file => File.expand_path('config/ssh', user_dir),
        :host => 'vbox',
        :test_target_path => 'vbox_test',
        :export_dir => path('packages'),
        :remote_dir => "#{timestamp}-#{method_name}"
      }.merge(options)

      package = build(options, &block)

      test = package.tempfile(options[:test_target_path])
      test << script
      
      package.export options[:export_dir]
      sh "0<&- 2>&1 scp -q -r -F '#{options[:config_file]}' '#{options[:export_dir]}' '#{options[:host]}:#{options[:remote_dir]}'"

      test_path = package.target_path(test.path)
      result = sh %Q{0<&- 2>&1 ssh -q -F '#{options[:config_file]}' '#{options[:host]}' -- "cd '#{options[:remote_dir]}'; sh '#{test_path}'"}
      assert_equal 0, $?.exitstatus, result
    end
    
    def vbox_test(remote_script, options={}, &block)
      script = []
      script << %Q{
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
}
      parse(remote_script, :outdent => true).each do |cmd, output, status|
        script << %Q{
assert_equal #{status} "$(
#{cmd}
)" $LINENO <<stdout
#{output}
stdout
}
      end
      
      script_test(script.join("\n"), options, &block)
    end
  end
end