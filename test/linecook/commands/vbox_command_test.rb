require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/commands/vbox_command'
require 'linecook/test'

class VboxCommandTest < Test::Unit::TestCase
  include Linecook::Test

  VboxCommand = Linecook::Commands::VboxCommand
  HOST_REGEXP = VboxCommand::HOST_REGEXP
  
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
  # load_hosts test
  #
  
  def test_load_hosts_loads_host_vm_pairs_from_config_file
    path = prepare('config/ssh') do |io|
      io.puts 'Host a # [one]'
      io.puts 'Host b # [two]'
    end
    
    assert_equal([['a', 'one'], ['b', 'two']], cmd.load_hosts(path))
  end
  
  def test_load_hosts_allows_punctuation_in_host_names
    path = prepare('config/ssh') do |io|
      io.puts 'Host a::b # [c]'
    end
    assert_equal([['a::b', 'c']], cmd.load_hosts(path))
  end
  
  def test_load_hosts_uses_host_name_as_vm_name_if_no_vm_name_is_specified
    path = prepare('config/ssh') do |io|
      io.puts 'Host a'
      io.puts 'Host b'
    end
    assert_equal([['a', 'a'], ['b', 'b']], cmd.load_hosts(path))
  end
  
  def test_load_hosts_loads_no_hosts_if_no_hosts_are_specified
    path = prepare('config/ssh') {|io| }
    assert_equal([], cmd.load_hosts(path))
  end
  
  #
  # each_host test
  #
  
  def test_each_host_iterates_hosts
    results = []
    cmd.each_host ['a', 'b', 'c'] do |host|
      results << host
    end
    
    assert_equal ['a', 'b', 'c'], results
  end
  
  def test_each_host_skips_duplicates
    results = []
    cmd.each_host ['a', 'b', 'a', 'c', 'a'] do |host|
      results << host
    end
    
    assert_equal ['a', 'b', 'c'], results
  end
  
  def test_each_host_iterates_non_splat_hosts_in_ssh_config_file_by_default
    cmd.ssh_config_file = prepare('config/ssh') do |io|
      io.puts 'Host a'
      io.puts 'Host b'
      io.puts 'Host b'
      io.puts 'Host c'
      io.puts 'Host *'
    end
    
    results = []
    cmd.each_host do |host|
      results << host
    end
    
    assert_equal ['a', 'b', 'c'], results
  end
  
  #
  # each_vm_name test
  #
  
  def test_each_vm_name_iterates_vm_names
    results = []
    cmd.each_vm_name ['a', 'b', 'c'] do |name|
      results << name
    end
    
    assert_equal ['a', 'b', 'c'], results
  end
  
  def test_each_vm_name_skips_duplicates
    results = []
    cmd.each_vm_name ['a', 'b', 'a', 'c', 'a'] do |name|
      results << name
    end
    
    assert_equal ['a', 'b', 'c'], results
  end
  
  def test_each_vm_name_iterates_non_splat_hosts_in_ssh_config_file_by_default
    cmd.ssh_config_file = prepare('config/ssh') do |io|
      io.puts 'Host a # [one]'
      io.puts 'Host b # [two]'
      io.puts 'Host c # [two]'
      io.puts 'Host * # [three]'
      io.puts 'Host *'
    end
    
    results = []
    cmd.each_vm_name do |name|
      results << name
    end
    
    assert_equal ['one', 'two', 'three'], results
  end
end