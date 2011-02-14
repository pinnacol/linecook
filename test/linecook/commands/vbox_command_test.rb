require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/commands/vbox_command'
require 'linecook/test/file_test'

class VboxCommandTest < Test::Unit::TestCase
  VboxCommand = Linecook::Commands::VboxCommand
  HOST_REGEXP = VboxCommand::HOST_REGEXP
  
  include Linecook::Test::FileTest
  include Linecook::Test::ShellTest
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = VboxCommand.new
  end
  
  #
  # HOST_REGEXP test
  #
  
  def test_HOST_REGEXP_matches_host_line
    assert 'Host host_name' =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal nil, $2
  end
  
  def test_HOST_REGEXP_matches_host_line_with_vm_name
    assert 'Host host_name # [vm_name]' =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal 'vm_name', $2
  end
  
  def test_HOST_REGEXP_is_indifferent_to_whitespace
    assert "   Host\thost_name   \t   #[vm_name]    " =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal 'vm_name', $2
    
    assert " \t  Host    host_name#\t  [vm_name]" =~ HOST_REGEXP
    assert_equal 'host_name', $1
    assert_equal 'vm_name', $2
  end
  
  #
  # hosts test
  #
  
  def test_hosts_loads_host_vm_pairs_from_config_file
    path = prepare('config/ssh') do |io|
      io.puts 'Host a # [one]'
      io.puts 'Host b # [two]'
    end
    
    assert_equal({'a' => 'one', 'b' => 'two'}, cmd.hosts(path))
  end
  
  def test_hosts_uses_host_name_as_vm_name_if_no_vm_name_is_specified
    path = prepare('config/ssh') do |io|
      io.puts 'Host a'
      io.puts 'Host b'
    end
    assert_equal({'a' => 'a', 'b' => 'b'}, cmd.hosts(path))
  end
  
  def test_hosts_loads_no_hosts_if_no_hosts_are_specified
    path = prepare('config/ssh') {|io| }
    assert_equal({}, cmd.hosts(path))
  end
end