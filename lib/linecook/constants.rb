module Linecook
  DEFAULT_VM_NAME         = ENV['LINECOOK_VM_NAME'] || 'vbox'
  DEFAULT_HOSTNAME        = ENV['LINECOOK_HOSTNAME'] || 'vbox'
  DEFAULT_SSH_CONFIG_FILE = ENV['LINECOOK_SSH_CONFIG_FILE'] || 'config/ssh'
end