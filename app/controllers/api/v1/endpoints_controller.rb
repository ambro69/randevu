module Api
  module V1
    # Self-describing endpoint listing: renders the method + path of every route
    # under /api/v1, derived at request time from the live route table (see
    # EndpointListing). No DB access, no writes (REQ-010/AC-008).
    class EndpointsController < BaseController
      def index
        render json: Api::V1::EndpointListing.call
      end
    end
  end
end
