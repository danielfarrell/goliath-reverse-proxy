require 'spec_helper'
require 'goliath/rack/reverse_proxy'

describe Goliath::Rack::ReverseProxy do

  def failed
    EM.stop
  end

  it 'should load without errors' do
    lambda { Goliath::Rack::ReverseProxy.new('app', {:base_url => 'http://localhost'}) }.should_not raise_error
  end

  describe 'while used as middleware' do
    before(:each) do
      @app = double('app').as_null_object
      @app.should_receive(:call).and_return(initial_response)
      @env = Goliath::Env.new
      @stub_connection = EventMachine::HttpConnection.new
      @stub_connection.stub(:dup => @stub_connection)
      EM::HttpRequest.should_receive(:new).with('http://localhost').and_return(@stub_connection)
      @proxy = Goliath::Rack::ReverseProxy.new(@app, {:base_url => 'http://localhost'})
    end

    it 'should create url to proxy to' do
      EM.synchrony do
        @env['REQUEST_METHOD'] = 'GET'
        @env['REQUEST_URI'] = '/a/test/file.html'
        @stub_connection.should_receive(:get).and_return(response_object)
        @proxy.call(@env)
        EM.stop
      end
    end

    it 'should build the needed headers' do
      EM.synchrony do
        @env['REQUEST_METHOD'] = 'GET'
        @env['REQUEST_URI'] = '/'
        @env['SERVER_NAME'] = 'test.com'
        @env['HTTP_HOST'] = 'testing.com'
        @env['REMOTE_USER'] = 'bob'
        headers = {"HOST"=>"testing.com", "X-Forwarded-Host"=>"testing.com", "X-Forwarded-User"=>"bob"}
        @stub_connection.should_receive(:get).with(:head => headers, :path => @env['REQUEST_URI']).and_return(response_object)
        @proxy.call(@env)
        EM.stop
      end
    end

    it 'should do a delete if a get was sent' do
      EM.synchrony do
        @env['REQUEST_METHOD'] = 'DELETE'
        @env['REQUEST_URI'] = '/some/item/23'
        @stub_connection.should_receive(:delete).and_return(response_object)
        @proxy.call(@env)
        EM.stop
      end
    end

    it 'should do a post with body if a post was sent' do
      EM.synchrony do
        @env['REQUEST_METHOD'] = 'POST'
        @env['REQUEST_URI'] = '/some/item'
        @stub_connection.should_receive(:post).and_return(response_object)
        @proxy.call(@env)
        EM.stop
      end
    end

    it 'should return the response from the proxied request' do
      EM.synchrony do
        @env['REQUEST_METHOD'] = 'GET'
        @env['REQUEST_URI'] = '/a/test/file.html'
        results  = response_object(401, {}, ['testing'])
        @stub_connection.should_receive(:get).and_return(results)
        response = @proxy.call(@env)
        response.should == [401, {}, [["testing"]]]
        EM.stop
      end
    end

  end
end
