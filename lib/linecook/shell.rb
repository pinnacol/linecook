require 'linecook/shell/posix'
require 'linecook/shell/unix'

module Linecook
  module Shell
    include Posix
    include Unix
  end
end