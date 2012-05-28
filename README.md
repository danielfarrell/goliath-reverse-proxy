goliath-reverse-proxy
=====================

Kerberos/GSSAPI authentication (Basic and Negotiate) rack middleware.

Actually this middleware should (hopefully) work for standard Rack
application and as a Goliath middleware.

Dependencies
============
All the work is done by em-http-request, em-syncrony, and goliath.

Example
=======

```ruby
require 'goliath'
require 'goliath/rack/reverse_proxy'

class Proxy < Goliath::API
  # Include other middleware here before the proxy
  # Params is required to pass along data
  use Goliath::Rack::Params
  use Goliath::Rack::ReverseProxy, base_url: 'http://127.0.0.1:8000'

  def response(env)
    [200, {}, []]
  end
end
```

