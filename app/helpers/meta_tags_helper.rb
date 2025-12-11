# frozen_string_literal: true

# =============================================================================
# MetaTagsHelper - Open Graph and Twitter Card Meta Tags
# =============================================================================
#
# Provides SEO and social sharing meta tags for the application.
#
# PRIVACY CONSIDERATIONS:
# This is a mental health application for PTSD therapy. User content (stuck
# points, worksheets, therapy notes) is highly sensitive and must NEVER be
# exposed in meta tags, as these appear in:
# - Social media link previews
# - Browser history
# - Shared URLs
# - Search engine results
#
# All descriptions use generic, app-level text regardless of page content.
# Only page titles (which use safe model fallbacks like "ABC #3") are dynamic.
#
# Open Graph Reference: https://ogp.me/
# Twitter Cards Reference: https://developer.twitter.com/en/docs/twitter-for-websites/cards
#
module MetaTagsHelper
  # Base application metadata
  APP_NAME = 'CPT with Ross'
  APP_DESCRIPTION = 'AI-powered Cognitive Processing Therapy assistant for PTSD recovery and healing'
  APP_KEYWORDS = 'PTSD, CPT, Cognitive Processing Therapy, trauma therapy, mental health, ' \
                 'PTSD treatment, therapy assistant'

  # OG Image filename (place PNG version at public/og-image.png for production)
  OG_IMAGE_FILENAME = 'og-image.png'

  # Renders all meta tags for the <head> section.
  # Call this once in your layout: <%= render_meta_tags %>
  def render_meta_tags
    safe_join([
                tag.meta(name: 'description', content: meta_description),
                tag.meta(name: 'keywords', content: APP_KEYWORDS),
                render_open_graph_tags,
                render_twitter_card_tags
              ], "\n    ")
  end

  # Standard meta description for SEO.
  # Uses page-specific description if set, otherwise falls back to app description.
  def meta_description
    content_for?(:meta_description) ? content_for(:meta_description) : APP_DESCRIPTION
  end

  private

  # Renders Open Graph protocol meta tags for Facebook, LinkedIn, etc.
  def render_open_graph_tags
    safe_join([
                tag.meta(property: 'og:type', content: 'website'),
                tag.meta(property: 'og:site_name', content: APP_NAME),
                tag.meta(property: 'og:title', content: og_title),
                tag.meta(property: 'og:description', content: og_description),
                tag.meta(property: 'og:image', content: og_image_url),
                tag.meta(property: 'og:image:width', content: '1200'),
                tag.meta(property: 'og:image:height', content: '630'),
                tag.meta(property: 'og:image:alt', content: "#{APP_NAME} - Untangling thoughts, finding clarity"),
                tag.meta(property: 'og:url', content: og_canonical_url),
                tag.meta(property: 'og:locale', content: 'en_US')
              ], "\n    ")
  end

  # Renders Twitter Card meta tags for Twitter/X previews.
  def render_twitter_card_tags
    safe_join([
                tag.meta(name: 'twitter:card', content: 'summary_large_image'),
                tag.meta(name: 'twitter:title', content: og_title),
                tag.meta(name: 'twitter:description', content: og_description),
                tag.meta(name: 'twitter:image', content: og_image_url),
                tag.meta(name: 'twitter:image:alt', content: "#{APP_NAME} - Untangling thoughts, finding clarity")
              ], "\n    ")
  end

  # Returns the page title for OG tags.
  # Reuses the page_title helper which already handles privacy-safe fallbacks.
  def og_title
    page_title
  end

  # Returns a privacy-safe description for OG tags.
  # IMPORTANT: Always returns generic app description to protect user privacy.
  # Never expose page-specific content that could reveal therapy details.
  def og_description
    APP_DESCRIPTION
  end

  # Returns the absolute URL for the OG image.
  # Uses the dedicated OG image from the public directory.
  def og_image_url
    if request.present?
      "#{request.protocol}#{request.host_with_port}/#{OG_IMAGE_FILENAME}"
    else
      # Fallback for mailers or background jobs
      host = Rails.application.config.action_mailer.default_url_options[:host] || 'localhost:3000'
      host = host.gsub(%r{https?://}, '')
      "https://#{host}/#{OG_IMAGE_FILENAME}"
    end
  end

  # Returns the canonical URL for the current page.
  # Used by social platforms to identify the authoritative URL.
  def og_canonical_url
    request.original_url
  end
end
