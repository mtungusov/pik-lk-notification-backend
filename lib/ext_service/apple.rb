require 'houston'

module ExtService; end

module ExtService::Apple
  class APNS
    def initialize
      @uri = ENV['RUN_ENV'] == 'production' ? Houston::APPLE_PRODUCTION_GATEWAY_URI : Houston::APPLE_DEVELOPMENT_GATEWAY_URI
      @cert_file_path = Settings::APNS_CERT
      @cert_pass = ENV['APNS_CERT_PASS']
      @connection = _create_connection
    end

    def _create_connection
      certificate = File.read(@cert_file_path)
      connection = Houston::Connection.new(@uri, certificate, @cert_pass)
      connection.open
      connection
    end

    def notification(token:, alert: nil, badge: nil)
      n = Houston::Notification.new(device: token)
      n.alert = alert if alert
      n.badge = badge if badge
      n
    end

    def push(notification)
      @connection.open unless @connection.open?
      r, e = nil, nil
      begin
        @connection.write(notification.message)
        error_status = _error_response(@connection)
        if error_status.nil? || error_status == 10
          notification.mark_as_sent!
          r = { error: error_status, status: :success }
        else
          notification.apns_error_code = error_status
          notification.mark_as_unsent!
          e = { status: error_status, token: notification.token }
        end

        if error_status
          puts "Error: APNS status - #{error_status}"
          close
        end
      rescue => error
        puts "Error: #{error}"
        close
        return [r, error]
      end
      [r, e]
    end

    def close
      @connection.close if @connection.open?
    end

    def _error_response(conn)
      status = nil
      ssl = conn.ssl
      read_socket, _ = IO.select([ssl], [ssl], [ssl], nil)
      if (read_socket && read_socket[0])
        if error = conn.read(6)
          _, status, _ = error.unpack("ccN")
        end
      end
      status
    end

  end

  module_function

  def api
    @@apple ||= APNS.new
  end
end
