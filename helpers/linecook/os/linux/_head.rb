require 'linecook/os/posix'
include Posix

require 'linecook/os/linux/utilities'
include Utilities

def capture_script(options={})
  unless options.kind_of?(Hash)
    options = {:target_name => options}
  end

  options[:mode] ||= 0770
  target_name = options.delete(:target_name) || _package_.next_target_path('script')
  path = capture_path(target_name, options) { yield }

  owner, group = options[:owner], options[:group]
  if owner || group
    callback 'before' do
      chown owner, group, path
    end
  end

  path
end
