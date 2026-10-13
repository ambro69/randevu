class PagesController < ApplicationController
  # Browser-facing landing page, served at the root URL ("/"). Renders the
  # shared application layout via the implicit-render convention
  # (app/views/pages/home.html.erb).
  def home
  end
end
