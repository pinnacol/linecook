module Linecook

  # Attributes provides a context for specifying default attributes.  For
  # example:
  #
  #   attributes = Attributes.new
  #   attributes.instance_eval %{
  #     attrs['a'] = 'A'
  #     attrs['b']['c'] = 'C'
  #   }
  #
  #   attributes.to_hash
  #   # => {'a' => 'A', 'b' => {'c' => 'C'}}
  #
  # Note that attrs is an auto-filling nested hash, making it easy to set
  # nested attributes, but it is not indifferent, meaning you do need to
  # differentiate between symbols and strings.  Normally strings are
  # preferred.
  class Attributes
    # A proc used to create nest_hash hashes
    NEST_HASH_PROC = Proc.new do |hash, key|
      hash[key] = Hash.new(&NEST_HASH_PROC)
    end

    class << self
      # Returns an auto-filling nested hash.
      def nest_hash
        Hash.new(&NEST_HASH_PROC)
      end

      # Recursively disables automatic nesting of nest_hash hashes.
      def disable_nest_hash(hash)
        if hash.default_proc == NEST_HASH_PROC
          hash.default = nil
        end

        hash.each_pair do |key, value|
          if value.kind_of?(Hash)
            disable_nest_hash(value)
          end
        end

        hash
      end
    end

    # A list of file extnames that may be loaded by load_attrs
    EXTNAMES = %w{.rb .yml .yaml .json}

    # An auto-filling nested hash
    attr_reader :attrs

    def initialize
      @attrs = Attributes.nest_hash
    end

    # Loads the attributes file into attrs. The loading mechanism depends on
    # the file extname:
    #
    #   .rb: evaluate in the context of attributes
    #   .yml,.yaml,.json: load as YAML and merge into attrs
    #
    # All other file types raise an error.
    def load_attrs(path)
      case File.extname(path)
      when '.rb'
        instance_eval(File.read(path), path)
      when '.yml', '.yaml', '.json'
        attrs.merge!(YAML.load_file(path))
      else
        raise "unsupported attributes format: #{path.inspect}"
      end

      self
    end

    # Disables automatic nesting and returns attrs.
    def to_hash
      Attributes.disable_nest_hash(attrs)
    end
  end
end