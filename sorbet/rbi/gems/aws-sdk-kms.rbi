# This file is autogenerated. Do not edit it by hand. Regenerate it with:
#   srb rbi gems

# typed: true
#
# If you would like to make changes to this file, great! Please create the gem's shim here:
#
#   https://github.com/sorbet/sorbet-typed/new/master?filename=lib/aws-sdk-kms/all/aws-sdk-kms.rbi
#
# aws-sdk-kms-1.5.0

module Aws::KMS
end
module Aws::KMS::Types
end
class Anonymous_Struct_45 < Struct
  def alias_arn; end
  def alias_arn=(_); end
  def alias_name; end
  def alias_name=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def target_key_id; end
  def target_key_id=(_); end
end
class Aws::KMS::Types::AliasListEntry < Anonymous_Struct_45
  include Aws::Structure
end
class Anonymous_Struct_46 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::CancelKeyDeletionRequest < Anonymous_Struct_46
  include Aws::Structure
end
class Anonymous_Struct_47 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::CancelKeyDeletionResponse < Anonymous_Struct_47
  include Aws::Structure
end
class Anonymous_Struct_48 < Struct
  def alias_name; end
  def alias_name=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def target_key_id; end
  def target_key_id=(_); end
end
class Aws::KMS::Types::CreateAliasRequest < Anonymous_Struct_48
  include Aws::Structure
end
class Anonymous_Struct_49 < Struct
  def constraints; end
  def constraints=(_); end
  def grant_tokens; end
  def grant_tokens=(_); end
  def grantee_principal; end
  def grantee_principal=(_); end
  def key_id; end
  def key_id=(_); end
  def name; end
  def name=(_); end
  def operations; end
  def operations=(_); end
  def retiring_principal; end
  def retiring_principal=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::CreateGrantRequest < Anonymous_Struct_49
  include Aws::Structure
end
class Anonymous_Struct_50 < Struct
  def grant_id; end
  def grant_id=(_); end
  def grant_token; end
  def grant_token=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::CreateGrantResponse < Anonymous_Struct_50
  include Aws::Structure
end
class Anonymous_Struct_51 < Struct
  def bypass_policy_lockout_safety_check; end
  def bypass_policy_lockout_safety_check=(_); end
  def description; end
  def description=(_); end
  def key_usage; end
  def key_usage=(_); end
  def origin; end
  def origin=(_); end
  def policy; end
  def policy=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def tags; end
  def tags=(_); end
end
class Aws::KMS::Types::CreateKeyRequest < Anonymous_Struct_51
  include Aws::Structure
end
class Anonymous_Struct_52 < Struct
  def key_metadata; end
  def key_metadata=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::CreateKeyResponse < Anonymous_Struct_52
  include Aws::Structure
end
class Anonymous_Struct_53 < Struct
  def ciphertext_blob; end
  def ciphertext_blob=(_); end
  def encryption_context; end
  def encryption_context=(_); end
  def grant_tokens; end
  def grant_tokens=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DecryptRequest < Anonymous_Struct_53
  include Aws::Structure
end
class Anonymous_Struct_54 < Struct
  def key_id; end
  def key_id=(_); end
  def plaintext; end
  def plaintext=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DecryptResponse < Anonymous_Struct_54
  include Aws::Structure
end
class Anonymous_Struct_55 < Struct
  def alias_name; end
  def alias_name=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DeleteAliasRequest < Anonymous_Struct_55
  include Aws::Structure
end
class Anonymous_Struct_56 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DeleteImportedKeyMaterialRequest < Anonymous_Struct_56
  include Aws::Structure
end
class Anonymous_Struct_57 < Struct
  def grant_tokens; end
  def grant_tokens=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DescribeKeyRequest < Anonymous_Struct_57
  include Aws::Structure
end
class Anonymous_Struct_58 < Struct
  def key_metadata; end
  def key_metadata=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DescribeKeyResponse < Anonymous_Struct_58
  include Aws::Structure
end
class Anonymous_Struct_59 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DisableKeyRequest < Anonymous_Struct_59
  include Aws::Structure
end
class Anonymous_Struct_60 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::DisableKeyRotationRequest < Anonymous_Struct_60
  include Aws::Structure
end
class Anonymous_Struct_61 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::EnableKeyRequest < Anonymous_Struct_61
  include Aws::Structure
end
class Anonymous_Struct_62 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::EnableKeyRotationRequest < Anonymous_Struct_62
  include Aws::Structure
end
class Anonymous_Struct_63 < Struct
  def encryption_context; end
  def encryption_context=(_); end
  def grant_tokens; end
  def grant_tokens=(_); end
  def key_id; end
  def key_id=(_); end
  def plaintext; end
  def plaintext=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::EncryptRequest < Anonymous_Struct_63
  include Aws::Structure
