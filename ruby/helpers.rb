def with_catch
  yield
rescue Exception => e
  p "////////////////////////////////////"
  p e
  p "////////////////////////////////////"
  status 500
  e.message
end

def with_db
  with_catch do
    begin
      args = {
        :host     => '',
        :port     => '',
        :options  => nil,
        :tty      => nil,
        :dbname   => '',
        :user     => '',
        :password => ''
      }
      conn = PG::Connection.new(args)
      yield conn
    ensure conn.close unless conn.nil?
    end
  end 
end

def css(path) handleArray(path) { |x| "\n<link rel='stylesheet' type='text/css' href='#{x}.css'/>" } end
def js(path)  handleArray(path) { |x| "\n<script src='#{x}.js'></script>" } end

def handleArray(arg)
  if    arg.is_a? String then yield(arg)
  elsif arg.is_a? Array  then arg.map{ |x| yield(x) }.join('')
  else  '' end
end

def include_slim(name, options = {}, &block)
  Slim::Template.new("#{name}.slim", options).render(self, &block)
end