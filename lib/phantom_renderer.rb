module PhantomRenderer

  def render_via_phantom(opts = {})
    cached = opts[:cache_key] && Rails.cache.read(opts[:cache_key])
    if cached
      ActiveSupport::Notifications.instrument('phantom_renderer.cache.responses.count')
      render text: cached
    elsif !requested_by_phantom?
      uri = get_phantom_uri
      req = assemble_phantom_request(uri)
      res = get_response_from_phantom(uri, req)
      if res
        ActiveSupport::Notifications.instrument('phantom_renderer.renders.count')
        Rails.cache.write(opts[:cache_key], res, expires_in: opts[:expires_in]) if opts[:cache_key]
        render text: res
      end
    end

  end
  
  private

  def requested_by_phantom?
    !phantom_header.blank?
  end

  def cfg
    PhantomRenderer::Configuration
  end

  def phantom_header
    request.headers[cfg.request_by_phantom_header]
  end

  def get_response_from_phantom(uri, req)
    begin
      res = Timeout.timeout(cfg.render_timeout) do
        ActiveSupport::Notifications.instrument('phantom_renderer.renders.time') do
          Net::HTTP.start(uri.host, uri.port) {|http| http.request(req) }
        end
      end
      response.headers[cfg.request_by_phantom_header] = "true"
      if res.code.to_i == 200
        return res.body
      else
        return false
      end
    rescue Timeout::Error => e
      handle_timeout(e, uri)
      return false
    rescue Exception => e
      handle_other_exception(e, uri)
      return false
    end
  end

  def assemble_phantom_request(uri)
    req = Net::HTTP::Get.new(uri.request_uri)
    req.add_field cfg.request_by_phantom_header, "true"
    req.add_field cfg.request_backend_header, "#{private_ip_address}:#{cfg.unicorn_port}"
    req
  end

  def get_phantom_uri
    uri = URI(request.original_url)
    uri.host = cfg.server_ip
    uri.port = cfg.server_port
    uri
  end

  def handle_timeout(e, uri)
    ActiveSupport::Notifications.instrument('phantom_renderer.errors.timeout', error: e.class.name, message: e.message, url: uri)
  end

  def handle_other_exception(e, uri)
    ActiveSupport::Notifications.instrument('phantom_renderer.errors.other', error: e.class.name, message: e.message, url: uri)
  end

  def private_ip_address
    @private_ip_address ||= begin
                              require 'socket'
                              ip=Socket.ip_address_list.detect{|intf| intf.ipv4_private?}
                              ip.ip_address
                            end
  end


  class TimeoutError < RuntimeError; end;
  class RenderError < RuntimeError; end;

  class Configuration
    class << self
      [ :server_ip, :server_port, :render_timeout, :request_by_phantom_header, :request_backend_header, :unicorn_port ].each do |attr|
        define_method attr do
          config[attr]
        end
      end

      def config
        @config ||= HashWithIndifferentAccess.new(YAML.load_file(Rails.root.join("config/phantom_renderer.yml"))[Rails.env])
      end


    end
  end
end