end
class Anonymous_Struct_64 < Struct
  def ciphertext_blob; end
  def ciphertext_blob=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::EncryptResponse < Anonymous_Struct_64
  include Aws::Structure
end
class Anonymous_Struct_65 < Struct
  def encryption_context; end
  def encryption_context=(_); end
  def grant_tokens; end
  def grant_tokens=(_); end
  def key_id; end
  def key_id=(_); end
  def key_spec; end
  def key_spec=(_); end
  def number_of_bytes; end
  def number_of_bytes=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GenerateDataKeyRequest < Anonymous_Struct_65
  include Aws::Structure
end
class Anonymous_Struct_66 < Struct
  def ciphertext_blob; end
  def ciphertext_blob=(_); end
  def key_id; end
  def key_id=(_); end
  def plaintext; end
  def plaintext=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GenerateDataKeyResponse < Anonymous_Struct_66
  include Aws::Structure
end
class Anonymous_Struct_67 < Struct
  def encryption_context; end
  def encryption_context=(_); end
  def grant_tokens; end
  def grant_tokens=(_); end
  def key_id; end
  def key_id=(_); end
  def key_spec; end
  def key_spec=(_); end
  def number_of_bytes; end
  def number_of_bytes=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GenerateDataKeyWithoutPlaintextRequest < Anonymous_Struct_67
  include Aws::Structure
end
class Anonymous_Struct_68 < Struct
  def ciphertext_blob; end
  def ciphertext_blob=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GenerateDataKeyWithoutPlaintextResponse < Anonymous_Struct_68
  include Aws::Structure
end
class Anonymous_Struct_69 < Struct
  def number_of_bytes; end
  def number_of_bytes=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GenerateRandomRequest < Anonymous_Struct_69
  include Aws::Structure
end
class Anonymous_Struct_70 < Struct
  def plaintext; end
  def plaintext=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GenerateRandomResponse < Anonymous_Struct_70
  include Aws::Structure
end
class Anonymous_Struct_71 < Struct
  def key_id; end
  def key_id=(_); end
  def policy_name; end
  def policy_name=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GetKeyPolicyRequest < Anonymous_Struct_71
  include Aws::Structure
end
class Anonymous_Struct_72 < Struct
  def policy; end
  def policy=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GetKeyPolicyResponse < Anonymous_Struct_72
  include Aws::Structure
end
class Anonymous_Struct_73 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GetKeyRotationStatusRequest < Anonymous_Struct_73
  include Aws::Structure
end
class Anonymous_Struct_74 < Struct
  def key_rotation_enabled; end
  def key_rotation_enabled=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GetKeyRotationStatusResponse < Anonymous_Struct_74
  include Aws::Structure
end
class Anonymous_Struct_75 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def wrapping_algorithm; end
  def wrapping_algorithm=(_); end
  def wrapping_key_spec; end
  def wrapping_key_spec=(_); end
end
class Aws::KMS::Types::GetParametersForImportRequest < Anonymous_Struct_75
  include Aws::Structure
end
class Anonymous_Struct_76 < Struct
  def import_token; end
  def import_token=(_); end
  def key_id; end
  def key_id=(_); end
  def parameters_valid_to; end
  def parameters_valid_to=(_); end
  def public_key; end
  def public_key=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GetParametersForImportResponse < Anonymous_Struct_76
  include Aws::Structure
end
class Anonymous_Struct_77 < Struct
  def encryption_context_equals; end
  def encryption_context_equals=(_); end
  def encryption_context_subset; end
  def encryption_context_subset=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GrantConstraints < Anonymous_Struct_77
  include Aws::Structure
end
class Anonymous_Struct_78 < Struct
  def constraints; end
  def constraints=(_); end
  def creation_date; end
  def creation_date=(_); end
  def grant_id; end
  def grant_id=(_); end
  def grantee_principal; end
  def grantee_principal=(_); end
  def issuing_account; end
  def issuing_account=(_); end
  def key_id; end
  def key_id=(_); end
  def name; end
  def name=(_); end
  def operations; end
  def operations=(_); end
  def retiring_principal; end
  def retiring_principal=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::GrantListEntry < Anonymous_Struct_78
  include Aws::Structure
end
class Anonymous_Struct_79 < Struct
  def encrypted_key_material; end
  def encrypted_key_material=(_); end
  def expiration_model; end
  def expiration_model=(_); end
  def import_token; end
  def import_token=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def valid_to; end
  def valid_to=(_); end
end
class Aws::KMS::Types::ImportKeyMaterialRequest < Anonymous_Struct_79
  include Aws::Structure
end
class Aws::KMS::Types::ImportKeyMaterialResponse < Aws::EmptyStructure
end
class Anonymous_Struct_80 < Struct
  def key_arn; end
  def key_arn=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::KeyListEntry < Anonymous_Struct_80
  include Aws::Structure
