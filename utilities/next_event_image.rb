$root_folder = File.expand_path('..', __FILE__)
require_relative '../integrations/database'
Dir[File.expand_path('../models/mixins/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../models/**/*.rb',     __FILE__)].each { |f| require f }

event = Event.where(Sequel.lit('start_time > NOW()')).order(:start_time).first
puts "Event: #{event.name} (#{event.id}) @ #{event.start_time}"
puts "Image URL: #{event.image(:original).url}"
