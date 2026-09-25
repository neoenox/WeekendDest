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
end
