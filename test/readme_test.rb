require File.expand_path('../test_helper', __FILE__)
require 'linecook/test'

class ReadmeTest < Test::Unit::TestCase
  include Linecook::Test
  
  LINE_COOK_DIR = File.expand_path('../..', __FILE__)
  LINE_COOK = File.join(LINE_COOK_DIR, 'bin/linecook')
  
  def teardown
    Dir.chdir user_dir
    super
  end
  
  def test_readme
    sh "#{LINE_COOK} init '#{method_dir}'"
    Dir.chdir method_dir
    
    prepare('helpers/example/head-section.rb', %q{
COLOR_CODES = Hash[*%W{
  black       0;30   red         0;31
  white       1;37   green       0;32
  light_gray  0;37   blue        0;34
}]
})

    prepare('helpers/example/color.erb', %q{
Adds color to a string.
(color, str)
--
\033[<%= COLOR_CODES[color.to_s] %>m<%= str %>\033[0m
})

    prepare('helpers/example/echo.erb', %q{
Echo a string in color
(str, options={})
color = options[:color]
--
echo -e '<%= color ? _color(color, str) : str %>'
})

    prepare('attributes/example.rb', %q{
attrs['example']['n'] = 3
attrs['example']['color'] = 'blue'
})

    prepare('recipes/example.rb', %q{
helpers "example"
attributes "example"

attrs['example']['n'].times do
  echo "I will not manually configure my server", :color => attrs['example']['color']
end
})

    prepare('packages/example.yml', %q{
linecook:
  recipes:
  - example
example:
  n: 5
})

    gemfile = path('Gemfile')
    File.open(gemfile, 'w') do |io|
      io.puts %Q{
        path '#{LINE_COOK_DIR}', :glob => 'linecook.gemspec'
        gemspec
      }
    end
    
    sh "BUNDLE_GEMFILE='#{gemfile}' rake packages 2>&1 > /dev/null"
    
    assert_script %Q{
      % bash '#{path('packages/example/example')}'
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
      \033[0;34mI will not manually configure my server\033[0m
    }
  end
end