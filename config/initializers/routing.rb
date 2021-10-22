class ActionDispatch::Routing::Mapper
  def draw(route_file)
    instance_eval(File.read(Rails.root.join("config/routes/#{route_file}.rb")))
  end

  def draw_custom(route_file)
    instance_eval(File.read(Rails.root.join("config","custom", Rails.application.config.cm, "routes", "#{route_file}.rb")))
  end
end
