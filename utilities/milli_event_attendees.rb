#!/usr/bin/env ruby
# Generates attendee email lists for all events mentioning Milli Gobli
# in the event name, subheading, or description.
#
# Usage (from repo root):
#   rvm 3.2.2 do bundle exec ruby utilities/milli_event_attendees.rb

require 'bigdecimal'
require 'sinatra'
Dir.chdir(File.join(__dir__, '..'))
require_relative '../ruby/environment'
require_relative '../ruby/patches'
require_relative '../integrations/database'
Dir["models/mixins/*.rb"].each  { |f| require_relative "../#{f}" unless f =~ /Routes/ }
Dir["models/**/*.rb"].each      { |f| require_relative "../#{f}" unless f =~ /Routes/ }

# ── Search events by text ────────────────────────────────────────────────────
SEARCH_TERMS = ['milli', 'gobli']

matching_events = Event.all.select do |e|
  fields = [e[:name], e[:subheading], e[:description]].compact.join(' ').downcase
  SEARCH_TERMS.any? { |term| fields.include?(term) }
end

if matching_events.empty?
  puts "No events found mentioning Milli / Gobli in name, subheading, or description."
  exit 0
end

puts "Matching events (#{matching_events.count}):"
matching_events.sort_by { |e| e[:starttime] || Time.at(0) }.each do |e|
  puts "  [#{e.id}] #{e.name}  #{e.starttime&.strftime('%Y-%m-%d') || 'no date'}"
end
puts

# ── Collect attendees from tickets ───────────────────────────────────────────
event_ids = matching_events.map(&:id)
tickets   = EventTicket.where(event_id: event_ids).all

attendees = tickets.map do |t|
  c = t.recipient || t.customer
  next unless c
  { name: c.name.to_s.strip, email: c.email.to_s.strip.downcase }
end.compact

attendees = attendees.uniq { |a| a[:email] }.reject { |a| a[:email].empty? }.sort_by { |a| a[:name] }

puts "Unique attendees: #{attendees.count}"
puts

# ── Write outputs ─────────────────────────────────────────────────────────────
emails_file = File.join(__dir__, 'milli_attendee_emails.txt')
File.open(emails_file, 'w') { |f| attendees.each { |a| f.puts a[:email] } }
puts "Emails written to:       #{emails_file}"

require 'csv'
csv_file = File.join(__dir__, 'milli_attendee_list.csv')
CSV.open(csv_file, 'w') do |csv|
  csv << ['Name', 'Email']
  attendees.each { |a| csv << [a[:name], a[:email]] }
end
puts "Name + email written to: #{csv_file}"

puts
puts "── Emails only ─────────────────────────────────────────────────────────"
attendees.each { |a| puts a[:email] }

puts
puts "── Name + Email ────────────────────────────────────────────────────────"
attendees.each { |a| puts "#{a[:name]}, #{a[:email]}" }
