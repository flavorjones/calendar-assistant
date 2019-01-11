require "clipboard"

module Clipboard
  module Linux

    def copy(data)
      CLIPBOARDS.each do |which|
        Utils.popen "xclip -select #{which} -t 'text/html'", data, ReadOutputStream
      end
      paste
    end
  end
end
