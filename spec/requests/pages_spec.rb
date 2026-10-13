require "rails_helper"

RSpec.describe "Landing page", type: :request do
  # Rails 8.1 host authorization (test env allows .localhost/.test/IPs only)
  # rejects the request-spec default host www.example.com with 403 before
  # routing; use an allowed host so the endpoint itself is exercised.
  before { host! "example.test" }

  let(:description) do
    "Randevu aggregates your calendars and meetings from connected mail accounts in one place."
  end

  describe "GET /" do
    it "returns HTTP 200" do
      get "/"

      expect(response).to have_http_status(:ok)
    end

    it "responds as HTML rendered with the application layout" do
      get "/"

      expect(response.media_type).to eq("text/html")
      expect(response.body).to include("<!DOCTYPE html>")
      expect(response.body).to include("<body>")
    end

    it "shows the application name" do
      get "/"

      expect(response.body).to include("Randevu")
    end

    it "shows the one-line description" do
      get "/"

      expect(response.body).to include(description)
    end
  end

  describe "shared application layout chrome" do
    it "renders a header landmark with the app name linked to /" do
      get "/"

      header = Nokogiri::HTML(response.body).at_css("header")
      expect(header).not_to be_nil
      expect(header.text).to include("Randevu")

      brand_link = header.at_css("a")
      expect(brand_link).not_to be_nil
      expect(brand_link.text.strip).to eq("Randevu")
      expect(brand_link["href"]).to eq("/")
    end

    it "renders a footer landmark with a Randevu copyright line" do
      get "/"

      footer = Nokogiri::HTML(response.body).at_css("footer")
      expect(footer).not_to be_nil
      expect(footer.text).to include("Randevu")
      expect(footer.text).to match(/©|\(c\)|copyright/i)
    end
  end

  describe "root route" do
    it "maps / to pages#home" do
      expect(Rails.application.routes.recognize_path("/", method: :get))
        .to eq(controller: "pages", action: "home")
    end

    it "resolves root_path to the landing page at /" do
      expect(root_path).to eq("/")
    end

    it "is served by a browser-facing controller inheriting ApplicationController" do
      expect(PagesController < ApplicationController).to be(true)
    end
  end
end
