module API
  class App < Sinatra::Base
    register Sinatra::Namespace
    helpers Sinatra::Param

    namespace '/api/v1' do
      before do
        content_type :json
      end

      post '/apple' do
        param :token, String, format: /^[^-]+[a-fA-F0-9-]+[^-]+$/, max_length: 128, required: true
        param :alert, String, format: /^(\S+.*\S+)$/, max_length: 1024
        param :badge, Integer, min: 0, max: 999
        any_of :alert, :badge

        args = { token: params[:token] }
        args.merge!(alert: params[:alert]) if params[:alert]
        args.merge!(badge: params[:badge]) if params[:badge]

        notification = ExtService::Apple.api.notification args

        r, e = ExtService::Apple.api.push(notification)

        result = if e
          { errors: e }
        else
          { result: r }
        end

        result.to_json
      end

      post '/google' do
        param :google_tokens, Array, max_length: 1000, required: true
        param :alert, String, format: /^(\S+.*\S+)$/, max_length: 1024, required: true

        args = { ids: params[:google_tokens], text: params[:alert] }
        notification = ExtService::FCM.api.notification args
        r = ExtService::FCM.api.push(notification)
        r.key?('errors') ? r.to_json : { result: r }.to_json
      end
    end
  end
end
