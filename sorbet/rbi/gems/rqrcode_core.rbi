# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/rqrcode_core/all/rqrcode_core.rbi
#
# rqrcode_core-0.1.1

module RQRCodeCore
end
module RQRCodeCore::CoreExtensions
end
module RQRCodeCore::CoreExtensions::Array
end
module RQRCodeCore::CoreExtensions::Array::Behavior
end
class Array
  include RQRCodeCore::CoreExtensions::Array::Behavior
end
module RQRCodeCore::CoreExtensions::Integer
end
module RQRCodeCore::CoreExtensions::Integer::Bitwise
  def rszf(count); end
end
class Integer < Numeric
  include RQRCodeCore::CoreExtensions::Integer::Bitwise
end
class RQRCodeCore::QR8bitByte
  def get_length; end
  def initialize(data); end
  def mode; end
  def write(buffer); end
end
class RQRCodeCore::QRAlphanumeric
  def get_length; end
  def initialize(data); end
  def mode; end
  def self.valid_data?(data); end
  def write(buffer); end
end
class RQRCodeCore::QRBitBuffer
  def alphanumeric_encoding_start(length); end
  def buffer; end
  def byte_encoding_start(length); end
  def end_of_message(max_data_bits); end
  def get(index); end
  def get_length_in_bits; end
  def initialize(version); end
  def numeric_encoding_start(length); end
  def pad_until(prefered_size); end
  def put(num, length); end
  def put_bit(bit); end
end
class RQRCodeCore::QRCodeArgumentError < ArgumentError
end
class RQRCodeCore::QRCodeRunTimeError < RuntimeError
end
class RQRCodeCore::QRCode
  def _deprecated_dark?(row, col); end
  def checked?(row, col); end
  def dark?(*args, &block); end
  def error_correction_level; end
  def get_best_mask_pattern; end
  def initialize(string, *args); end
  def inspect; end
  def make; end
  def make_impl(test, mask_pattern); end
  def map_data(data, mask_pattern); end
  def mode; end
  def module_count; end
  def modules; end
  def place_format_info(test, mask_pattern); end
  def place_position_adjust_pattern; end
  def place_position_probe_pattern(row, col); end
  def place_timing_pattern; end
  def place_version_info(test); end
  def prepare_common_patterns; end
  def self.count_max_data_bits(rs_blocks); end
  def self.create_bytes(buffer, rs_blocks); end
  def self.create_data(version, error_correct_level, data_list); end
  def smallest_size_for(string, max_size_array); end
  def to_s(*args); end
  def version; end
  extend Gem::Deprecate
end
class RQRCodeCore::QRMath
  def self.gexp(n); end
  def self.glog(n); end
end
class RQRCodeCore::QRNumeric
  def get_bit_length(length); end
  def get_code(chars); end
  def get_length; end
  def initialize(data); end
  def mode; end
  def self.valid_data?(data); end
  def write(buffer); end
end
class RQRCodeCore::QRPolynomial
  def get(index); end
  def get_length; end
  def initialize(num, shift); end
  def mod(e); end
  def multiply(e); end
end
class RQRCodeCore::QRRSBlock
  def data_count; end
  def initialize(total_count, data_count); end
  def self.get_rs_block_table(version, error_correct_level); end
  def self.get_rs_blocks(version, error_correct_level); end
  def total_count; end
end
class RQRCodeCore::QRUtil
  def self.demerit_points_1_same_color(modules); end
  def self.demerit_points_2_full_blocks(modules); end
  def self.demerit_points_3_dangerous_patterns(modules); end
  def self.demerit_points_4_dark_ratio(modules); end
  def self.get_bch_digit(data); end
  def self.get_bch_format_info(data); end
  def self.get_bch_version(data); end
  def self.get_error_correct_polynomial(error_correct_length); end
  def self.get_length_in_bits(mode, version); end
  def self.get_lost_points(modules); end
  def self.get_mask(mask_pattern, i, j); end
  def self.get_pattern_positions(version); end
  def self.max_size; end
end