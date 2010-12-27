require 'linecook/shell/posix'
require 'linecook/shell/unix'
require 'linecook/shell/utils'

module Linecook
  module Shell
    include Posix
    include Unix
    include Utils
  end
end