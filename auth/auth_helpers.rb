module Sinatra

    module Auth
    
      module Helpers
        def logged_in?       ; !!session[:user_id]             end
        def user             ; User[session[:user_id]]         end
        def customer         ; Customer[session[:customer_id]] end
        
        def has_role?(role)
          User[session[:user_id]].has_role? role
        end
  
        def read_jwt
          jwt = request.cookies['cosmicjwt'] or return
          jwt = JWT.decode(jwt,ENV['JWT_SECRET'],true,{ algorithm: 'HS256'})
          custy = Customer[jwt[0]["user"]["customer_id"]] or return
          session[:customer_id] = custy.id
          session[:user_id] = custy.user.id
          jwt
        end
  
      end
    
      def self.registered(app)
  
        app.helpers Auth::Helpers
  
        app.set(:auth) do |role|
          condition do
            redirect "/auth/login?page=#{request.path}" unless logged_in?
            redirect '/' unless User[session[:user_id]].has_role? role
            true
          end
        end
  
        app.set(:onboard) do |role|
          condition do
            redirect "/auth/onboard?page=#{request.path}" unless logged_in?
            redirect '/' unless User[session[:user_id]].has_role? role
            true
          end
        end
  
        app.set(:self_or) do |role|
          condition do
            return true if User[session[:user_id]].has_role? role
            halt(401, "Cannot Modify Someone Elses Account!") unless session[:customer_id] == Integer(params[:customer_id])
            true
          end
        end
  
        app.set(:jwt_logged_in) do |bool|
          condition do
            read_jwt
            true
          rescue JWT::DecodeError
            halt(401, 'A token must be passed.')
          rescue JWT::ExpiredSignature
            halt(403, 'The token has expired.')
          rescue JWT::InvalidIssuerError
            halt(403, 'The token does not have a valid issuer.')
          rescue JWT::InvalidIatError
            halt(403, 'The token does not have a valid "issued at" time.')
          end
        end 
  
      end
  
    end
  
  end