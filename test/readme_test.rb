require File.expand_path('../test_helper', __FILE__)
require 'linecook/test'

class ReadmeTest < Test::Unit::TestCase
  include Linecook::Test
  
  LINE_COOK_DIR = File.expand_path('../..', __FILE__)
  LINE_COOK = File.join(LINE_COOK_DIR, 'bin/linecook')
  
  def test_readme
    Dir.chdir user_dir
    FileUtils.rmdir method_dir
    sh "#{LINE_COOK} init '#{method_dir}'"
    Dir.chdir method_dir
    
    file('helpers/example/_head.rb', %q{
COLOR_CODES = Hash[*%W{
  black       0;30   red         0;31
  white       1;37   green       0;32
  light_gray  0;37   blue        0;34
}]
})

    file('helpers/example/color.erb', %q{
Adds color to a string.
(color, str)
--
\033[<%= COLOR_CODES[color.to_s] %>m<%= str %>\033[0m
})

    file('helpers/example/echo.erb', %q{
Echo a string in color
(str, options={})
color = options[:color]
--
echo -e '<%= color ? _color(color, str) : str %>'
})

    file('attributes/example.rb', %q{
attrs['example']['n'] = 3
attrs['example']['color'] = 'blue'
})

    file('recipes/example.rb', %q{
helpers "example"
attributes "example"

attrs['example']['n'].times do
  echo "I will not manually configure my server", :color => attrs['example']['color']
end
})

    file('packages/example.yml', %q{
linecook:
  recipes:
  - example
example:
  n: 5
})

    File.open(path('Gemfile'), 'w') do |io|
      io.puts %Q{
        path '#{LINE_COOK_DIR}', :glob => 'linecook.gemspec'
        gem 'linecook'
        path '.'
      }
    end
    
    sh "rake packages 2>&1 > /dev/null"
    
    sh_test %Q{
      % bash '#{path('packages/example/example')}'
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
    }
    
    # Start the VM and run the scripts (see the docs for setting up a VM).
    # 
    #   % rake vbox:start
    #   % rake vbox:ssh 
    #   vm: bash /vbox/scripts/example.sh
    #   vm: exit
    # 
    # Stop the VM.
    # 
    #   % rake vbox:stop
  end
end