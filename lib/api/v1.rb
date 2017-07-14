module API
  class App < Sinatra::Base
    register Sinatra::Namespace
    helpers Sinatra::Param

    namespace '/api/v1' do
      before do
        content_type :json
      end

      post '/apple' do
        param :token, String, format: /^[^-]+[a-fA-F0-9-]+[^-]+$/, required: true
        param :alert, String, format: /^(\S+.*\S+)$/
        param :badge, Integer, min: 0, max: 999
        any_of :alert, :badge

        args = { token: params[:token][0..127] }
        args.merge!(alert: params[:alert][0..511]) if params[:alert]
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
    end
  end
end
