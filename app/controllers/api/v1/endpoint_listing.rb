module Api
  module V1
    # Derives the /api/v1 endpoint listing from the live route table. Plain-Ruby
    # helper (no dependency): reads only the in-memory routing data — no DB, no
    # writes, no mutable state (REQ-010/AC-008). Dynamic by construction
    # (REQ-008/AC-006): any route added under /api/v1 shows up here without
    # changes to this code.
    module EndpointListing
      # Standard HTTP methods, used to decode Regexp-style route verbs.
      HTTP_METHODS = %w[GET POST PUT PATCH DELETE OPTIONS HEAD TRACE CONNECT].freeze

      module_function

      # Returns a sorted array of { "method" => String, "path" => String }
      # entries — one per route whose path starts with /api/v1/, including
      # /api/v1/endpoints itself.
      #
      # Ordering: AC-005/TEST-005 pin the expected array as
      # [ /api/v1/health, /api/v1/endpoints ]. Lexicographic ascending would
      # place "endpoints" before "health" ("e" < "h"), so the listing sorts by
      # path descending to reproduce the plan's specified order, with a
      # deterministic ascending method tie-break for identical paths.
      def call(routes = Rails.application.routes.routes)
        routes.flat_map { |route| entries_for(route) }.sort do |a, b|
          order = b["path"] <=> a["path"] # path, descending
          order.zero? ? a["method"] <=> b["method"] : order # method, ascending
        end
      end

      # One entry per HTTP verb for a single route, or [] when the route is
      # outside the /api/v1 namespace or carries no extractable verb.
      def entries_for(route)
        path = route.path.spec.to_s
        return [] unless path.start_with?("/api/v1/")

        verbs_for(route.verb).map do |verb|
          { "method" => verb, "path" => normalize_path(path) }
        end
      end

      # Extracts HTTP method names from a route verb. Current route table uses
      # plain Strings ("GET"); future multi-verb routes yield a Regexp (e.g.
      # /^GET|POST$/), handled generically here.
      def verbs_for(verb)
        case verb
        when String
          [ verb ]
        when Regexp
          verb.source.scan(/[A-Z]+/).select { |method| HTTP_METHODS.include?(method) }.uniq
        else
          []
        end
      end

      # Strips the optional format suffix, e.g. "/api/v1/health(.:format)"
      # -> "/api/v1/health".
      def normalize_path(path)
        path.sub(/\(\.:format\)\z/, "")
      end
    end
  end
end
