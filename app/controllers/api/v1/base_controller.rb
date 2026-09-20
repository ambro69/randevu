module Api
  module V1
    # Shared base controller for the /api/v1 namespace. Inherits
    # ActionController::Base (the /health precedent) so ApplicationController's
    # browser-gating filters (allow_browser, stale_when_importmap_changes) never
    # block non-browser API clients. All namespaced endpoints remain
    # unauthenticated and DB-free.
    class BaseController < ActionController::Base
    end
  end
end
