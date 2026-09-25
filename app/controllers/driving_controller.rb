class DrivingController < ApplicationController
  def index
    p 'index start'
  end

  def list
    p 'list start'
    if params[:src].blank?
      redirect_to driving_index_path, alert: '出発地を入力してください'
      return
    end

    geo_response = Api::GoogleGeo::Request.new.request(params[:src])
    geo_result = geo_response.fetch('result')
    latitude = Float(geo_result.fetch('latitude'))
    longitude = Float(geo_result.fetch('longitude'))

    candidates = []
    Tourist.find_each do |tourist|
      distance = Tourist.distance(
        latitude,
        longitude,
        tourist['latitude'].to_f,
        tourist['longitude'].to_f
      )
      next unless distance < 100

      candidates.push(
        {
          src: params[:src],
          dest: tourist['latitude'].to_s + ',' + tourist['longitude'].to_s,
          place_name: tourist['place_name']
        }
      )
    end

    if candidates.empty?
      redirect_to driving_index_path, alert: '100km以内に候補の観光地が見つかりませんでした'
      return
    end

    @srcdestMap = candidates.sample
    route_response = Api::GoogleRoute::Request.new.request([@srcdestMap])
    @result = route_response.fetch('result')
    raise Api::GoogleRoute::Request::RequestError, 'route result is not an array' unless @result.is_a?(Array)

    render :list
  rescue Api::GoogleGeo::Request::RequestError, Api::GoogleRoute::Request::RequestError,
         KeyError, TypeError, ArgumentError => e
    Rails.logger.warn("driving list failed: #{e.class}: #{e.message}")
    redirect_to driving_index_path, alert: '経路情報を取得できませんでした。時間をおいて再度お試しください'
  end
end
