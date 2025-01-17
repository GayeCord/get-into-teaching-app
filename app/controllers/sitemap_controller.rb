class SitemapController < ApplicationController
  DEFAULT_LASTMOD = "2021-03-01".freeze

  ALIASES = {
    "/home" => "/",
  }.freeze

  OTHER_PATHS = %w[
    /events
    /event-categories/train-to-teach-events
    /event-categories/online-q-as
    /event-categories/school-and-university-events
    /mailinglist/signup/name
  ].freeze

  def show
    render xml: build.to_xml
  end

private

  def build
    Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
        published_pages.each do |path, metadata|
          xml.url do
            xml.loc(request.base_url + page_location(path))
            xml.lastmod(metadata.fetch(:date) { DEFAULT_LASTMOD })
            xml.priority(metadata.fetch(:priority)) if metadata.key?(:priority)
          end
        end

        OTHER_PATHS.each do |events_path|
          xml.url do
            xml.loc(request.base_url + events_path)
            xml.lastmod(DEFAULT_LASTMOD)
          end
        end
      end
    end
  end

  def published_pages
    Pages::Frontmatter.list.reject { |_path, fm| fm[:draft] }
  end

  def page_location(path)
    ALIASES.fetch(path) { path }
  end
end
