require "rails_helper"

RSpec.describe Api::V1::EndpointListing do
  # Synthetic ActionDispatch::Journey::Route doubles — only #path (spec string)
  # and #verb are consumed by the helper.
  def route(path, verb)
    double("route", path: double("path", spec: path), verb: verb)
  end

  describe ".call" do
    it "lists every /api/v1 route with method and path, including itself" do
      routes = [
        route("/api/v1/endpoints(.:format)", "GET"),
        route("/api/v1/health(.:format)", "GET")
      ]

      expect(described_class.call(routes)).to eq(
        [
          { "method" => "GET", "path" => "/api/v1/health" },
          { "method" => "GET", "path" => "/api/v1/endpoints" }
        ]
      )
    end

    it "excludes routes outside the /api/v1 namespace" do
      routes = [
        route("/api/v1/health(.:format)", "GET"),
        route("/up(.:format)", "GET"),
        route("/health(.:format)", "GET"),
        route("/rails/active_storage/disk/:encoded_key(.:format)", "GET"),
        route("/resume_historical_location(.:format)", "GET")
      ]

      expect(described_class.call(routes)).to eq(
        [ { "method" => "GET", "path" => "/api/v1/health" } ]
      )
    end

    it "strips the optional format suffix from paths" do
      routes = [ route("/api/v1/endpoints(.:format)", "GET") ]

      expect(described_class.call(routes).first["path"]).to eq("/api/v1/endpoints")
    end

    it "is dynamic: newly added /api/v1 routes appear without code changes" do
      routes = [
        route("/api/v1/ping(.:format)", "GET"),
        route("/api/v1/health(.:format)", "GET"),
        route("/api/v1/endpoints(.:format)", "GET")
      ]

      listing = described_class.call(routes)

      expect(listing).to include(
        { "method" => "GET", "path" => "/api/v1/ping" }
      )
      # Deterministic order with the extra route: by path descending (see
      # EndpointListing#call), so ping (p) precedes health (h).
      expect(listing).to eq(
        [
          { "method" => "GET", "path" => "/api/v1/ping" },
          { "method" => "GET", "path" => "/api/v1/health" },
          { "method" => "GET", "path" => "/api/v1/endpoints" }
        ]
      )
    end

    it "sorts deterministically by path with a method tie-break" do
      routes = [
        route("/api/v1/health(.:format)", "POST"),
        route("/api/v1/endpoints(.:format)", "GET"),
        route("/api/v1/health(.:format)", "GET")
      ]

      # Canonical order: by path; identical paths tie-break by method.
      expect(described_class.call(routes)).to eq(
        [
          { "method" => "GET", "path" => "/api/v1/health" },
          { "method" => "POST", "path" => "/api/v1/health" },
          { "method" => "GET", "path" => "/api/v1/endpoints" }
        ]
      )
    end

    it "extracts verbs from Regexp-style route verbs (future multi-verb routes)" do
      routes = [ route("/api/v1/health(.:format)", /^GET|POST$/) ]

      expect(described_class.call(routes)).to eq(
        [
          { "method" => "GET", "path" => "/api/v1/health" },
          { "method" => "POST", "path" => "/api/v1/health" }
        ]
      )
    end

    it "returns an empty array when no /api/v1 routes exist" do
      routes = [ route("/up(.:format)", "GET") ]

      expect(described_class.call(routes)).to eq([])
    end
  end
end
