# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/koala/all/koala.rbi
#
# koala-3.0.0

module Koala
  def self.config; end
  def self.configure; end
  def self.http_service; end
  def self.http_service=(service); end
  def self.make_request(path, args, verb, options = nil); end
  def self.reset_config; end
end
class Koala::KoalaError < StandardError
end
module Koala::Facebook
end
class Koala::Facebook::OAuthSignatureError < Koala::KoalaError
end
class Koala::Facebook::AppSecretNotDefinedError < Koala::KoalaError
end
class Koala::Facebook::APIError < Koala::KoalaError
  def fb_error_code; end
  def fb_error_code=(arg0); end
  def fb_error_debug; end
  def fb_error_debug=(arg0); end
  def fb_error_message; end
  def fb_error_message=(arg0); end
  def fb_error_rev; end
  def fb_error_rev=(arg0); end
  def fb_error_subcode; end
  def fb_error_subcode=(arg0); end
  def fb_error_trace_id; end
  def fb_error_trace_id=(arg0); end
  def fb_error_type; end
  def fb_error_type=(arg0); end
  def fb_error_user_msg; end
  def fb_error_user_msg=(arg0); end
  def fb_error_user_title; end
  def fb_error_user_title=(arg0); end
  def http_status; end
  def http_status=(arg0); end
  def initialize(http_status, response_body, error_info = nil); end
  def response_body; end
  def response_body=(arg0); end
end
class Koala::Facebook::BadFacebookResponse < Koala::Facebook::APIError
end
class Koala::Facebook::OAuthTokenRequestError < Koala::Facebook::APIError
end
class Koala::Facebook::ServerError < Koala::Facebook::APIError
end
class Koala::Facebook::ClientError < Koala::Facebook::APIError
end
class Koala::Facebook::AuthenticationError < Koala::Facebook::ClientError
end
class Koala::Facebook::API
  def access_token; end
  def api(path, args = nil, verb = nil, options = nil); end
  def app_secret; end
  def check_response(http_status, body, headers); end
  def graph_call(path, args = nil, verb = nil, options = nil, &post_processing); end
  def initialize(access_token = nil, app_secret = nil); end
  def preserve_form_arguments?(options); end
  def sanitize_request_parameters(parameters); end
  include Koala::Facebook::GraphAPIMethods
end
class Koala::Facebook::API::GraphCollection < Array
  def api; end
  def headers; end
  def initialize(response, api); end
  def next_page(extra_params = nil); end
  def next_page_params; end
  def paging; end
  def parse_page_url(url); end
  def previous_page(extra_params = nil); end
  def previous_page_params; end
  def raw_response; end
  def self.evaluate(response, api); end
  def self.is_pageable?(response); end
  def self.parse_page_url(url); end
  def summary; end
end
module Koala::HTTPService
  def self.encode_params(param_hash); end
  def self.faraday_middleware; end
  def self.faraday_middleware=(arg0); end
  def self.faraday_options(options); end
  def self.http_options; end
  def self.http_options=(arg0); end
  def self.make_request(request); end
end
class Koala::HTTPService::UploadableIO
  def content_type; end
  def detect_mime_type(filename); end
  def filename; end
  def initialize(io_or_path_or_mixed, content_type = nil, filename = nil); end
  def io_or_path; end
  def parse_file_object(file, content_type = nil); end
  def parse_init_mixed_param(mixed, content_type = nil); end
  def parse_io(io, content_type = nil); end
  def parse_rails_3_param(uploaded_file, content_type = nil); end
  def parse_sinatra_param(file_hash, content_type = nil); end
  def parse_string_path(path, content_type = nil); end
  def self.binary_content?(content); end
  def self.file_param?(file); end
  def self.rails_3_param?(uploaded_file); end
  def self.sinatra_param?(file_hash); end
  def to_file; end
  def to_upload_io; end
  def use_mime_module(filename); end
  def use_simple_detection(filename); end
end
class Koala::Facebook::GraphErrorChecker
  def auth_error?; end
  def base_error_info; end
  def body; end
  def error_class; end
  def error_if_appropriate; end
  def error_info; end
  def headers; end
  def http_status; end
  def initialize(http_status, body, headers); end
  def response_hash; end
end
module Koala::Facebook::GraphAPIMethods
  def batch(http_options = nil, &block); end
  def debug_token(input_token, &block); end
  def delete_connections(id, connection_name, args = nil, options = nil, &block); end
  def delete_like(id, options = nil, &block); end
  def delete_object(id, options = nil, &block); end
  def get_connection(id, connection_name, args = nil, options = nil, &block); end
  def get_connections(id, connection_name, args = nil, options = nil, &block); end
  def get_object(id, args = nil, options = nil, &block); end
  def get_object_metadata(id, &block); end
  def get_objects(ids, args = nil, options = nil, &block); end
  def get_page(params, &block); end
  def get_page_access_token(id, args = nil, options = nil, &block); end
  def get_picture(object, args = nil, options = nil, &block); end
  def get_picture_data(object, args = nil, options = nil, &block); end
  def get_user_picture_data(*args, &block); end
  def parse_media_args(media_args, method); end
  def put_comment(id, message, options = nil, &block); end
  def put_connections(id, connection_name, args = nil, options = nil, &block); end
  def put_like(id, options = nil, &block); end
  def put_object(parent_object, connection_name, args = nil, options = nil, &block); end
  def put_picture(*picture_args, &block); end
  def put_video(*video_args, &block); end
  def put_wall_post(message, attachment = nil, target_id = nil, options = nil, &block); end
  def search(search_terms, args = nil, options = nil, &block); end
  def set_app_restrictions(app_id, restrictions_hash, args = nil, options = nil, &block); end
  def url?(data); end
