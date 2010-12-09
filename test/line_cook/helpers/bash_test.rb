require File.expand_path('../../../test_helper', __FILE__)
require 'line_cook/helpers/bash'
require 'line_cook/recipe'

class BashTest < Test::Unit::TestCase
  acts_as_shell_test
  
  attr_accessor :recipe
  
  def setup
    super
    @recipe = LineCook::Recipe.new('recipe').extend(LineCook::Helpers::Bash)
  end
  
  def assert_recipe(expected, &block)
    recipe.instance_eval(&block)
    assert_output_equal expected, recipe.to_s
  end
  
  def assert_content(expected, name)
    recipe.close
    
    source_path = recipe.registry.invert[name]
    assert_output_equal expected, File.read(source_path)
  end
  
  #
  # comment test
  #
  
  def test_comment_writes_a_comment
    assert_recipe(%{
      # hello world
    }){ 
      comment('hello world')
    }
  end
  
  def test_comment_wraps_long_comments
    assert_recipe(%{
      # lorem ipsum dolor sit ametlorem ipsum dolor sit ametlorem ipsum dolor sit
      # ametlorem ipsum dolor sit ametlorem ipsum dolor sit ametlorem ipsum dolor sit
      # ametlorem ipsum dolor sit ametlorem ipsum dolor sit ametlorem ipsum dolor sit
      # ametlorem ipsum dolor sit amet
    }){ 
      comment("lorem ipsum dolor sit amet" * 10)
    }
  end
  
  #
  # su test
  #
  
  def test_su_wraps_block_content_in_a_script
    assert_recipe(%{
      su root "$LINECOOK_DIR/recipe.d/0-root"
      check_status 0 $? $LINENO
      
    }){ 
      su('root') do 
        comment('content')
      end
    }
    
    assert_content "# content\n", 'recipe.d/0-root'
  end
  
  def test_nested_su
    assert_recipe %q{
      # +A
      su a "$LINECOOK_DIR/recipe.d/2-a"
      check_status 0 $? $LINENO
      
      # -A
    } do
      comment('+A')
      su('a') do 
        comment('+B')
        su('b') do
          comment('+C')
          su('c') do
            comment('+D')
            comment('-D')
          end
          comment('-C')
        end
        comment('-B')
      end
      comment('-A')
    end
    
    assert_content %q{
      # +B
      su b "$LINECOOK_DIR/recipe.d/1-b"
      check_status 0 $? $LINENO
      
      # -B
    }, 'recipe.d/2-a'
    
    assert_content %q{
      # +C
      su c "$LINECOOK_DIR/recipe.d/0-c"
      check_status 0 $? $LINENO
      
      # -C
    }, 'recipe.d/1-b'
    
    assert_content %q{
      # +D
      # -D
    }, 'recipe.d/0-c'
  end
  
  #
  # package test
  #
  
  def test_package_calls_zypper_to_install
    assert_recipe(%{
      zypper -n --no-gpg-checks install -l package_name
      check_status 0 $? $LINENO
      
    }){ 
      package('package_name')
    }
  end
  
  def test_package_calls_zypper_to_install_package_with_specified_version
    assert_recipe(%{
      zypper -n --no-gpg-checks install -l package_name=1.0
      check_status 0 $? $LINENO
      
    }){ 
      package('package_name', '1.0')
    }
  end
  
  def test_package_does_version_less_install_for_blank_version
    assert_recipe(%{
      zypper -n --no-gpg-checks install -l package_name
      check_status 0 $? $LINENO
      
    }){ 
      package('package_name', '')
    }
  end
end
