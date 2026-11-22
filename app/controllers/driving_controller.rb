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
    valid_routes = @result.is_a?(Array) && @result.all? do |route|
      location = route.is_a?(Hash) ? route['location'] : nil
      distance = route.is_a?(Hash) ? route['distance'] : nil
      location.is_a?(Hash) && distance.is_a?(Hash) &&
        location['src'].is_a?(String) && location['src'].present? &&
        location['dest'].is_a?(String) && location['dest'].present? &&
        distance['highway'].present? && distance['localway'].present?
    end
    raise Api::GoogleRoute::Request::RequestError, 'invalid route response structure' unless valid_routes

    render :list
  rescue Api::GoogleGeo::Request::RequestError, Api::GoogleRoute::Request::RequestError,
         KeyError, TypeError, ArgumentError => e
    Rails.logger.warn("driving list failed: #{e.class}: #{e.message}")
    redirect_to driving_index_path, alert: '経路情報を取得できませんでした。時間をおいて再度お試しください'
  end
end
