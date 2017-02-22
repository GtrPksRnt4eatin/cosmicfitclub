require 'sinatra/base'

module Sinatra
  
  module ViewHelpers

    def no_scaling; "\n<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0'/>" end
    def css(path) handleArray(path) { |x| "\n<link rel='stylesheet' type='text/css' href='#{x}.css'/>" } end
    def js(path)  handleArray(path) { |x| "\n<script src='#{x}.js'></script>" } end

    def handleArray(arg)
      if    arg.is_a? String then yield(arg)
      elsif arg.is_a? Array  then arg.map{ |x| yield(x) }.join('')
      else  '' end
    end

    def include_slim(name, options = {}, &block)
      Slim::Template.new("shared/#{name}.slim", options).render(self, &block)
    end

    def fb_image(path)  "\n<meta property='og:image'  content='#{path}'  />" end
    def fb_title(title) "\n<meta property='og:title'  content='#{title}' />" end
    def fb_type(type)   "\n<meta property='og:type'   content='#{type}'  />" end
    def fb_url(url)     "\n<meta property='og:url'    content='#{url}'   />" end
    def fb_appid(id)    "\n<meta property='fb:app_id' content='#{id}'    />" end

    def analytics
      <<-eos
        <script>
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

          ga('create', 'UA-92420410-1', 'auto');
          ga('send', 'pageview');
        </script>
      eos
    end
    
  end

end