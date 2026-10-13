module Api
  module V1
    # Namespaced health check mirroring the root /health semantics: renders the
    # static JSON literal { "status": "ok" } with HTTP 200 / application/json.
    # No model/DB access, no writes (REQ-010/AC-008 by construction).
    class HealthController < BaseController
      def show
        render json: { status: "ok" }
      end
    end
  end
end
