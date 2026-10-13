require "rails_helper"

RSpec.describe "Api::V1::Health endpoint", type: :request do
  # Rails 8.1 host authorization (test env allows .localhost/.test/IPs only)
  # rejects the request-spec default host www.example.com with 403 before
  # routing; use an allowed host so the endpoint itself is exercised.
  before { host! "example.test" }

  it "returns HTTP 200" do
    get "/api/v1/health"

    expect(response).to have_http_status(:ok)
  end

  it "responds with a JSON content type" do
    get "/api/v1/health"

    expect(response.media_type).to eq("application/json")
  end

  it "returns a body with status ok" do
    get "/api/v1/health"

    expect(JSON.parse(response.body)).to eq("status" => "ok")
  end

  it "is accessible without authentication" do
    get "/api/v1/health"

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq("status" => "ok")
  end
end
