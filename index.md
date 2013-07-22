---
title: Getting started
layout: default
---


### Installation

HTTPI is available through [Rubygems](http://rubygems.org/gems/httpi) and can be installed via:

{% highlight bash %}
$ gem install httpi
{% endhighlight %}

<ul id='links'>
  <li><a href='http://github.com/rubiii/httpi'><code>Code (Github)</code></a></li>
  <li><a href='http://rubydoc.info/gems/httpi/frames'><code>RDoc (Rubydoc)</code></a></li>
  <li><a href='http://travis-ci.org/#!/savonrb/httpi'><code>CI (Travis)</code></a></li>
  <li><a href='https://groups.google.com/forum/#!forum/httpirb'><code>Mailing list (Google)</code></a></li>
</ul>


### Adapters

HTTPI provides a common interface for Ruby’s most popular HTTP clients:

* [HTTPClient](http://rubygems.org/gems/httpclient)
* [Curb](http://rubygems.org/gems/curb)
* [EM-HTTP-Request](http://rubygems.org/gems/em-http-request) (also requires [EM-Synchrony](http://rubygems.org/gems/em-synchrony))
* [Net::HTTP](http://ruby-doc.org/stdlib/libdoc/net/http/rdoc)
* [Net::HTTP::Persistent](http://rubygems.org/gems/net-http-persistent)
* [excon](http://rubygems.org/gems/excon)
* [Rack](http://rubygems.org/gems/rack)

Due to the fact that Rubygems does not allow optional dependencies, HTTPI does not specify any of these
libraries as direct dependencies. Therefore if you want to use anything other than Net::HTTP, you need
to make sure it’s available in your load path.

When you’re executing any HTTP request for the first time without having specified an adapter to use,
HTTPI tries to load and use the "best" library for you. It follows a specific load order with Net::HTTP at the
end of the chain:

``` ruby
[:httpclient, :curb, :em_http, :excon, :net_http, :net_http_persistent]
```

You can also manually specify which adapter you would like to use:

``` ruby
HTTPI.adapter = :curb
```


#### Adding new adapters

Also as of version 2, you can extend HTTPI to support your very own adapter by creating a class
that inherits from `HTTPI::Adapter::Base` and implements a simple interface.

``` ruby
# [1] inherit from the base class
class MyAdapter < HTTPI::Adapter::Base

  # [2] register your adapter and a list of dependencies
  register :my_adapter, deps: %w(some_http_client)

  # [3] your adapter receives the request on initialize
  def initialize(request)
    @request = request
    @client = SomeHTTPClient.new
  end

  # [4] make the underlying client available to others
  attr_reader :client

  # [5] execute an arbitary HTTP request
  def request(method)
    response = @client.request(method, @request.url, @request.body)

    # [6] always return a response object
    Response.new(response.code, response.header, response.content)
  end

end
```


### Requests

In order to provide a common interface, HTTPI exposes the `HTTPI::Request` (request) object for you to configure
your requests. Here’s a very simple example of how you can use this object to execute a GET request:

``` ruby
request = HTTPI::Request.new("http://example.com")
HTTPI.get(request)
```

And here’s an example of a POST request with a payload using the Curb adapter:

``` ruby
request = HTTPI::Request.new
request.url = "http://example.com"
request.body = "bangarang"

HTTPI.post(request, :curb)
```

The previous example only specifies a URL and a request body. For simple use cases like this, HTTPI allows you
to omit the request object:

``` ruby
HTTPI.post("http://example.com", "bangarang", :curb)
```

As you can see, the `HTTPI` module provides access to common HTTP request methods. All of them either accept a
request object or a certain set of convenience arguments. Along these arguments, you can optionally specify the
adapter to use per request.

##### GET:

``` ruby
HTTPI.get(request, adapter = nil)
HTTPI.get(url, adapter = nil)
```

##### POST:

``` ruby
HTTPI.post(request, adapter = nil)
HTTPI.post(url, body, adapter = nil)
```

##### HEAD:

``` ruby
HTTPI.head(request, adapter = nil)
HTTPI.head(url, adapter = nil)
```

##### PUT:

``` ruby
HTTPI.put(request, adapter = nil)
HTTPI.put(url, body, adapter = nil)
```

##### DELETE:

``` ruby
HTTPI.delete(request, adapter = nil)
HTTPI.delete(url, adapter = nil)
```

##### REQUEST:

``` ruby
HTTPI.request(method, request, adapter = nil)
```

The request method is special. You can use it to dynamically specify the HTTP request method to use.

``` ruby
http_method = :get
request = HTTPI::Request.new("http://example.com")

HTTPI.request(http_method, request)
```

It can also be used for custom HTTP methods. Currently this is only supported by HTTPClient and EM-HTTP-Request.

``` ruby
HTTPI.request(:custom, request)
```


### Options

The `HTTPI::Request` object should support every option you might need to specify.
It can be created with a request URL, an options Hash or no arguments at all.

``` ruby
HTTPI::Request.new
HTTPI::Request.new("http://example.com")
HTTPI::Request.new(url: "http://example.com", open_timeout: 15)
```

Of course, every Hash option also has its own accessor method.

##### URL

``` ruby
request.url = "http://example.com"
request.url # => #<URI::HTTP:0x101c1ab18 URL:http://example.com>
```

##### Query

``` ruby
request.url = "http://example.com"
request.query = "q=query"
# or
request.query = {:q => "query"}
request.url.to_s # => "http://example.com?q=query"
```

##### Proxy

``` ruby
request.proxy = "http://example.com"
request.proxy # => #<URI::HTTP:0x101c1ab18 URL:http://example.com>
```

##### Headers

``` ruby
request.headers["Accept-Charset"] = "utf-8"
request.headers = { "Accept-Charset" => "utf-8" }

request.headers # => { "Accept-Charset" => "utf-8" }
```

##### Body

``` ruby
request.body = "scary monsters and nice sprites"
request.body # => "scary monsters and nice sprites"

request.body = { user_id: 123, active: false }
request.body # => "user_id=123&active=false"
```

##### Timeouts

``` ruby
request.open_timeout = 30 # seconds
request.read_timeout = 30 # seconds
```


### Authentication

`HTTPI::Request` supports HTTP basic and digest authentication.

``` ruby
request.auth.basic("username", "password")
request.auth.digest("username", "password")
```

The `:curb` adapter provides support for HTTP Negotiate/SPNEGO (aka Kerberos) authentication.

``` ruby
request.auth.gssnegotiate
```

For NTLM authentication, HTTPI ships with a solution build on top of the `:net_http` adapter
and the [Ruby/NTLM](http://rubygems.org/gems/rubyntlm) library. The configuration method accepts
an optional third parameter to specify a domain. If the domain is omitted we assume that you want
to authenticate to the local server.

``` ruby
request.auth.ntlm("username", "password")
request.auth.ntlm("username", "password", "domain")
```

In case you're using SSL client authentication, HTTPI has you covered as well.

``` ruby
request.auth.ssl.cert_key_file     = "client_key.pem"   # the private key file to use
request.auth.ssl.cert_key_password = "C3rtP@ssw0rd"     # the key file's password
request.auth.ssl.cert_file         = "client_cert.pem"  # the certificate file to use
request.auth.ssl.ca_cert_file      = "ca_cert.pem"      # the ca certificate file to use
request.auth.ssl.verify_mode       = :none              # or one of [:peer, :fail_if_no_peer_cert, :client_once]
request.auth.ssl.ssl_version       = :TLSv1             # or one of [:SSLv2, :SSLv3]
```


### Responses

Every request returns an `HTTPI::Response` object which contains various details like the response code,
headers and response body.

``` ruby
response = HTTPI.get(request)
response.body # => "<!DOCTYPE HTML PUBLIC ...>"
```

##### Code:

``` ruby
response.code # => 200
```

##### Headers:

``` ruby
response.headers # => { "Content-Encoding" => "gzip" }
```

##### Body:

``` ruby
response.body # => "<!DOCTYPE HTML PUBLIC ...>"
```

This method automatically handles gzipped and [DIME](http://en.wikipedia.org/wiki/Direct_Internet_Message_Encapsulation) encoded responses.
You can still access the raw response body though:

``` ruby
response.raw_body # => "x��Qt�w�pU���Qu��tV��ӳ�[��"
```

##### Error:

``` ruby
response.code   # => 404
response.error? # => true
```

A response is considered successful when the response code lies between 200 and 299.


### Logging

HTTPI by default logs each HTTP request to $stdout using a log level of :debug.

``` ruby
HTTPI.log       = false     # disable logging
HTTPI.logger    = MyLogger  # change the logger
HTTPI.log_level = :info     # change the log level
```
