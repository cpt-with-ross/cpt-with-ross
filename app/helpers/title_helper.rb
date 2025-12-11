# frozen_string_literal: true

# =============================================================================
# TitleHelper - Dynamic Page Title Generation for SEO and UX
# =============================================================================
#
# Provides consistent, SEO-optimized page titles across the application.
#
# SEO Best Practices Applied:
# - Titles are 50-60 characters (optimal for search engine display)
# - Primary keywords included (PTSD, CPT, Therapy)
# - Unique titles per page for better indexing
# - Brand name at the end for recognition
#
# Usage in views:
#   <% content_for :title, "Dashboard" %>
#   <% content_for :title, @abc_worksheet.title %>
#
# Privacy note: Avoid using stuck point statements in titles as they may
# contain sensitive trauma-related content visible in browser history.
# Use the model's `title` method which provides safe fallbacks like "ABC #3".
#
module TitleHelper
  BASE_TITLE = 'CPT with Ross - PTSD Therapy Assistant'
  SHORT_BRAND = 'CPT with Ross'

  BASELINE_SECTION_TITLES = {
    'checklist' => 'PTSD Baseline Checklist',
    'pcl' => 'PCL-5 Symptom Assessment',
    'statement' => 'Impact Statement'
  }.freeze

  ALTERNATIVE_THOUGHT_SECTION_TITLES = {
    'exploring' => 'Exploring Questions',
    'patterns' => 'Thinking Patterns',
    'alternative' => 'Alternative Thought',
    'rerate' => 'Re-Rate Belief',
    'emotions_after' => 'Emotions After'
  }.freeze

  # Returns the full page title with consistent formatting.
  # Format: "Page Name | CPT with Ross - PTSD Therapy Assistant"
  # Falls back to the descriptive base title if no page-specific title is set.
  def page_title
    if content_for?(:title)
      page_specific = content_for(:title)
      # Keep total length reasonable for SEO (under 60 chars if possible)
      "#{page_specific} | #{SHORT_BRAND}"
    else
      BASE_TITLE
    end
  end

  # Returns the title for a baseline section
  def baseline_section_title(section)
    BASELINE_SECTION_TITLES[section] || 'Edit Baseline'
  end

  # Returns the title for an alternative thought section
  def alternative_thought_section_title(section)
    ALTERNATIVE_THOUGHT_SECTION_TITLES[section] || 'Edit'
  end
end
