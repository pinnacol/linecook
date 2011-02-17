module Linecook
  module Commands
    class CommandError < RuntimeError
      attr_reader :exitstatus
      
      def initialize(msg, exitstatus=1)
        @exitstatus = exitstatus
        super(msg)
      end
    end
  end
end