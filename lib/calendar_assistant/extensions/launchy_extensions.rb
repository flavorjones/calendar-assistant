require "launchy"

#
#  extend Launchy to handle zoom web URLs via the zoom commandline
#  executable.
#
#  note this doesn't handle "personal links" like
#
#    "https://robin.zoom.us/my/usernamehere"
#
#  which depends on an http 302 redirect from the zoom site
#
class CalendarAssistant
  class ZoomLaunchy < Launchy::Application::Browser
    ZOOM_URI_REGEXP = %r(https?://\w+.zoom.us/j/(\d+))

    def self.handles? uri
      return true if ZOOM_URI_REGEXP.match(uri)
    end

    def darwin_app_list
      [find_executable("open")]
    end

    def nix_app_list
      [find_executable("xdg-open")]
    end

    def open uri, options={}
      command = host_os_family.app_list(self).compact.first
      if command.nil?
        super uri, options
      else
        confno = ZOOM_URI_REGEXP.match(uri)[1]
        url = "zoommtg://zoom.us/join?confno=#{confno}"
        run command, [url]
      end
    end
  end
end

# we need to be first so we get right of first refusal on `https?` URLs
Launchy::Application.children.delete(CalendarAssistant::ZoomLaunchy)
Launchy::Application.children.prepend(CalendarAssistant::ZoomLaunchy)
