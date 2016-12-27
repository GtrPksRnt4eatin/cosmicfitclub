require 'sinatra/base'
require 'pry'

class CFC < Sinatra::Base

  helpers  Sinatra::ViewHelpers
  register Sinatra::PageFolders
  register Sinatra::SharedResources

  set :root, File.dirname(__FILE__)

  get( '/' )        { render_page :index    } 
  get( '/classes')  { render_page :classes  }
  get( '/training') { render_page :training }
  get( '/events')   { render_page :events   }
  get( '/schedule') { render_page :schedule }
  get( '/staff')    { render_page :staff    }
  get( '/pricing')  { render_page :pricing  }
  get( '/faq')      { render_page :faq      }
  get( '/store')    { render_page :store    }

  post '/charge' do

    data = JSON.parse request.body.read
  
    if data['type'] == 'plan' then
      customer = Stripe::Customer.create(
        :source   => data['token']['id'],
        :plan     => data['plan_id'],
        :email    => data['token']['email'],
        :metadata => { :name => data['token']['card']['name'] } 
      )
    end

#  charge = Stripe::Charge.create(
#    :amount      => @amount,
#    :description => 'Sinatra Charge',
#    :currency    => 'usd',
#    :customer    => customer.id
#  )

#  slim :charged
  end 

  error Stripe::CardError do
    env['sinatra.error'].message
  end

  get '/slides' do
    JSON.generate Slide.all.map { |s| { :id => s.id, :data => JSON.parse(s.image_data)['metadata'], :url => s.image_url } }
  end

end