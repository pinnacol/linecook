require 'linecook/shell/posix'
include Posix

DEFAULT_SHELL_PATH = '/bin/sh'
DEFAULT_ENV_PATH   = '/usr/bin/env'

TARGET_PATH = '$LINECOOK_DIR/%s'

attr_writer :shell_path
attr_writer :env_path

def shell_path
  @shell_path ||= DEFAULT_SHELL_PATH
end

def env_path
  @env_path ||= DEFAULT_ENV_PATH
end

def target_path(source_path)
  TARGET_PATH % super(source_path)
end

def close
  unless closed?
    section " (#{target_name}) "
  end
  
  super
end