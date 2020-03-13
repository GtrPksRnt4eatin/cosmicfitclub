require 'sinatra/base'

module Sinatra
  
  module ViewHelpers

    def covid19
      "\n<div id='covid19' style='background:rgba(255,50,0,0.6); padding:0.5em; text-align: center; font-size: 1em; font-family:'Industry-Bold'; ><a style='text-decoration:none;' href='/covid19'>Community Health Advisory</a></div>"
    end

    def no_scaling; "\n<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0'/>" end
    def css(path) handleArray(path) { |x| "\n<link rel='stylesheet' type='text/css' href='#{x}.css'/>" } end
    def js(path)  handleArray(path) { |x| "\n<script defer src='#{x}.js'></script>" } end
    
    def js_sync(path) handleArray(path) { |x| "\n<script src='#{x}.js'></script>" } end
    
    def js_bundle(tag,arr) 
      params = arr.map{ |x| "file[]=#{x}" }.join('&')
      "\n<script src='bundledjs/#{tag}?#{params}'></script>"
    end

    def handleArray(arg)
      if    arg.is_a? String then yield(arg)
      elsif arg.is_a? Array  then arg.map{ |x| yield(x) }.join('')
      else  '' end
    end

    def include_slim(name, options = {}, &block)
      Slim::Template.new("shared/#{name}.slim", options).render(self, &block)
    end

    def fb_image(path)              "\n<meta property='og:image'       content='#{path}'        />" end
    def fb_title(title)             "\n<meta property='og:title'       content='#{title}'       />" end
    def fb_type(type)               "\n<meta property='og:type'        content='#{type}'        />" end
    def fb_url(url)                 "\n<meta property='og:url'         content='#{url}'         />" end
    def fb_appid(id)                "\n<meta property='fb:app_id'      content='#{id}'          />" end
    def fb_description(description) "\n<meta property='og:description' content='#{description}' />" end 

    def analytics
      #hotjar + matomo + 
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

    def hotjar
      <<-eos
        <!-- Hotjar Tracking Code for cosmicfitclub.com -->
        <script>
            (function(h,o,t,j,a,r){
                h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
                h._hjSettings={hjid:1022582,hjsv:6};
                a=o.getElementsByTagName('head')[0];
                r=o.createElement('script');r.async=1;
                r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
                a.appendChild(r);
            })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
        </script>
      eos
    end

    def matomo
      <<-eos
        <!-- Matomo -->
        <script type="text/javascript">
          var _paq = _paq || [];
          /* tracker methods like "setCustomDimension" should be called before "trackPageView" */
          _paq.push(['trackPageView']);
          _paq.push(['enableLinkTracking']);
          (function() {
            var u="https://cosmicfitclub.innocraft.cloud/";
            _paq.push(['setTrackerUrl', u+'piwik.php']);
            _paq.push(['setSiteId', '1']);
            var d=document, g=d.createElement('script'), s=d.getElementsByTagName('script')[0];
            g.type='text/javascript'; g.async=true; g.defer=true; g.src=u+'piwik.js'; s.parentNode.insertBefore(g,s);
          })();
        </script>
        <!-- End Matomo Code -->
      eos
    end

  end

end