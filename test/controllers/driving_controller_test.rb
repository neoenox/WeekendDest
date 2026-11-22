require 'test_helper'

class DrivingControllerTest < ActionDispatch::IntegrationTest
  test 'redirects instead of calling route API when no nearby tourist exists' do
    Tourist.delete_all

    fake_geo = Object.new
    def fake_geo.request(_src)
      { 'result' => { 'latitude' => 35.0, 'longitude' => 139.0 } }
    end

    Api::GoogleGeo::Request.stub(:new, fake_geo) do
      get list_driving_index_url, params: { src: 'Tokyo' }
    end

    assert_redirected_to driving_index_path
    assert_equal '100km以内に候補の観光地が見つかりませんでした', flash[:alert]
  end

  test 'redirects with a user-facing message when geocoding fails' do
    fake_geo = Object.new
    def fake_geo.request(_src)
      raise Api::GoogleGeo::Request::RequestError, 'HTTP 503'
    end

    Api::GoogleGeo::Request.stub(:new, fake_geo) do
      get list_driving_index_url, params: { src: 'Tokyo' }
    end

    assert_redirected_to driving_index_path
    assert_equal '経路情報を取得できませんでした。時間をおいて再度お試しください', flash[:alert]
  end

  test 'renders valid route responses' do
    assert_route_response(
      [{ 'location' => { 'src' => 'Tokyo', 'dest' => '35.0,139.0' },
         'distance' => { 'highway' => 12, 'localway' => 15 } }],
      valid: true
    )
  end

  test 'rejects incomplete route response entries without a 500' do
    invalid_results = [
      [nil],
      [{ 'location' => nil, 'distance' => nil }],
      [{ 'location' => { 'src' => 'Tokyo' }, 'distance' => { 'highway' => 12, 'localway' => 15 } }],
      [{ 'location' => { 'src' => 'Tokyo', 'dest' => '35.0,139.0' }, 'distance' => nil }],
      [{ 'location' => { 'src' => 'Tokyo', 'dest' => '35.0,139.0' }, 'distance' => { 'highway' => 12 } }],
      [{ 'location' => { 'src' => '', 'dest' => '35.0,139.0' }, 'distance' => { 'highway' => 12, 'localway' => 15 } }]
    ]
    invalid_results.each { |result| assert_route_response(result, valid: false) }
  end

  private

  def assert_route_response(result, valid:)
    Tourist.delete_all
    Tourist.create!(place_name: 'Nearby', latitude: 35.0, longitude: 139.0, address: 'Tokyo', notice: 'sample')

    geo = Object.new
    def geo.request(_src)
      { 'result' => { 'latitude' => 35.0, 'longitude' => 139.0 } }
    end
    route = Object.new
    route.define_singleton_method(:request) { |_candidates| { 'result' => result } }

    Api::GoogleGeo::Request.stub(:new, geo) do
      Api::GoogleRoute::Request.stub(:new, route) do
        get list_driving_index_url, params: { src: 'Tokyo' }
      end
    end

    if valid
      assert_response :success
      assert_includes response.body, 'Nearby'
    else
      assert_redirected_to driving_index_path
      assert_equal '経路情報を取得できませんでした。時間をおいて再度お試しください', flash[:alert]
    end
  end
end
