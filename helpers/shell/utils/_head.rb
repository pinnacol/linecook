require 'linecook/shell/posix'
include Posix

DEFAULT_SHELL_PATH = '/bin/bash'
SCRIPT_PATH = '$LINECOOK_DIR/%s'

attr_writer :shell_path

def shell_path
  @shell_path ||= DEFAULT_SHELL_PATH
end

def script_path(source_path, basename=nil)
  SCRIPT_PATH % super(source_path, basename=nil)
end

def close
  unless closed?
    break_line " (#{script_name}) "
  end
  
  super
end