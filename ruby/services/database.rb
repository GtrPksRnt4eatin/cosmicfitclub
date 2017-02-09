require 'sequel'

def get_heroku_pg_args
  uri = URI.parse(ENV['DATABASE_URL'])
  { :host     => uri.hostname,
    :port     => uri.port,
    :options  => nil,
    :tty      => nil,
    :dbname   => uri.path[1..-1],
    :user     => uri.user,
    :password => uri.password
  }
end

args = get_heroku_pg_args
$DB = Sequel.postgres(args[:dbname], args )
Sequel.application_timezone = :local
Sequel.database_timezone = :local