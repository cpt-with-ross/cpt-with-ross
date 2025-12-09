# frozen_string_literal: true

module MarkdownHelper
  def markdown(text)
    return '' if text.blank?

    renderer = Redcarpet::Render::HTML.new(
      filter_html: true,
      no_images: true,
      no_links: false,
      no_styles: true,
      safe_links_only: true,
      hard_wrap: true
    )

    markdown_parser = Redcarpet::Markdown.new(
      renderer,
      autolink: true,
      no_intra_emphasis: true,
      strikethrough: true,
      underline: true
    )

    sanitize(markdown_parser.render(text))
  end
end
