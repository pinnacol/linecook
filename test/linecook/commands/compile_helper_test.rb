require File.expand_path('../../../test_helper', __FILE__)
require 'linecook/commands/compile_helper'

class CompileHelperCommandTest < Test::Unit::TestCase
  include ShellTest

  CompileHelper = Linecook::Commands::CompileHelper

  attr_accessor :cmd

  def setup
    @cmd = CompileHelper.new
  end

  #
  # partition test
  #

  def test_partition_separates_section_files_and_definitions_based_on_leading_underscore
    a = "_a.rb"
    b = "path/to/_b.rb"
    c = "not/a/section.rb"
    sources = [a, c, b]

    assert_equal [[a, b], [c]], cmd.partition(sources)
  end

  def test_partition_requires_section_files_to_not_have_empty_section_name
    a = "_a.rb"
    b = "_.rb"
    assert_equal [[a], [b]], cmd.partition([a,b])
  end

  #
  # load_sections test
  #

  def test_load_sections_loads_paths_into_a_hash_by_section_name
    a = prepare "_a.rb", "A"
    b = prepare "_b.rb", "B"
    paths = [a, b]

    assert_equal({
      "a" => "A",
      "b" => "B"
    }, cmd.load_sections(paths))
  end

  #
  # load_definition test
  #

  def test_load_definition_returns_desc_method_name_signature_and_body
    path = prepare "method_name.rb", %{
      desc
      (*args)
      --
      body
    }

    assert_equal ["desc", "method_name", "(*args)", "body"], cmd.load_definition(path)
  end

  def test_load_definition_corrects_method_names
    path = prepare "method_name-check.rb", "body"
    assert_equal ["", "method_name?", "()", "body"], cmd.load_definition(path)
  end

  #
  # parse_definition test
  #

  # helper for testing parse_definition
  def assert_def_equal(expected, str)
    assert_equal expected, cmd.parse_definition(outdent(str))
  end

  def test_parse_definition_split_str_into_desc_and_body_along_double_dash
    assert_def_equal ["desc", "()", "body\n"], %{
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
    assert_equal ["", "()", "body\n"], cmd.parse_definition("body\n")
  end

  def test_parse_definition_returns_all_empty_for_whitespace_string
    assert_def_equal ["", "()", ""], %{
    }
  end

  #
  # parse_method_name test
  #

  def test_parse_method_name_returns_normal_names
    assert_equal "method_name", cmd.parse_method_name("method_name")
  end

  def test_parse_method_name_replaces_check_names_with_question_mark
    assert_equal "method_name?", cmd.parse_method_name("method_name-check")
  end

  def test_parse_method_name_replaces_bang_names_with_exclamation_mark
    assert_equal "method_name!", cmd.parse_method_name("method_name-bang")
  end

  def test_parse_method_name_replaces_eq_names_with_equals_sign
    assert_equal "method_name=", cmd.parse_method_name("method_name-eq")
  end

  #
  # build test
  #

  def test_build_results_in_a_nicely_formatted_module
    definition = prepare "a.rb", %{
      aaa
      (*args)
      --
        body
    }

    assert_output_equal %q{
      # Generated by Linecook

      module A
        module B
          # aaa
          def a(*args)
            body
            chain_proxy
          end

          def _a(*args, &block) # :nodoc:
            str = capture_str { a(*args, &block) }
            str.strip!
            str
          end
        end
      end
    }, cmd.build("A::B", [definition])
  end

  def test_build_remains_nicely_formatted_with_sections
    header = prepare "_header.rb", "header"
    doc    = prepare "_doc.rb",    "doc"
    head   = prepare "_head.rb",   "head"
    foot   = prepare "_foot.rb",   "foot"
    footer = prepare "_footer.rb", "footer\n"
    definition = prepare "a.rb",   "  body"

    assert_output_equal %q{
      # Generated by Linecook
      header
      module A
        doc
        module B
          head
          def a()
            body
            chain_proxy
          end

          def _a(*args, &block) # :nodoc:
            str = capture_str { a(*args, &block) }
            str.strip!
            str
          end
          foot
        end
      end
      footer
    }, cmd.build("A::B", [header, head, doc, foot, footer, definition])
  end

  def test_build_raises_error_for_invalid_formats
    definition = prepare("method_name.json") {|io| }

    err = assert_raises(::Linecook::CommandError) { cmd.build("A::B", [definition]) }
    assert_equal "invalid definition format: \".json\" (#{definition.inspect})", err.message
  end

  def test_build_raises_error_for_non_word_method_definitions
    definition = prepare "-.rb", %{
      Override minus, for why?
      (arg)
      --
    }

    err = assert_raises(::Linecook::CommandError) { cmd.build("A::B", [definition]) }
    assert_equal "invalid method name: \"-\" (#{definition.inspect})", err.message
  end
end