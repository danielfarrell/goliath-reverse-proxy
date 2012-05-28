$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
$:.unshift File.expand_path(File.dirname(__FILE__))

require 'rspec'
require 'goliath'
require 'ostruct'

class ResponseHeader < Hash
  def status
    @status || 200
  end

  def status=(status)
    @status = status
  end
end

class Response
  attr_reader :response, :response_header

  def initialize(code, headers, response)
    @response = response
    @response_header = ResponseHeader.new(headers)
    @response_header.status = code
  end

end

def response_object(code=200, headers={}, body=[])
  Response.new(code, headers, body)
end

def initial_response
  [200, {}, []]
end
