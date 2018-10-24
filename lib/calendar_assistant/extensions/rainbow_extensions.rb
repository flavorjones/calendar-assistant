#
#  TODO: this file can be deleted once this PR gets merged:
#
#      https://github.com/sickill/rainbow/pull/84
#
require "rainbow"

module Rainbow
  class Presenter
    TERM_EFFECT_STRIKE = 9

    def strike
      wrap_with_sgr TERM_EFFECT_STRIKE
    end
  end

  class NullPresenter
    def strike
      self
    end
  end
end
