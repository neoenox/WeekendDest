class Tourist < ApplicationRecord
  def self.distance(lat1, lng1, lat2, lng2)
    # 緯度経度をラジアンに変換
    rlat1 = lat1 * Math::PI / 180
    rlng1 = lng1 * Math::PI / 180
    rlat2 = lat2 * Math::PI / 180
    rlng2 = lng2 * Math::PI / 180

    # 2点の中心角(ラジアン)を求める
    a =
      Math.sin(rlat1) * Math.sin(rlat2) +
      Math.cos(rlat1) * Math.cos(rlat2) *
      Math.cos(rlng1 - rlng2)
    # 浮動小数点誤差で理論範囲 [-1, 1] をわずかに外れることがあるため補正する
    a = [[a, -1.0].max, 1.0].min
    rr = Math.acos(a)

    earth_radius = 6_378_140 # 地球赤道半径(メートル)
    (earth_radius * rr / 1000).floor
  end
end
