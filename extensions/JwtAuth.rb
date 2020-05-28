class JwtAuth
  def initialize app
    @app = app
  end
  def call env
    begin
      request = Rack::Request.new(env)
      jwt = request.cookies['cosmicjwt'] or ( @app.call(env); return)
      payload, header = JWT.decode jwt, ENV['JWT_SECRET'], true, { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      session[:user_id] = payload['user']['user_id']
      session[:customer_id] = payload['user']['customer_id']
      @app.call env
    rescue JWT::DecodeError
      [401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']]
    rescue JWT::ExpiredSignature
      [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    rescue JWT::InvalidIssuerError
      [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
    end
  end
end