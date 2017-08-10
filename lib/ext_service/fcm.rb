require 'faraday'
require 'faraday_middleware'

module ExtService; end

module ExtService::FCM
  class FCMClient
    def initialize
      @url = 'https://fcm.googleapis.com'
      @url_path = '/fcm/send'
      @api_key = ENV['FCM_API_KEY']
      @connection = _create_connection
    end

    def _create_connection
      _options = {headers: {Authorization: "key=#{@api_key}"}}
      Faraday.new(@url, _options) do |faraday|
        faraday.request  :json
        faraday.response :logger, @logger, headers: false # log requests to STDOUT
        faraday.response :json, :content_type => /\bjson$/
        faraday.adapter  Faraday.default_adapter
      end
    end

    def notification(ids: [], text: '')
      return if ids.empty?
      _text = text.strip
      return if _text.empty?
      {
        registration_ids: ids,
        data: {
          text: _text,
          sound: 'default'
        }
      }
    end

    def push(notification)
      resp = @connection.post @url_path, notification
      _status = resp.status
      case _status
      when 200
        _process_response_body resp.body, notification.fetch(:registration_ids)
      else
        {errors: {response_status: _status}}
      end
    end

    def _process_response_body(resp, ids)
      _failure, _canonical_ids = resp.fetch('failure'), resp.fetch('canonical_ids')
      if _failure.zero? and _canonical_ids.zero?
        { status: :success }
      else
        puts 'proccess results array'
        { status: :success }.merge _process_results(ids, resp.fetch('results'))
      end
    end

    def _process_results(notification_ids, results)
      results.each_with_index.inject({}) do |acc, (result, i)|
        _tmp = _process_result result, i, notification_ids
        (acc[:remove_ids] ||= []) << _tmp[:remove] if _tmp.key? :remove
        (acc[:resend_ids] ||= []) << _tmp[:resend] if _tmp.key? :resend
        (acc[:update_ids] ||= []) << _tmp[:update] if _tmp.key? :update
        (acc[:errors]     ||= []) << _tmp[:error]  if _tmp.key? :error
        acc
      end
    end

    def _process_result(result, result_index, ids)
      _error = result['error']
      _registration_id = result['registration_id']
      r = {}
      case _error
      when 'NotRegistered', 'InvalidRegistration'
        r[:remove] = ids[result_index]
      when 'Unavailable'
        r[:resend] = ids[result_index]
      when (not nil)
        r[:error] = _error
      end
      r[:update] = {old: ids[result_index], new: _registration_id} if _registration_id
      r
    end
  end

  module_function
  
  def api
    @@gcm ||= FCMClient.new
  end

end
