def with_s3
  with_catch do
    s3 = Aws::S3::Resource.new(
      region: 'us-east-1',
      credentials: Aws::Credentials.new( ENV['AWS_KEY'], ENV['AWS_SECRET'] )
    ); yield(s3.bucket('cosmicfitclub'))
  end  
end

$S3_options = {
  access_key_id:     ENV['AWS_KEY'],
  secret_access_key: ENV['AWS_SECRET'],
  region:            "us-east-1",
  bucket:            'cosmicfitclub'
}