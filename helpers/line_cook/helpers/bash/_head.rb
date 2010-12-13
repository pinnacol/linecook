include LineCook::Utils

DEFAULT_BASH_PATH = '/bin/bash'
DEFAULT_ENV_PATH  = '/usr/bin/env'

TARGET_PATH = '$LINECOOK_DIR/%s'

attr_writer :bash_path
attr_writer :env_path

def bash_path
  @bash_path ||= DEFAULT_BASH_PATH
end

def env_path
  @env_path ||= DEFAULT_ENV_PATH
end

def target_path(source_path)
  TARGET_PATH % super
end

def close
  unless closed?
    break_line " (#{target_name}) "
  end
  
  super
end