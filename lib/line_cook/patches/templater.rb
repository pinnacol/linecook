require 'tap/templater'

class Tap::Templater < OpenStruct
  # Build the template, setting the attributes and filename if specified.
  # All methods of self will be accessible in the template.
  def build(_attrs_=nil, _filename_=nil)
    _attrs_.each_pair do |key, value|
      send("#{key}=", value)
    end if _attrs_
    
    @template.filename = _filename_
    @template.result(binding)
    @_erbout
  end
end
