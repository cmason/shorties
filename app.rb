require "sinatra"
require "sinatra/activerecord"

set :database, "sqlite3:///url.db"

RADIX = 36

class Url < ActiveRecord::Base
  def shorten
    id.to_s(RADIX)
  end
end

get '/' do
  if params[:long_url]
     uri = URI::parse(params[:long_url])
     raise "Invalid URL" unless uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS
     @url = Url.find_or_create_by(long_url: uri.to_s)
     root_url + '/' + @url.shorten     
  else
    haml :index
  end 
end

post '/' do
  uri = URI::parse(params[:long_url])
  raise "Invalid URL" unless uri.kind_of? URI::HTTP or uri.kind_of? URI::HTTPS
  @url = Url.find_or_create_by(long_url: uri.to_s)
  haml :index
end

get '/:tiny' do |t| 
  redirect Url.find(t.to_i(RADIX)).long_url 
end

error do 
  haml :index 
end

helpers do

  # The root URL for this site.
  def root_url
    'http://' +  request.host_with_port
  end
  
  # Creates the browser link that people can use to post the current URL in
  # their browser to this application.
  def bookmarklet(text)
    # We need to POST the current URL to / from javascript. The only way
    # that I know to do this is to use javascript to create a form on the
    # current page, and then submit that form to /.
    js_code = <<EOF
      var%20f = document.createElement('form');
      f.style.display = 'none';
      document.body.appendChild(f);
      f.method = 'POST';
      f.action = '#{root_url}/';
      var%20m = document.createElement('input');
      m.setAttribute('type', 'hidden');
      m.setAttribute('name', 'long_url');
      m.setAttribute('value', location.href);
      f.appendChild(m);
      f.submit();
EOF

    # Remove all the whitespace from the javascript, so that it's a
    # bookmarkable URL.
    js_code.gsub!(/\s+/, '')

    # Return the link.
    %(<a href="javascript:#{js_code}">#{text}</a>)
  end
end

# Views
# use_in_file_templates!
enable :inline_templates
__END__

@@ layout
!!! XML utf-8
!!! Strict
%html{html_attrs()}
  %head
    %title Url Shortener
    %link{:rel => 'stylesheet', :href => 'http://www.w3.org/StyleSheets/Core/Swiss', :type => 'text/css'}
  %body
    = yield
    %div#bookmarklet
      Drag this link to your browser's bookmark bar to create a tiny URL 
      anywhere: 
      = bookmarklet("URL shortener")

@@ index
%h1.title Url Shortener
- unless @url.nil?
  %div
    %code= @url.long_url
    shortened to
    %a{:href => root_url + '/' + @url.shorten}
      = root_url + '/' + @url.shorten      
%form{:method => 'post', :action => '/'}
  %div
    %label
      Shorten this:
      %input{:type => 'text', :name => 'long_url', :size => '50'}
    %input{:type => 'submit', :value => 'Shorten'}
