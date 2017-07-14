require 'settingslogic'
require 'dotenv'

module Settings
  ROOT_DIR = File.dirname(__dir__).to_s
  puts "Dir: #{Settings::ROOT_DIR}"

  CUR_DIR = ROOT_DIR.include?('uri:classloader:') ? File.split(ROOT_DIR).first : ROOT_DIR
  puts "Cur Dir: #{CUR_DIR}"

  CONFIG_FILE = File.join(CUR_DIR, 'config', 'config.yml')
  puts "Config File: #{CONFIG_FILE}"
  unless File.exist? CONFIG_FILE
    puts "Error: Not found config file - #{CONFIG_FILE}!"
    exit!
  end

  SECRETS_FILE = File.join(CUR_DIR, 'config', "secrets.env.#{ENV['RUN_ENV']}")
  puts "Secrets Env File: #{SECRETS_FILE}"
  unless File.exist? SECRETS_FILE
    puts "Error: Not found secrets file - #{SECRETS_FILE}!"
    exit!
  end

  class Config < Settingslogic
    namespace ENV['RUN_ENV']
  end

  ALL = Config.new CONFIG_FILE

  Dotenv.load SECRETS_FILE

  # Certificates
  ## Apple
  APNS_CERT = File.join(CUR_DIR, 'keys', ALL.cert_apple)
  puts "APNS Cert: #{APNS_CERT}"
  unless File.exist? APNS_CERT
    puts "Error: Not found APNS Cert - #{APNS_CERT}!"
    exit!
  end

end