end
class Anonymous_Struct_81 < Struct
  def arn; end
  def arn=(_); end
  def aws_account_id; end
  def aws_account_id=(_); end
  def creation_date; end
  def creation_date=(_); end
  def deletion_date; end
  def deletion_date=(_); end
  def description; end
  def description=(_); end
  def enabled; end
  def enabled=(_); end
  def expiration_model; end
  def expiration_model=(_); end
  def key_id; end
  def key_id=(_); end
  def key_manager; end
  def key_manager=(_); end
  def key_state; end
  def key_state=(_); end
  def key_usage; end
  def key_usage=(_); end
  def origin; end
  def origin=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def valid_to; end
  def valid_to=(_); end
end
class Aws::KMS::Types::KeyMetadata < Anonymous_Struct_81
  include Aws::Structure
end
class Anonymous_Struct_82 < Struct
  def limit; end
  def limit=(_); end
  def marker; end
  def marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ListAliasesRequest < Anonymous_Struct_82
  include Aws::Structure
end
class Anonymous_Struct_83 < Struct
  def aliases; end
  def aliases=(_); end
  def next_marker; end
  def next_marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def truncated; end
  def truncated=(_); end
end
class Aws::KMS::Types::ListAliasesResponse < Anonymous_Struct_83
  include Aws::Structure
end
class Anonymous_Struct_84 < Struct
  def key_id; end
  def key_id=(_); end
  def limit; end
  def limit=(_); end
  def marker; end
  def marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ListGrantsRequest < Anonymous_Struct_84
  include Aws::Structure
end
class Anonymous_Struct_85 < Struct
  def grants; end
  def grants=(_); end
  def next_marker; end
  def next_marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def truncated; end
  def truncated=(_); end
end
class Aws::KMS::Types::ListGrantsResponse < Anonymous_Struct_85
  include Aws::Structure
end
class Anonymous_Struct_86 < Struct
  def key_id; end
  def key_id=(_); end
  def limit; end
  def limit=(_); end
  def marker; end
  def marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ListKeyPoliciesRequest < Anonymous_Struct_86
  include Aws::Structure
end
class Anonymous_Struct_87 < Struct
  def next_marker; end
  def next_marker=(_); end
  def policy_names; end
  def policy_names=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def truncated; end
  def truncated=(_); end
end
class Aws::KMS::Types::ListKeyPoliciesResponse < Anonymous_Struct_87
  include Aws::Structure
end
class Anonymous_Struct_88 < Struct
  def limit; end
  def limit=(_); end
  def marker; end
  def marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ListKeysRequest < Anonymous_Struct_88
  include Aws::Structure
end
class Anonymous_Struct_89 < Struct
  def keys; end
  def keys=(_); end
  def next_marker; end
  def next_marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def truncated; end
  def truncated=(_); end
end
class Aws::KMS::Types::ListKeysResponse < Anonymous_Struct_89
  include Aws::Structure
end
class Anonymous_Struct_90 < Struct
  def key_id; end
  def key_id=(_); end
  def limit; end
  def limit=(_); end
  def marker; end
  def marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ListResourceTagsRequest < Anonymous_Struct_90
  include Aws::Structure
end
class Anonymous_Struct_91 < Struct
  def next_marker; end
  def next_marker=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def tags; end
  def tags=(_); end
  def truncated; end
  def truncated=(_); end
end
class Aws::KMS::Types::ListResourceTagsResponse < Anonymous_Struct_91
  include Aws::Structure
end
class Anonymous_Struct_92 < Struct
  def limit; end
  def limit=(_); end
  def marker; end
  def marker=(_); end
  def retiring_principal; end
  def retiring_principal=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ListRetirableGrantsRequest < Anonymous_Struct_92
  include Aws::Structure
end
class Anonymous_Struct_93 < Struct
  def bypass_policy_lockout_safety_check; end
  def bypass_policy_lockout_safety_check=(_); end
  def key_id; end
  def key_id=(_); end
  def policy; end
  def policy=(_); end
  def policy_name; end
  def policy_name=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::PutKeyPolicyRequest < Anonymous_Struct_93
  include Aws::Structure
end
class Anonymous_Struct_94 < Struct
  def ciphertext_blob; end
  def ciphertext_blob=(_); end
  def destination_encryption_context; end
  def destination_encryption_context=(_); end
  def destination_key_id; end
  def destination_key_id=(_); end
  def grant_tokens; end
  def grant_tokens=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def source_encryption_context; end
  def source_encryption_context=(_); end
end
class Aws::KMS::Types::ReEncryptRequest < Anonymous_Struct_94
  include Aws::Structure
end
class Anonymous_Struct_95 < Struct
  def ciphertext_blob; end
  def ciphertext_blob=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def source_key_id; end
  def source_key_id=(_); end