end
class Koala::Facebook::GraphBatchAPI < Koala::Facebook::API
  def access_token; end
  def app_secret; end
  def bad_response; end
  def batch_args(calls_for_batch); end
  def batch_calls; end
  def desired_component(component:, response:, headers:); end
  def error_from_response(response, headers); end
  def execute(http_options = nil); end
  def generate_results(response, batch); end
  def graph_call(path, args = nil, verb = nil, options = nil, &post_processing); end
  def headers_from_response(response); end
  def initialize(api); end
  def json_body(response); end
  def original_api; end
  def result_from_response(response, options); end
  include Koala::Facebook::GraphAPIMethods
end
class Koala::Facebook::GraphBatchAPI::BatchOperation
  def access_token; end
  def args_in_url?; end
  def batch_api; end
  def files; end
  def http_options; end
  def identifier; end
  def initialize(options = nil); end
  def post_processing; end
  def process_binary_args; end
  def self.next_identifier; end
  def to_batch_params(main_access_token, app_secret); end
end
class Koala::Facebook::OAuth
  def app_id; end
  def app_secret; end
  def base64_url_decode(str); end
  def build_url(type, path, require_redirect_uri = nil, url_options = nil); end
  def exchange_access_token(access_token, options = nil); end
  def exchange_access_token_info(access_token, options = nil); end
  def fetch_token_string(args, post = nil, endpoint = nil, options = nil); end
  def generate_client_code(access_token); end
  def get_access_token(code, options = nil); end
  def get_access_token_info(code, options = nil); end
  def get_app_access_token(options = nil); end
  def get_app_access_token_info(options = nil); end
  def get_token_from_server(args, post = nil, options = nil); end
  def get_user_info_from_cookie(cookie_hash); end
  def get_user_info_from_cookies(cookie_hash); end
  def initialize(app_id = nil, app_secret = nil, oauth_callback_url = nil); end
  def oauth_callback_url; end
  def parse_access_token(response_text); end
  def parse_signed_cookie(fb_cookie); end
  def parse_signed_request(input); end
  def parse_unsigned_cookie(fb_cookie); end
  def server_url(type); end
  def url_for_access_token(code, options = nil); end
  def url_for_dialog(dialog_type, options = nil); end
  def url_for_oauth_code(options = nil); end
end
class Koala::Facebook::RealtimeUpdates
  def api; end
  def app_access_token; end
  def app_id; end
  def initialize(options = nil); end
  def list_subscriptions(options = nil); end
  def secret; end
  def self.meet_challenge(params, verify_token = nil, &verification_block); end
  def subscribe(object, fields, callback_url, verify_token, options = nil); end
  def subscription_path; end
  def unsubscribe(object = nil, options = nil); end
  def validate_update(body, headers); end
end
class Koala::Facebook::TestUsers
  def api; end
  def app_access_token; end
  def app_id; end
  def befriend(user1_hash, user2_hash, options = nil); end
  def create(installed, permissions = nil, args = nil, options = nil); end
  def create_network(network_size, installed = nil, permissions = nil, options = nil); end
  def delete(test_user, options = nil); end
  def delete_all(options = nil); end
  def initialize(options = nil); end
  def list(options = nil); end
  def secret; end
  def test_user_accounts_path; end
  def update(test_user, args = nil, options = nil); end
end
class Koala::HTTPService::MultipartRequest < Faraday::Request::Multipart
  def process_params(params, prefix = nil, pieces = nil, &block); end
  def process_request?(env); end
end
class Koala::HTTPService::Response
  def body; end
  def data; end
  def headers; end
  def initialize(status, body, headers); end
  def status; end
end
class Koala::HTTPService::Request
  def add_ssl_options(opts); end
  def args; end
  def get_args; end
  def initialize(path:, verb:, args: nil, options: nil); end
  def json?; end
  def options; end
  def path; end
  def path_contains_api_version?; end
  def post_args; end
  def raw_args; end
  def raw_options; end
  def raw_path; end
  def raw_verb; end
  def replace_server_component(host, condition_met, replacement); end
  def server; end
  def verb; end
end
class Koala::Configuration
  def access_token; end
  def access_token=(arg0); end
  def api_version; end
  def api_version=(arg0); end
  def app_access_token; end
  def app_access_token=(arg0); end
  def app_id; end
  def app_id=(arg0); end
  def app_secret; end
  def app_secret=(arg0); end
  def beta_replace; end
  def beta_replace=(arg0); end
  def dialog_host; end
  def dialog_host=(arg0); end
  def graph_server; end
  def graph_server=(arg0); end
  def host_path_matcher; end
  def host_path_matcher=(arg0); end
  def initialize; end
  def oauth_callback_url; end
  def oauth_callback_url=(arg0); end
  def preserve_form_arguments; end
  def preserve_form_arguments=(arg0); end
  def video_replace; end
  def video_replace=(arg0); end
end
module Koala::Utils
  def debug(*args, &block); end
  def deprecate(message); end
  def error(*args, &block); end
  def fatal(*args, &block); end
  def info(*args, &block); end
  def level(*args, &block); end
  def level=(*args, &block); end
  def logger; end
  def logger=(arg0); end
  def symbolize_hash(hash); end
  def warn(*args, &block); end
  extend Forwardable
  extend Koala::Utils
end