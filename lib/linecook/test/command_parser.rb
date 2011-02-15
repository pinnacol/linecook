module Linecook
  module Test
    class CommandParser
      attr_reader :ps1
      attr_reader :ps2
      attr_reader :prefix
      attr_reader :suffix
      
      def initialize(options={})
        options = {
          :ps1 => '% ',
          :ps2 => '> ',
          :prefix => '0<&- 2>&1 ',
          :suffix => ''
        }.merge(options)
        
        @ps1 = options[:ps1]
        @ps2 = options[:ps2]
        @prefix = options[:prefix]
        @suffix = options[:suffix]
      end
      
      def parse_cmd(cmd)
        cmd =~ /.*?#\s*(?:\[(\d+)\])?\s*(\.{3})?/
        exit_status = $1 ? $1.to_i : 0
        output = $2 ? nil : ""
        
        [cmd, output, exit_status]
      end
      
      def parse(script)
        commands = []
        
        command, output, exit_status = nil, "", 0
        script.each_line do |line|
          case
          when line.index(ps1) == 0
            if command
              commands << ["#{prefix}#{command}#{suffix}", output, exit_status]
            end
            
            command, output, exit_status = parse_cmd lchomp(ps1, line)
            
          when command.nil?
            unless line.strip.empty?
              command, output, exit_status = parse_cmd(line)
            end
            
          when line.index(ps2) == 0
            command << lchomp(ps2, line)
          
          when output.nil?
            output = line
          
          else
            output << line
          end
        end
        
        if command
          commands << ["#{prefix}#{command}#{suffix}", output, exit_status]
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