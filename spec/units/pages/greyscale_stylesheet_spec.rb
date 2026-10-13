require "rails_helper"

# AC-005 / REQ-007: the landing page stylesheet must use only greyscale values
# and must not introduce a CSS framework or any new dependency. These are
# static properties of the stylesheet and the dependency manifests, so they are
# checked directly rather than through a rendered page (non-DB spec).
RSpec.describe "Greyscale-only landing page styling" do
  GREYSCALE_NAMED_COLORS = %w[
    black white gray grey silver gainsboro
    darkgray darkgrey dimgray dimgrey lightgray lightgrey
    transparent currentcolor
  ].freeze

  NON_COLOR_CSS_KEYWORDS = %w[
    solid dashed dotted double none auto inherit initial unset revert
    thin medium thick normal inset outset
  ].freeze

  COLOR_PROPERTY = /\A(?:
    color|background|background-color|
    border|border-color|border-(?:top|right|bottom|left)(?:-color)?|
    outline|outline-color|fill|stroke|box-shadow|text-shadow
  )\z/x

  let(:stylesheet) { File.read(Rails.root.join("app/assets/stylesheets/application.css")) }

  it "uses only greyscale hex color literals" do
    hexes = stylesheet.scan(/#[0-9a-fA-F]{3,8}/).uniq
    expect(hexes).not_to be_empty

    hexes.each do |hex|
      channels = hex_channels(hex)
      expect(channels).not_to be_nil, "unexpected hex color literal #{hex}"
      expect(channels.uniq.length).to eq(1), "#{hex} is not greyscale"
    end
  end

  it "uses only greyscale rgb()/rgba() color literals" do
    stylesheet.scan(/rgba?\(([^)]*)\)/).each do |(args)|
      channels = args.split(",").map(&:strip).first(3)
      expect(channels.uniq.length).to eq(1), "rgb(#{args}) is not greyscale"
    end
  end

  it "uses only greyscale named color keywords in color declarations" do
    values = stylesheet.scan(/([a-z-]+)\s*:\s*([^;}]+)/i)
                      .select { |property, _| COLOR_PROPERTY.match?(property.downcase) }
                      .map(&:last)
    expect(values).not_to be_empty

    named_tokens = values.flat_map do |value|
      value
        .gsub(/var\([^)]*\)/, " ")
        .gsub(/rgba?\([^)]*\)/, " ")
        .gsub(/#[0-9a-fA-F]+/, " ")
        .gsub(/\b\d+(?:\.\d+)?[a-z%]*\b/i, " ")
        .split(/[\s,]+/)
        .map { |token| token.downcase.gsub(/[^a-z]/, "") }
        .reject(&:empty?)
    end

    unknown = (named_tokens.uniq - GREYSCALE_NAMED_COLORS - NON_COLOR_CSS_KEYWORDS)
    expect(unknown).to eq([]), "non-greyscale color keywords used: #{unknown.inspect}"
  end

  it "does not reference a CSS framework or an external stylesheet" do
    expect(stylesheet).not_to match(%r{@import\s+(?:url\()?["']?https?:}i)
    expect(stylesheet).not_to match(/tailwind|bootstrap|bulma|foundation|spectre|purecss|materialize/i)
  end

  it "does not add a CSS framework dependency to the Gemfile or importmap" do
    gemfile = File.read(Rails.root.join("Gemfile"))
    importmap = File.read(Rails.root.join("config/importmap.rb"))

    expect(gemfile).not_to match(/tailwind|bootstrap|bulma|foundation|spectre|cssbundling|dartsass|sassc/i)
    expect(importmap).not_to match(/tailwind|bootstrap|bulma|foundation|spectre/i)
  end

  # Returns the three colour channels of a hex literal, or nil if malformed.
  def hex_channels(hex)
    digits = hex.delete_prefix("#")
    case digits.length
    when 3, 4 then digits.chars.first(3)
    when 6, 8 then digits.chars.each_slice(2).map(&:join).first(3)
    end
  end
end
