require File.expand_path('../../../test_helper', __FILE__) 
require 'linecook/commands/env'

class EnvTest < Test::Unit::TestCase
  Env = Linecook::Commands::Env
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Env.new
  end
  
  #
  # select test
  #
  
  def test_select_returns_value_defined_by_keys
    env = {:a => {:b => 'b'}}
    
    assert_equal({:b => 'b'}, cmd.select(env, :a))
    assert_equal('b', cmd.select(env, :a, :b))
  end
  
  def test_select_returns_nil_for_missing_or_non_hash_value
    env = {:a => {:b => 'b'}}
    
    assert_equal nil, cmd.select(env, :a, :b, :x)
    assert_equal nil, cmd.select(env, :a, :x)
    assert_equal nil, cmd.select(env, :x)
  end
end