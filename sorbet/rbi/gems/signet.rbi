# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/signet/all/signet.rbi
#
# signet-0.8.1

module Signet
  def self.parse_auth_param_list(auth_param_string); end
end
module Signet::VERSION
end
class Signet::UnsafeOperationError < StandardError
end
class Signet::ParseError < StandardError
end
class Signet::MalformedAuthorizationError < StandardError
end
class Signet::AuthorizationError < StandardError
  def initialize(message, options = nil); end
  def request; end
  def response; end
end
module Signet::OAuth2
  def self.generate_authorization_uri(authorization_uri, parameters = nil); end
  def self.generate_basic_authorization_header(client_id, client_password); end
  def self.generate_bearer_authorization_header(access_token, auth_params = nil); end
  def self.parse_authorization_header(field_value); end
  def self.parse_basic_credentials(credential_string); end
  def self.parse_bearer_credentials(credential_string); end
  def self.parse_credentials(body, content_type); end
  def self.parse_oauth_challenge(challenge_string); end
  def self.parse_www_authenticate_header(field_value); end
end
class Signet::OAuth2::Client
  def access_token; end
  def access_token=(new_access_token); end
  def additional_parameters; end
  def additional_parameters=(new_additional_parameters); end
  def audience; end
  def audience=(new_audience); end
  def authorization_uri(options = nil); end
  def authorization_uri=(new_authorization_uri); end
  def clear_credentials!; end
  def client_id; end
  def client_id=(new_client_id); end
  def client_secret; end
  def client_secret=(new_client_secret); end
  def code; end
  def code=(new_code); end
  def coerce_uri(incoming_uri); end
  def decoded_id_token(public_key = nil, options = nil, &keyfinder); end
  def deep_hash_normalize(old_hash); end
  def expired?; end
  def expires_at; end
  def expires_at=(new_expires_at); end
  def expires_in; end
  def expires_in=(new_expires_in); end
  def expires_within?(sec); end
  def expiry; end
  def expiry=(new_expiry); end
  def extension_parameters; end
  def extension_parameters=(new_extension_parameters); end
  def fetch_access_token!(options = nil); end
  def fetch_access_token(options = nil); end
  def fetch_protected_resource(options = nil); end
  def generate_access_token_request(options = nil); end
  def generate_authenticated_request(options = nil); end
  def grant_type; end
  def grant_type=(new_grant_type); end
  def id_token; end
  def id_token=(new_id_token); end
  def initialize(options = nil); end
  def issued_at; end
  def issued_at=(new_issued_at); end
  def issuer; end
  def issuer=(new_issuer); end
  def normalize_timestamp(time); end
  def password; end
  def password=(new_password); end
  def person; end
  def person=(new_person); end
  def principal; end
  def principal=(new_person); end
  def recursive_hash_normalize_keys(val); end
  def redirect_uri; end
  def redirect_uri=(new_redirect_uri); end
  def refresh!(options = nil); end
  def refresh_token; end
  def refresh_token=(new_refresh_token); end
  def scope; end
  def scope=(new_scope); end
  def signing_algorithm; end
  def signing_key; end
  def signing_key=(new_key); end
  def state; end
  def state=(new_state); end
  def sub; end
  def sub=(arg0); end
  def to_json; end
  def to_jwt(options = nil); end
  def token_credential_uri; end
  def token_credential_uri=(new_token_credential_uri); end
  def update!(options = nil); end
  def update_token!(options = nil); end
  def uri_is_oob?(uri); end
  def uri_is_postmessage?(uri); end
  def username; end
  def username=(new_username); end
end