end
class Aws::KMS::Types::ReEncryptResponse < Anonymous_Struct_95
  include Aws::Structure
end
class Anonymous_Struct_96 < Struct
  def grant_id; end
  def grant_id=(_); end
  def grant_token; end
  def grant_token=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::RetireGrantRequest < Anonymous_Struct_96
  include Aws::Structure
end
class Anonymous_Struct_97 < Struct
  def grant_id; end
  def grant_id=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::RevokeGrantRequest < Anonymous_Struct_97
  include Aws::Structure
end
class Anonymous_Struct_98 < Struct
  def key_id; end
  def key_id=(_); end
  def pending_window_in_days; end
  def pending_window_in_days=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ScheduleKeyDeletionRequest < Anonymous_Struct_98
  include Aws::Structure
end
class Anonymous_Struct_99 < Struct
  def deletion_date; end
  def deletion_date=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::ScheduleKeyDeletionResponse < Anonymous_Struct_99
  include Aws::Structure
end
class Anonymous_Struct_100 < Struct
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def tag_key; end
  def tag_key=(_); end
  def tag_value; end
  def tag_value=(_); end
end
class Aws::KMS::Types::Tag < Anonymous_Struct_100
  include Aws::Structure
end
class Anonymous_Struct_101 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def tags; end
  def tags=(_); end
end
class Aws::KMS::Types::TagResourceRequest < Anonymous_Struct_101
  include Aws::Structure
end
class Anonymous_Struct_102 < Struct
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def tag_keys; end
  def tag_keys=(_); end
end
class Aws::KMS::Types::UntagResourceRequest < Anonymous_Struct_102
  include Aws::Structure
end
class Anonymous_Struct_103 < Struct
  def alias_name; end
  def alias_name=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
  def target_key_id; end
  def target_key_id=(_); end
end
class Aws::KMS::Types::UpdateAliasRequest < Anonymous_Struct_103
  include Aws::Structure
end
class Anonymous_Struct_104 < Struct
  def description; end
  def description=(_); end
  def key_id; end
  def key_id=(_); end
  def self.[](*arg0); end
  def self.inspect; end
  def self.members; end
  def self.new(*arg0); end
end
class Aws::KMS::Types::UpdateKeyDescriptionRequest < Anonymous_Struct_104
  include Aws::Structure
end
module Aws::KMS::ClientApi
  include Seahorse::Model
end
class Aws::KMS::Client < Seahorse::Client::Base
  def build_request(operation_name, params = nil); end
  def cancel_key_deletion(params = nil, options = nil); end
  def create_alias(params = nil, options = nil); end
  def create_grant(params = nil, options = nil); end
  def create_key(params = nil, options = nil); end
  def decrypt(params = nil, options = nil); end
  def delete_alias(params = nil, options = nil); end
  def delete_imported_key_material(params = nil, options = nil); end
  def describe_key(params = nil, options = nil); end
  def disable_key(params = nil, options = nil); end
  def disable_key_rotation(params = nil, options = nil); end
  def enable_key(params = nil, options = nil); end
  def enable_key_rotation(params = nil, options = nil); end
  def encrypt(params = nil, options = nil); end
  def generate_data_key(params = nil, options = nil); end
  def generate_data_key_without_plaintext(params = nil, options = nil); end
  def generate_random(params = nil, options = nil); end
  def get_key_policy(params = nil, options = nil); end
  def get_key_rotation_status(params = nil, options = nil); end
  def get_parameters_for_import(params = nil, options = nil); end
  def import_key_material(params = nil, options = nil); end
  def initialize(*args); end
  def list_aliases(params = nil, options = nil); end
  def list_grants(params = nil, options = nil); end
  def list_key_policies(params = nil, options = nil); end
  def list_keys(params = nil, options = nil); end
  def list_resource_tags(params = nil, options = nil); end
  def list_retirable_grants(params = nil, options = nil); end
  def put_key_policy(params = nil, options = nil); end
  def re_encrypt(params = nil, options = nil); end
  def retire_grant(params = nil, options = nil); end
  def revoke_grant(params = nil, options = nil); end
  def schedule_key_deletion(params = nil, options = nil); end
  def self.errors_module; end
  def self.identifier; end
  def tag_resource(params = nil, options = nil); end
  def untag_resource(params = nil, options = nil); end
  def update_alias(params = nil, options = nil); end
  def update_key_description(params = nil, options = nil); end
  def waiter_names; end
  include Aws::ClientStubs
end
module Aws::KMS::Errors
  extend Aws::Errors::DynamicErrors
end
class Aws::KMS::Errors::ServiceError < Aws::Errors::ServiceError
end
class Aws::KMS::Resource
  def client; end
  def initialize(options = nil); end
end