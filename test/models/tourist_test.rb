require 'test_helper'

class TouristTest < ActiveSupport::TestCase
  test "distance is zero for identical coordinates" do
    assert_equal 0, Tourist.distance(35.681236, 139.767125, 35.681236, 139.767125)
  end

  test "distance does not raise for extremely close coordinates" do
    distance = nil
    assert_nothing_raised do
      distance = Tourist.distance(35.681236, 139.767125, 35.681236000001, 139.767125000001)
    end
    assert_operator distance, :>=, 0
  end

  test "distance does not raise near antipodal boundary" do
    distance = nil
    assert_nothing_raised do
      distance = Tourist.distance(0.0, 0.0, 0.0, 180.0)
    end
    assert_operator distance, :>, 20_000
  end
end
