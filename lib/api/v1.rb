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

        # _token = params[:token][0..127]
        # _alert = params[:alert][0..511] if params[:alert]
        # _badge = params[:badge] if params[:badge]

        notification = ExtService::Apple.api.notification(token: params[:token][0..127],
                                                          alert: params[:alert][0..511],
                                                          badge: params[:badge])
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
