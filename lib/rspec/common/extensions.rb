Dir.glob(File.expand_path("extensions/**/*.rb", __dir__)).each do |path|
  require path
end
