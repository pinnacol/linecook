module Linecook
  module Test
    class CommandParser
      attr_reader :ps1
      attr_reader :ps2
      
      def initialize(options={})
        options = {
          :ps1 => '% ',
          :ps2 => '> '
        }.merge(options)
        
        @ps1 = options[:ps1]
        @ps2 = options[:ps2]
        ps1_length = ps1.length
        
        
        ps2_length = ps2.length
      end
      
      def parse_exit_status(line)
        line =~ /# \[(\d+)\]\s*$/ ? $1.to_i : 0
      end
      
      def parse(script)
        commands = []
        
        command, output, exit_status = nil, nil, 0
        script.each_line do |line|
          case
          when line.index(ps1) == 0
            if command
              commands << [command, output.join, exit_status]
            end
            
            command = lchomp(ps1, line)
            exit_status = parse_exit_status(line)
            output  = []
            
          when command.nil?
            unless line.strip.empty?
              command, output = line, []
            end
            
          when line.index(ps2) == 0
            command << lchomp(ps2, line)
            
          else
            output << line
          end
        end
        
        if command
          commands << [command, output.join, exit_status]
        end
        
        commands
      end
      
      private
      
      def lchomp(prefix, line) # :nodoc:
        length = prefix.length
        line[length, line.length - length]
      end
    end
  end
end