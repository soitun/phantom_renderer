require 'spec_helper'
require 'net/http'

describe PhantomRenderer, type: :controller do
  CACHE_KEY = "cache_key"
  EXPIRATION = 1.minute
  UNICORN_RESPONSE = "unicorn response"
  PHANTOM_RESPONSE = "phantom response"

  class FakeCache
    class << self
      def read(opts)
      end
      def write(key, val, opts)
      end
    end
  end

  def cfg
    @cfg ||= PhantomRenderer::Configuration
  end

  controller do
    include PhantomRenderer
    def index
      render_via_phantom(cache_key: CACHE_KEY, expires_in: EXPIRATION) || render(text: UNICORN_RESPONSE)
    end

    def show
      render_via_phantom
    end
  end

  before do
    ApplicationController.any_instance.stub :produce_single_page_header_and_footer_data
    Rails.cache.clear
    res = double body: PHANTOM_RESPONSE
    Net::HTTP.stub start: res
  end

  describe "GET index" do
    subject { response }

    context "with phantom header" do
      before do
        @request.env[cfg.request_by_phantom_header] = "true"
        get :index
      end

      it {should be_success}
      its(:body) {should eq UNICORN_RESPONSE}

      describe "headers" do
        subject {response.headers[cfg.request_by_phantom_header]}
        it {should be_blank}
      end
    end

    context "without phantom header" do
      before do
        get :index
      end

      it {should be_success}
      its(:body) {should eq PHANTOM_RESPONSE}

      describe "headers" do
        subject {response.headers[cfg.request_by_phantom_header]}
        it {should_not be_blank}
      end

    end

    describe "caching" do
      it "should cache result" do
        expect {
          get :index
        }.to change{Rails.cache.read(CACHE_KEY)}.from(nil)
      end

      it "should not render again after cached" do
        Rails.cache.write(CACHE_KEY, "cached data")
        get :index
        subject.body.should eq "cached data"
      end

      context "no cache key" do
        before do
          get :show, id: 1
        end
        it {should be_success}
      end

      describe "parameters" do
        before do
          Rails.stub cache: FakeCache
        end

        context "cache key" do
          it "should match opts" do
            FakeCache.should_receive(:write).with(CACHE_KEY, PHANTOM_RESPONSE, expires_in: EXPIRATION)
            get :index
          end
        end

        context "no cache key" do
          it "should not write to cache" do
            FakeCache.should_not_receive(:write)
            get :show, id: 1
          end
        end

        after do
          Rails.unstub :cache
        end
      end
    end

    describe "timeout handling" do
      before do
        Timeout.stub(:timeout).and_raise(Timeout::Error)
      end

      it "should not throw exception" do
        expect {get :index}.not_to raise_error
      end

      context "response" do
        before do
          get :index
        end
        it {should be_success}
        its(:body) {should eq UNICORN_RESPONSE}
      end

      after do
        Timeout.unstub(:timeout)
      end
    end

    describe "error handling" do

      before do
        Net::HTTP.stub(:start).and_raise(PhantomRenderer::RenderError)
      end

      it "should not throw exception" do
        expect {get :index}.not_to raise_error
      end

      it "should launch handle other exception" do
        controller.should_receive(:handle_other_exception)
        get :index
      end

      context "response" do
        before do
          get :index
        end

        it {should be_success}
        its(:body) {should eq UNICORN_RESPONSE }
      end
    end

  end

  describe "Configuration" do
    it "should have configuration values" do
      [ :server_ip, :server_port, :render_timeout, :request_by_phantom_header, :request_backend_header, :unicorn_port ].each do |attr|
        cfg.send(attr).should_not be_nil
      end
    end
  end

end

