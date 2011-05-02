require File.expand_path('../../test_helper', __FILE__)
require 'linecook/test'

class GenerateScriptsTest < Test::Unit::TestCase
  include Linecook::Test
  
  def setup
    super
    FileUtils.mkdir_p method_dir
    Dir.chdir method_dir
  end

  def teardown
    Dir.chdir user_dir
    super
  end
  
  def test_build_with_package_file
    prepare('packages/demo.yml', %q{
linecook:
  package:
    recipes:
      run: demo     # package/path: recipe_name
})

    prepare('recipes/demo.rb', %q{
target.puts <<-SCRIPT
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
git config --global user.name "John Doe"
git config --global user.email "john.doe@example.com"
SCRIPT
})

    stdout, cmd = linecook 'build', 'I' => ['lib']
    assert_equal 0, $?.exitstatus, "% #{cmd}\n#{stdout}"

    assert_output_equal %q{
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
git config --global user.name "John Doe"
git config --global user.email "john.doe@example.com"
}, File.read('packages/demo/run')
  end

  def test_build_with_empty_package_file
    prepare('packages/demo.yml', %q{
{}
})

    prepare('recipes/demo.rb', %q{
target.puts <<-SCRIPT
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
git config --global user.name "John Doe"
git config --global user.email "john.doe@example.com"
SCRIPT
})

    stdout, cmd = linecook 'build', 'I' => ['lib']
    assert_equal 0, $?.exitstatus, "% #{cmd}\n#{stdout}"

    assert_output_equal %q{
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
git config --global user.name "John Doe"
git config --global user.email "john.doe@example.com"
}, File.read('packages/demo/run')
  end
  
  def test_build_with_attributes
    prepare('attributes/git.rb', %q{
attrs['git']['package'] = 'git'
attrs['git']['config']['user.name'] = 'John Doe'
attrs['git']['config']['user.email'] = 'john.doe@example.com'
})

    prepare('attributes/ruby.rb', %q{
attrs['ruby']['package'] = 'ruby1.9.1'
})
    
    prepare('packages/demo.yml', %q{
ruby:
  package: ruby1.8
})

    prepare('recipes/demo.rb', %q{
attributes 'ruby'
attributes 'git'
#########################################################################
target.puts <<-SCRIPT
sudo apt-get -y install #{attrs['ruby']['package']}
sudo apt-get -y install #{attrs['git']['package']}
git config --global user.name "#{attrs['git']['config']['user.name']}"
git config --global user.email "#{attrs['git']['config']['user.email']}"
SCRIPT
})

    stdout, cmd = linecook 'build', 'I' => ['lib']
    assert_equal 0, $?.exitstatus, "% #{cmd}\n#{stdout}"

    assert_output_equal %q{
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
git config --global user.name "John Doe"
git config --global user.email "john.doe@example.com"
}, File.read('packages/demo/run')
  end
  
  def test_build_with_helpers
    prepare('attributes/git.rb', %q{
attrs['git']['package'] = 'git'
attrs['git']['config']['user.name'] = 'John Doe'
attrs['git']['config']['user.email'] = 'john.doe@example.com'
})

    prepare('attributes/ruby.rb', %q{
attrs['ruby']['package'] = 'ruby1.9.1'
})

    prepare('helpers/demo/install.erb', %q{
Installs a package using apt-get.
(package)
--
sudo apt-get -y install <%= package %>
})

    prepare('helpers/demo/set_git_config.erb', %q{
Sets a global git config.
(key, value)
--
git config --global <%= key %> "<%= value %>"
})

    prepare('packages/demo.yml', %q{
ruby:
  package: ruby1.8
})

    prepare('recipes/demo.rb', %q{
attributes 'ruby'
attributes 'git'
helpers 'demo'
#########################################################################
install attrs['ruby']['package']
install attrs['git']['package']
['user.name', 'user.email'].each do |key|
  set_git_config key, attrs['git']['config'][key]
end
})

    stdout, cmd = linecook 'build', 'I' => ['lib']
    assert_equal 0, $?.exitstatus, "% #{cmd}\n#{stdout}"

    assert_output_equal %q{
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
git config --global user.name "John Doe"
git config --global user.email "john.doe@example.com"
}, File.read('packages/demo/run')
  end
  
  def test_build_with_file
    prepare('files/gitconfig', %q{
[user]
	name = John Doe
	email = john.doe@example.com
})

    prepare('packages/demo.yml', %q{
{}
})

    prepare('recipes/demo.rb', %q{
target.puts <<-SCRIPT
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
cp "#{ file_path "gitconfig" }" ~/.gitconfig
SCRIPT
})

    stdout, cmd = linecook 'build', 'I' => ['lib']
    assert_equal 0, $?.exitstatus, "% #{cmd}\n#{stdout}"

    assert_alike %q{
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
cp ":...:/gitconfig" ~/.gitconfig
}, File.read('packages/demo/run')

    assert_equal %q{
[user]
	name = John Doe
	email = john.doe@example.com
}, File.read('packages/demo/gitconfig')
  end
  
  def test_build_with_template
    prepare('attributes/git.rb', %q{
attrs['git']['package'] = 'git'
attrs['git']['config']['user.name'] = 'John Doe'
attrs['git']['config']['user.email'] = 'john.doe@example.com'
})
    
    prepare('templates/gitconfig.erb', %q{
[user]
	name = <%= attrs['git']['config']['user.name'] %>
	email = <%= attrs['git']['config']['user.email'] %>
})

    prepare('packages/demo.yml', %q{
{}
})

    prepare('recipes/demo.rb', %q{
attributes 'git'
#########################################################################
target.puts <<-SCRIPT
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
cp "#{ template_path "gitconfig.erb" }" ~/.gitconfig
SCRIPT
})

    stdout, cmd = linecook 'build', 'I' => ['lib']
    assert_equal 0, $?.exitstatus, "% #{cmd}\n#{stdout}"

    assert_alike %q{
sudo apt-get -y install ruby1.8
sudo apt-get -y install git
cp ":...:/gitconfig" ~/.gitconfig
}, File.read('packages/demo/run')

    assert_equal %q{
[user]
	name = John Doe
	email = john.doe@example.com
}, File.read('packages/demo/gitconfig')
  end
end
