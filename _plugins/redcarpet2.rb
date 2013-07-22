require 'jekyll'

class Jekyll::Converters::Markdown::RedcarpetParser

  alias_method :original_initialize, :initialize

  def initialize(config)
    original_initialize(config)

    @renderer.class_eval do
      def header(text, level)
        id = text.downcase.gsub('&#39;', '').gsub(/[^a-z1-9]+/, '-').chomp('-')
        "<h#{level} id='#{id}'>#{text}</h#{level}>"
      end
    end
  end

end
