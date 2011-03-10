require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/commands/helper'
require 'linecook/test'

class HelperCommandTest < Test::Unit::TestCase
  include Linecook::Test
  
  Helper = Linecook::Commands::Helper
  
  attr_accessor :cmd
  
  def setup
    super
    @cmd = Helper.new
  end
  
  #
  # partition test
  #
  
  def test_partition_separates_section_files_and_definitions_based_on_leading_dash
    a = '-a.rb'
    b = 'path/to/-b.rb'
    c = 'not/a/section.rb'
    sources = [a, c, b]
    
    assert_equal [[a, b], [c]], cmd.partition(sources)
  end
  
  def test_partition_requires_section_files_to_not_have_empty_section_name
    a = '-a.rb'
    b = '-.rb'
    assert_equal [[a], [b]], cmd.partition([a,b])
  end
  
  #
  # load_sections test
  #
  
  def test_load_sections_loads_paths_into_a_hash_by_section_name
    a = prepare('-a.rb') {|io| io << 'A' }
    b = prepare('-b.rb') {|io| io << 'B' }
    paths = [a, b]
    
    assert_equal({
      'a' => 'A',
      'b' => 'B'
    }, cmd.load_sections(paths))
  end
  
  #
  # load_definition test
  #
  
  def test_load_definition_returns_desc_method_name_signature_and_body
    path = prepare('method_name.rb') do |io| 
      io.puts "desc"
      io.puts "(*args)"
      io.puts '--'
      io.puts "body"
    end
    
    assert_equal ["desc", 'method_name', "(*args)", "body"], cmd.load_definition(path)
  end
  
  def test_load_definition_corrects_method_names
    path = prepare('method_name-check.rb') {|io| io.puts "body" }
    assert_equal ["", 'method_name?', "()", "body"], cmd.load_definition(path)
  end
  
  #
  # parse_definition test
  #
  
  # helper for testing parse_definition
  def assert_def_equal(expected, str)
    assert_equal expected, cmd.parse_definition(outdent(str))
  end
  
  def test_parse_definition_split_str_into_desc_and_body_along_double_dash
    assert_def_equal ["desc", '()', "body\n"], %{
      desc
      --
      body
    }
  end
  
  def test_parse_definition_reads_signature_from_header_if_present
    assert_def_equal ["", "(*args)", "body\n"], %{
      (*args)
      --
      body
    }
  end
    
  def test_parse_definition_reads_desc_and_signature_from_header_if_present
    assert_def_equal ["desc", "(*args)", "body\n"], %{
      desc
      (*args)
      --
      body
    }
  end
  
  def test_parse_definition_handles_multiline_defs
    assert_def_equal ["a\nb\nc", "(*args)\n1\n2\n3", "x\ny\nz\n"], %{
      a
      b
      c
      (*args)
      1
      2
      3
      --
      x
      y
      z
    }
  end
  
  def test_parse_definition_returns_body_if_no_header_is_present
    assert_equal ["", '()', "body\n"], cmd.parse_definition("body\n")
  end
  
  def test_parse_definition_returns_all_empty_for_whitespace_string
    assert_def_equal ["", '()', ""], %{
    }
  end
  
  #
  # parse_method_name test
  #
  
  def test_parse_method_name_returns_normal_names
    assert_equal 'method_name', cmd.parse_method_name('method_name')
  end
  
  def test_parse_method_name_replaces_check_names_with_question_mark
    assert_equal 'method_name?', cmd.parse_method_name('method_name-check')
  end
  
  def test_parse_method_name_replaces_bang_names_with_exclamation_mark
    assert_equal 'method_name!', cmd.parse_method_name('method_name-bang')
  end
  
  def test_parse_method_name_replaces_eq_names_with_equals_sign
    assert_equal 'method_name=', cmd.parse_method_name('method_name-eq')
  end
  
  #
  # build test
  #
  
  def test_build_results_in_a_nicely_formatted_module
    definition = prepare('a.rb') do |io| 
      io.puts "aaa"
      io.puts "(*args)"
      io.puts '--'
      io.puts "  body"
    end
    
    assert_output_equal %q{
      require 'erb'
      
      module A
        module B
          # aaa
          def a(*args)
            body
            self
          end
          
          def _a(*args, &block) # :nodoc:
            capture { a(*args, &block) }
          end
        end
      end
    }, cmd.build('A::B', [definition])
  end
  
  def test_build_remains_nicely_formatted_with_sections
    header = prepare('-header.rb') do |io| 
      io.puts "header"
    end
    
    doc = prepare('-doc.rb') do |io| 
      io.puts "# doc"
    end
    
    head = prepare('-head.rb') do |io| 
      io.puts "head"
    end
    
    foot = prepare('-foot.rb') do |io| 
      io.puts "foot"
    end
    
    footer = prepare('-footer.rb') do |io| 
      io.puts "\nfooter"
    end
    
    definition = prepare('a.rb') do |io| 
      io.puts "  body"
    end
    
    assert_output_equal %q{
      require 'erb'
      header
      
      module A
        # doc
        module B
          head
          
          def a()
            body
            self
          end
          
          def _a(*args, &block) # :nodoc:
            capture { a(*args, &block) }
          end
          
          foot
        end
      end
      
      footer
    }, cmd.build('A::B', [header, head, doc, foot, footer, definition])
  end
  
  def test_build_raises_error_for_invalid_formats
    definition = prepare('method_name.json') {|io| }
    
    err = assert_raises(::Linecook::Commands::CommandError) { cmd.build('A::B', [definition]) }
    assert_equal "invalid definition format: \".json\" (#{definition.inspect})", err.message
  end
  
  def test_build_raises_error_for_non_word_method_definitions
    definition = prepare('-.rb') do |io| 
      io.puts "Override minus, for why?"
      io.puts "(arg)"
      io.puts '--'
    end
    
    err = assert_raises(::Linecook::Commands::CommandError) { cmd.build('A::B', [definition]) }
    assert_equal "invalid method name: \"-\" (#{definition.inspect})", err.message
  end
  
  #
  # examples
  #
  
  def test_generated_helpers_allow_method_chaining
    echo_def = prepare('echo.erb') do |io| 
      io.puts outdent(%q{
      (*args)
      --
      echo <%= args.join(' ') %>
      })
    end
    
    heredoc_def = prepare('heredoc.erb') do |io| 
      io.puts outdent(%q{
      ()
      rstrip
      --
       <<DOC
      <% yield %>
      DOC
      })
    end
    
    helper_file = prepare('helper.rb') do |io|
      io << cmd.build("HelperCommandTestModules::ChainHelper", [echo_def, heredoc_def])
    end
    
    load helper_file
    use_helpers ::HelperCommandTestModules::ChainHelper
    
    assert_recipe %q{
      echo a b c
      echo <<DOC
      x
      y
      z
      DOC
    } do
      echo 'a', 'b', 'c'
      echo.heredoc do
        target.puts "x"
        target.puts "y"
        target.puts "z"
      end
    end
  end
end