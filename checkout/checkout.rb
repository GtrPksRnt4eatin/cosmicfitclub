require 'rack/contrib'
require 'sinatra/base'
require_relative './extensions/checkouthelpers'
require_relative './extensions/paymentmethods'

class Checkout < Sinatra::Base

  ################################### CONFIG ####################################

  register Sinatra::Auth
  use JwtAuth
  use Rack::JSONBodyParser

  configure do
    enable :cross_origin
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control :no_cache
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  ################################### CONFIG ####################################

  helpers Sinatra::CheckoutHelpers
  helpers Sinatra::PaymentMethods
  
  set :root, File.dirname(__FILE__)

  register Sinatra::PageFolders
  register Sinatra::SharedResources
  helpers  Sinatra::ViewHelpers

  get('/plan/:id')                               { render_page :plan              }
  get('/pack/:id')                               { render_page :pack              }
  get('/training/:id')                           { render_page :training          }
  get('/event/:id')                              { render_page :event             }
  get('/event2/:id')                             { render_page :event2            }  
  get('/complete')                               { render_page :complete          }
  get('/misc')                                   { render_page :misc              }
  get('/front_desk')                             { render_page :front_desk        }
  get('/redeem_gift')                            { render_page :gift_cert         }
  get('/loft', :onboard => 'user')               { render_page :loft_rental       }
  get('/point', :onboard => 'user')              { render_page :loft_rental       }
  get('/group/:id')                              { render_page :group             }

  get('/transactions')                           { render_page :transactions      }

  get('/class_reg/:id',   :onboard => 'user'   ) { render_page :class_reg         }

  get('/class_checkin',   :auth => 'frontdesk' ) { render_page :class_checkin     } 
  get('/class_sheet/:id', :auth => 'frontdesk' ) { render_page :class_sheet       }
  get('/customer_file',   :auth => 'frontdesk' ) { render_page :customer_file     }

  post('/plan/charge')         { buy_plan             }
  post('/pack/charge')         { buy_pack             }
  post('/pack/buy')            { buy_pack_precharged  }
  post('/pack/intent')         { buy_pack_intent      }
  post('/donate/intent')       { donate_intent        }
  post('/training/charge')     { buy_training         }
  post('/event/precharged')    { buy_event_precharged }
  post('/event/charge')        { buy_event            }
  post('/event/charge_priv')   { buy_event_privates   }
  post('/event/passes')        { buy_event_passes     }
  post('/event/register')      { register_event       }
  post('/group/apply_payment') { group_payment        }
  post('/group/apply_passes')  { group_passes         }
  post('/misc/charge')         { buy_misc             }

  post('/charge_card')       { charge_card         }
  post('/charge_saved_card') { charge_saved_card   }
  post('/pay_cash')          { pay_cash            }

  post('/swipe')             { card_swipe          }

  get('/wait_for_swipe',    :auth => 'frontdesk' ) { wait_for_swipe      }

  post('/save_card',        :self_or => 'frontdesk' ) { save_card           }
  post('/set_default_card', :self_or => 'frontdesk' ) { set_default_card    }
  post('/remove_card',      :self_or => 'frontdesk' ) { remove_card         }

  post('/create_intent',    :jwt_logged_in=>true) { StripeMethods::get_payment_intent(params[:amount],params[:description],Customer[session["customer_id"]]) }
  post('/update_intent',    :jwt_logged_in=>true) { StripeMethods::update_intent(params[:amount],params[:description],params[:intent_id]) }
  post('/confirm_intent',   :jwt_logged_in=>true) { StripeMethods::confirm_intent }

  options "*" do
    response.headers["Allow"] = "GET, PUT, POST, DELETE, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
    origin_ok = ['https://video.cosmicfitclub.com', 'https://localhost:3000'].include? request.env["HTTP_ORIGIN"]
    response.headers['Access-Control-Allow-Origin'] = request.env["HTTP_ORIGIN"] if origin_ok
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    200
  end

  error do
    Slack.err( 'Checkout Error', env['sinatra.error'] )
    'An Error Occurred.'
    render_page :error
  end

  def rental_text
    %{
      THIS AGREEMENT (the “Agreement”), made as of 9/07/2019 (the “Booking Date”), 
      is by and between Cosmic Fit Club, and Event Organizer (each a “Party” and collectively, the “Parties”). 

      WHEREAS, Event Organizer desires to use the Space for the Event; and 
      WHEREAS, the Parties used the Services provided by Cosmic Fit Club in order to engage each other. 
      In consideration of the mutual promises and covenants contained herein, the Parties agree as follows:

      Grant of License. 
      Cosmic Fit Club hereby grants Event Organizer a limited and revocable license (the “License”) to use the Space, 
      located at 21-36 44th Road LIC NY 11101. The License permits Event Organizer to use the Space only from the agreed Check In date and time, 
      until the Check out date and time, and only for the purposes set forth in Section 7 of this Agreement. 

      Event Time. The Event Time is inclusive of set-up and clean-up time. Event Organizer shall not have access to the Space outside of the Event Check In time and the Event Check Out time, unless Event Organizer receives prior written consent of Space Provider. 
      Transaction Fee. After confirmation of a booking request on the Services, the Event Organizer will then be charged 50% of the balance. Upon receipt of this payment via paypal to donut@cosmicfitclub.com Cosmic Fit Club will reserve this time slot for the Event. The remaining 50% will be due at the close of the event. All payments shall be made without withholding or deductions. Cosmic Fit Club is responsible for all property taxes and any other applicable taxes in respect of the Space. Cosmic Fit Club uses a third party vendor to provide payment processing services. All services provided by such third party vendor are subject to the terms of use of such third party. 
      Excess Time Fees. Usage Fees are based on the stated actual hours which include set up and clean up time. If Event Organizer, its guests, or service providers exceed the Event Time for any reason, Event Organizer shall pay Excess Time Fees which shall be assessed and billed in 1/2 hour increments unless otherwise agreed in writing in advance between Space Provider and Event Organizer.

      Right of Entry. Space Provider shall have the right to enter the Space at any time including but not limited during the Event Time and for any reasonable purpose, including any emergency that may threaten danger to the Space, or injury to any person in or near the Space. Notwithstanding the foregoing, Space Provider shall not interfere with the Event except in case of emergency. 
      Permitted Use. Event Organizer is authorized pursuant to the License to use the Space to hold the Event, and for no other purpose, unless Space Provider gives Event Organizer prior written authorization for additional permitted uses. 
      Representation and Warranties. Space Provider and Event Organizer represent and warrant that (i) they are authorized and have full authority to enter into this Agreement and perform their obligations hereunder, (ii) they shall comply at all time with all applicable laws and regulations. In addition, where alcohol shall be made available during the Event, Event Organizer represents and warrants that he/she is at least 21 years old and undertakes to take adequate measures to confirm the identification and age of those wishing to drink during the Event. 
      Condition of Premises. Space Provider hereby represents and warrants that any and all information provided by Space Provider in any registration questionnaire is truthful and accurate. Space Provider further represents and warrants that the Space is safe and conforms to all local rules and regulations. Event Organizer shall leave the Space in the same or similar condition as when Event Organizer entered the Space. Event Organizer shall be responsible for any damage caused to the Space beyond ordinary wear and tear, and shall be responsible for any repair needed to remedy such damage. In the event that Event Organizer does not satisfactorily remedy the damage caused to the Space, Space Provider shall be entitled to make the necessary repairs at Event Organizer’s expense. Event Organizer shall reimburse Space Provider for any such repairs within 30 days of receipt of Space Provider’s written request for reimbursement, which request shall be accompanied by a written statement of the damage incurred and the amount of expenses incurred to remedy such damage. 
      Removal of Property. All equipment, installments, decorations, and personal property of Event Organizer or any of Event Organizer’s service providers, guests or invitees must be removed from the Space by the conclusion of the Event Time. Unless otherwise agreed to in writing by the Parties, any such equipment, installments, decorations, or personal property left in the Space after the Event shall be considered abandoned and may be disposed of by Space Provider accordingly. 


      Release. Space Provider and Event Organizer on behalf of themselves and their respective assigns, subrogees, representatives and all other persons or entities acting for, by or through it, hereby release and forever discharges Cosmic Fit Club, its directors, officers, agents, representatives, employees, and insurers, from any and all liability, claims, demands, actions or rights of action, of whatever nature, character or description, for personal injury, property damage or death that arise from, are related to or are in any way connected with the Event , the renting or use of the Space (“Claims”), including without limitation and to the maximum extent permitted by applicable law, any Claims in part or in whole arising from, related to or in any way connected with the alleged or in fact negligent acts or omissions of Cosmic Fit Club, its directors, agents, employees, officers, and representatives. In the event either Event Organizer or Space Provider suffers any loss to person or property, such Party shall look solely to its, his or her insurance coverage, if any, and hereby waives any and all claims, demands, damages and causes of action of any nature whatsoever that Event Organizer or Space Provider, its successors or assigns may have against Cosmic Fit Club. 
      Limitation of Liability. Cosmic Fit Club and Event Organizer EACH ACKNOWLEDGE AND AGREE THAT, TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, EACH OF THEM ASSUME THE ENTIRE RISK ARISING OUT OF THEIR ACCESS TO AND USE OF THE SITE OR SERVICES, NEITHER COSMIC FIT CLUB NOR ANY OTHER PARTY INVOLVED IN CREATING, PRODUCING, OR DELIVERING THE SITE OR SERVICES WILL BE LIABLE FOR ANY INCIDENTAL, SPECIAL, EXEMPLARY OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, LOSS OF DATA OR LOSS OF GOODWILL, SERVICE INTERRUPTION, 
      COMPUTER DAMAGE OR SYSTEM FAILURE OR THE COST OF SUBSTITUTE SPACES OR SERVICES, OR FOR ANY DAMAGES FOR PERSONAL OR BODILY INJURY OR EMOTIONAL DISTRESS ARISING OUT OF OR IN CONNECTION WITH THIS AGREEMENT, 
      Insurance. Cosmic Fit Club and Event Organizer jointly and severally warrant and represent that they are covered by sufficient insurance to cover any damage, accident or loss whatsoever arising out of the lease of the Space by Cosmic Fit Club and the use of the Space by Event Organizer, their guests, invitees, vendors, clients, customers or licensees, including policies covering property damage, casualty, personal injury, fire, and general liability (“Sufficient Insurance”). 
      Compliance with Laws. Event Organizer shall obtain and maintain any and all necessary permits, licenses, or other forms of permission necessary to use the Space in a lawful manner at its sole cost. Event Organizer shall not use the Space in any manner that violates local, state or federal laws or regulations. Event Organizer shall indemnify Cosmic Fit Club, its employees, officers, directors, or other agents for any damages, penalties, fines, suits, actions, or other costs (including reasonable attorneys’ fees) arising out of or in connection with Event Organizer's violation of any local, state or federal law, rule, regulation or ordinance related to Event Organizer’s use of the Space. 
      Force Majeure. In the event that Cosmic Fit Club is unable, for reasons beyond its control, to make the Space available to Event Organizer on the Event Date for the purposes as set forth in this Agreement, Event Organizer shall have the option of choosing an alternate date to hold the Event (the “Alternate Event Date”), at no extra charge to Event Organizer. If Event Organizer selects an Alternate Event Date that is reasonably acceptable to Space Provider, then the Alternate Event Date shall replace the Event Date for the purposes of this Agreement, and all obligations, rights, duties and privileges as set forth in this Agreement shall remain binding on the Parties. If Event Organizer and Space Provider cannot agree upon an Alternate Event Date within 10 days of the original Event Date, then Space Provider shall refund to Event Organizer the full amount of the Usage Fee. In neither case shall Space Provider be liable for any additional costs or damages suffered by Event Organizer (over and above the Usage Fee) arising out of a rescheduling or cancellation of the Event pursuant to this Section. 
      Cancellation Policies. The event may be cancelled up to 5 days before its scheduled time if both Cosmic Fit Club and Event Organizer agree in writing to the cancellation. 
      Dispute Resolution. Any dispute, controversy or claim arising out of or relating to this Agreement, including the formation, interpretation, breach or termination thereof, including whether the claims asserted are arbitral, will be referred to and finally determined by arbitration in accordance with the JAMS International Arbitration Rules. The Tribunal will consist of one arbitrator. The place of arbitration will be the city of New York. The language to be used in the arbitral proceedings will be English. Judgment upon the award rendered by the arbitrator may 
      be entered in any court having jurisdiction thereof. 
      Governing Law. This Agreement shall be construed in accordance with, and governed in all respects by, the laws of the State of New York, without regard to conflicts of law principles. 
      Counterparts. This Agreement may be executed in several counterparts, each of which shall constitute an original and all of which, when taken together, shall constitute one agreement. 
      Severability. If any part or parts of this Agreement shall be held unenforceable for any reason, the remainder of this Agreement shall continue in full force and effect. If any provision of this Agreement is deemed invalid or unenforceable by any court of competent jurisdiction, and if limiting such provision would make the provision valid, then such provision shall be deemed to be construed as so limited. 
      Entire Agreement. This Agreement constitutes the entire agreement between Cosmic Fit Club and Event Organizer supersedes any prior understanding or representation of any kind preceding the date of this Agreement. There are no other promises, conditions, understandings or other agreements, whether oral or written, relating to the subject matter of this Agreement. Any terms starting capitalized and not defined in this Agreement shall have the meaning assigned to it under the Terms of Use. 
    }
  end

end
