require 'faraday'
require 'faraday_middleware'

module ExtService; end

module ExtService::GCM
  class GCMClient
    def initialize
      @url = 'https://android.googleapis.com'
      @url_path = '/gcm/send'
      @api_key = ENV['GCM_API_KEY']
      @connection = _create_connection
    end

    def _create_connection
      _options = {headers: {Authorization: "key=#{@api_key}"}}
      Faraday.new(@url, _options) do |faraday|
        faraday.request  :json
        faraday.response :logger, @logger, headers: true # log requests to STDOUT
        faraday.response :json, :content_type => /\bjson$/
        faraday.adapter  Faraday.default_adapter
      end
    end

    def notification(ids: [], text:"")
      return if ids.empty?
      _text = text.strip
      return if _text.empty?
      {
        registration_ids: ids,
        data: {
          text: _text,
          sound: 'default'
        },
        delay_while_idle: true
      }
    end

    def push(notification)
      resp = @connection.post @url_path, notification
      resp
    end
  end

  module_function
  
  def api
    @@gcm ||= GCMClient.new
  end


end
