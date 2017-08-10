require 'java'

java_import java.lang.System

puts 'Start App'
puts "Java:  #{System.getProperties['java.runtime.version']}"
puts "Jruby: #{ENV['RUBY_VERSION']}"

require 'lib/settings'
puts "Namespace: #{Settings::Config.namespace}"
puts "App: #{Settings::ALL.app_name}"

require 'lib/ext_service'

# require 'pry'
# binding.pry

# gcm = ExtService::GCM.api
# n = gcm.notification(ids: ["APA91bGms1iKIPdKURo7CAi1bGx4kZ_1EB-8m950An3LPDkvMRkxRKofz7yvuZGvzrFpDl6hjOz5zjNbMA1ue2xfBknnGU-dwkUVC74A-rYHIOdydX2PgDZ4IPdT2C_Gjl6eHq_5c356"], text: "Hello from client!")
# resp = gcm.push n

# apple = ExtService::Apple.api
# n = apple.notification(token: '1985FB22936A678CC90D4723E31F3A1F697F02B34E1C2292803F02D7F37158DF',
#                        alert: 'Test Msg',
#                        badge: 77)
# apple.push(n)

require 'rack/contrib/nested_params'
require 'rack/contrib/post_body_content_type_parser'
require 'lib/api'

use Rack::NestedParams
use Rack::PostBodyContentTypeParser

at_exit {
  puts 'Terminate:at_exit:start'
  # Close connections
  ## Apple
  ExtService::Apple.api.close

  sleep 1
  puts 'Terminate:at_exit:end'
  exit!
}

run API::App
