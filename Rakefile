desc "Run Ruby Console with DB and Model access"

task :console do
  Dir.chdir('utillities')
  ruby "db_models.rb"
end

task :ssl_local do
  `bundle exec thin start -R config.ru --ssl --ssl-key-file shared/.ssl/server.key --ssl-cert-file shared/.ssl/server.crt`
end
