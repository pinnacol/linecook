require 'configurable'

module Linecook
  module CommandUtils
    include Configurable

    config :quiet, false  # -q, --quiet : silence output

    def sh(cmd)
      $stderr.puts "$ #{cmd}" unless quiet
      system(cmd)
    end

    def sh!(cmd)
      unless sh(cmd)
        raise CommandError, "non-zero exit status: #{$?.exitstatus}"
      end
    end
  end
end