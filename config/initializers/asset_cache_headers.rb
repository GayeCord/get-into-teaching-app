if ENV["APP_URL"].present?
  Rails.application.config.public_file_server.headers = {
    "Cache-Control" => "max-age=31536000, public, immutable",
    "Access-Control-Allow-Origin" => ENV["APP_URL"],
  }
end
