require 'em-synchrony/em-http'

module Goliath
  module Rack
    class ReverseProxy
      include Goliath::Rack::AsyncMiddleware

      def initialize(app, options)
        @app = app
        @connection = EM::HttpRequest.new(options[:base_url])
      end

      def call(env)
        connection = @connection.dup
        super(env, connection)
      end

      def post_process(env, status, headers, body, connection)
        method = env['REQUEST_METHOD'].downcase.to_sym

        options = {:head => request_headers(env, headers), :path => env['REQUEST_URI']}
        options[:body] = env['params'] if [:put, :post, :patch].include? method

        http = connection.send(method, options)

        [http.response_header.status, http.response_header.raw, [http.response]]
      end

      def request_headers(env, headers)
        env.each do |key, value|
          headers[$1] = value if key =~ /HTTP_(.*)/
        end
        headers['X-Forwarded-Host'] = env['HTTP_HOST']
        headers['X-Forwarded-User'] = env['REMOTE_USER'] if env['REMOTE_USER']
        headers
      end

    end
  end
end
