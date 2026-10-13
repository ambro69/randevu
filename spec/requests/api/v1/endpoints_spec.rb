require "rails_helper"

RSpec.describe "Api::V1::Endpoints endpoint", type: :request do
  # Rails 8.1 host authorization (test env allows .localhost/.test/IPs only)
  # rejects the request-spec default host www.example.com with 403 before
  # routing; use an allowed host so the endpoint itself is exercised.
  before { host! "example.test" }

  let(:expected_listing) do
    [
      { "method" => "GET", "path" => "/api/v1/health" },
      { "method" => "GET", "path" => "/api/v1/endpoints" }
    ]
  end

  it "returns HTTP 200 with a JSON content type" do
    get "/api/v1/endpoints"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
  end

  it "lists every /api/v1 route with method and path, including itself" do
    get "/api/v1/endpoints"

    expect(JSON.parse(response.body)).to eq(expected_listing)
  end

  it "is accessible without authentication" do
    get "/api/v1/endpoints"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq(expected_listing)
  end

  # Regression per REQ-009/AC-007: the root endpoints behave exactly as before.
  it "leaves the root /up endpoint unchanged" do
    get "/up"

    expect(response).to have_http_status(:ok)
  end

  it "leaves the root /health endpoint unchanged" do
    get "/health"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq("status" => "ok")
  end
end
