require 'erb'
require 'ostruct'

module Linecook
  class Template
    attr_reader :erb
    
    def initialize(filename)
      @erb = ERB.new File.read(filename)
      @erb.filename = filename
    end
    
    def build(locals={})
      erb.result OpenStruct.new(locals).instance_eval('binding')
    end
  end
end