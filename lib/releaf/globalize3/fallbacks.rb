module Releaf
  module Globalize3
    module Fallbacks
      def self.set
        i18n_fallbacks = {}

        I18n.default_locale ||= 'en'
        I18n.locale ||= 'en'

        valid_locales = Settings.i18n_locales || []

        (valid_locales + [I18n.default_locale.to_s, I18n.locale.to_s]).uniq.each do |locale|
          #  "locale" must be first in list
          i18n_fallbacks[locale] = [locale] + (valid_locales - [locale])
        end
        Globalize.fallbacks = i18n_fallbacks
      end
    end
  end
end
