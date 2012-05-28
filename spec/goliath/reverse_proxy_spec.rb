require 'spec_helper'
require 'goliath/rack/reverse_proxy'

describe Goliath::Rack::ReverseProxy do
  it 'should load without errors' do
    lambda { Goliath::Rack::ReverseProxy.new('app', {:base_url => 'http://localhost'}) }.should_not raise_error
  end

  describe 'while used as middleware' do
    before(:each) do
      @app = double('app').as_null_object
      @app.should_receive(:call).and_return(initial_response)
      @env = Goliath::Env.new
      @proxy = Goliath::Rack::ReverseProxy.new(@app, {:base_url => 'http://localhost'})
    end

    it 'should create url to proxy to' do
      @env['REQUEST_METHOD'] = 'GET'
      @env['REQUEST_URI'] = '/a/test/file.html'
      action = double('http action').as_null_object
      action.should_receive(:get).and_return(response_object)
      EM::HttpRequest.should_receive(:new).with('http://localhost/a/test/file.html').and_return(action)
      @proxy.call(@env)
    end

    it 'should build the needed headers' do
      @env['REQUEST_METHOD'] = 'GET'
      @env['REQUEST_URI'] = '/'
      @env['SERVER_NAME'] = 'test.com'
      @env['HTTP_HOST'] = 'testing.com'
      @env['REMOTE_USER'] = 'bob'
      action = double('http action').as_null_object
      headers = {"HOST"=>"testing.com", "CONTENT_TYPE"=>nil, "HTTP_HOST"=>"test.com", "X-Forwarded-Host"=>"testing.com", "REMOTE_USER"=>"bob"}
      action.should_receive(:get).with(:head => headers).and_return(response_object)
      EM::HttpRequest.should_receive(:new).with('http://localhost/').and_return(action)
      @proxy.call(@env)
    end

    it 'should do a delete if a get was sent' do
      @env['REQUEST_METHOD'] = 'DELETE'
      @env['REQUEST_URI'] = '/some/item/23'
      action = double('http action').as_null_object
      action.should_receive(:delete).and_return(response_object)
      EM::HttpRequest.should_receive(:new).with('http://localhost/some/item/23').and_return(action)
      @proxy.call(@env)
    end

    it 'should do a post with body if a post was sent' do
      @env['REQUEST_METHOD'] = 'POST'
      @env['REQUEST_URI'] = '/some/item'
      action = double('http action').as_null_object
      action.should_receive(:post).and_return(response_object)
      EM::HttpRequest.should_receive(:new).with('http://localhost/some/item').and_return(action)
      @proxy.call(@env)
    end

    it 'should return the response from the proxied request' do
      @env['REQUEST_METHOD'] = 'GET'
      @env['REQUEST_URI'] = '/a/test/file.html'
      results  = response_object(401, {}, ['testing'])
      action = double('http action').as_null_object
      action.should_receive(:get).and_return(results)
      EM::HttpRequest.should_receive(:new).with('http://localhost/a/test/file.html').and_return(action)
      response = @proxy.call(@env)
      response.should == [401, {}, [["testing"]]]
    end

  end
end
