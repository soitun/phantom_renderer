# PhantomRenderer
![Build Status](https://api.travis-ci.org/FTBpro/phantom_renderer.png?branch=master "Build Status")

phantom_renderer is a ruby-gem meant to work with Rails applications to render
full HTML pages out of single-page applications.  
It is intended to work with [phantom_server](https://github.com/FTBpro/phantom_server) which is a separate server which performs the actual HTML rendering.

## Why should you?

If you're using single-page frameworks like AngularJS or EmberJS you must know
the major pains:

1. SEO - search engines do not render JS so they have to get a full version of
   the page in order to correctly index your site.
2. Caching - In order to cache full rendred pages in your local cache or CDN
   you have to be able to fully render them
3. Mobile Performance - Some older devices are having difficulties executing
   the JS involved in single-page applications.

## How phantom_renderer resolves these issues?

By rendering full HTML pages:

1. Search engines will receive a full HTML of your pages and won't have any
   trouble indexing it.
2. You will have fully rendered HTML pages in your local cache or CDN.
3. Since mobile devices will mainly get fully renderd pages they won't have to
   go through the hassle of rendering them themselves thus reducing the
   performance issues with single-page applications.


## Installation

1. `gem "phantom_renderer"` in your `Gemfile`
2. `bundle install`

## Configuration

Put the following configuration in `config/phantom_renderer.yml`:  

```yaml
defaults: &defaults
  # ip of phantom_server
  server_ip: 1.1.1.1 
  # port from which phantom_server will request the single-page HTML
  unicorn_port: 80 
  # If phantom_server does not render within 5 seconds return the single-page HTML
  render_timeout: 5 

  server_port: 80 # no need to change
  request_by_phantom_header: X-Phantom # no need to change
  request_backend_header: X-Backend-Host # no need to change


development: &development
  <<: *defaults
  server_ip: localhost

test:
  <<: *defaults

production:
  <<: *defaults
  server_ip: 2.2.2.2

```


## Usage

1. phantom_renderer is meant to be used as a rendering engine in your controller.  
   Instead of sending the single-page application you will ask phantom_renderer to
   render the full HTML page for you:  
   ```ruby
   class UsersController < ApplicationController
     include PhantomRenderer
     def show
       render_via_phantom
     end
   end
   ```

2. In your Javascript, when you want phantom_server to return the rendered page,
   insert the followin snippet:

   ```javascript
   var readyEvent = document.createEvent("Event");
   readyEvent.initEvent("renderReady", true, true);
   window.dispatchEvent(readyEvent);
   ```

## Caching

phantom_renderer supports caching of full HTML pages returned by phantom_server
to prevent re-rendering the same pages.  
In order to cache the returned result just pass a `cache_key` option to the
`render_via_phantom` statement:
```ruby
class UsersController < ApplicationController
  include PhantomRenderer
  def show
    render_via_phantom(cache_key: "User_#{params[:id]}")
  end
end
```

This will save the fully rendered HTML page in `Rails.cache` so that the next
time this page is requested it will be served from cache and not re-rendered by
phantom_server.  
If the phantom_server did not render the page well or returned a response
different than HTTP 200 the page won't be cached.
