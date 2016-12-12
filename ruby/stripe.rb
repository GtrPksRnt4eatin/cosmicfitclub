require 'stripe'
require_relative 'environment.rb'

Stripe.api_key = ENV['STRIPE_SECRET']