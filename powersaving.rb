# -*- coding: utf-8 -*-
# 節電しよう！

require 'open-uri'

Module.new do
  URL = "http://www.tepco.co.jp/forecast/html/images/juyo-j.csv"

  interval = 3600
  nextcheck = Time.new + interval
  plugin = Plugin.create(:powersaving)
  plugin.add_event(:boot){ |service| refresh }
  plugin.add_event(:period){ |service|
    if nextcheck < Time.new
      nextcheck =+ interval
      refresh end }

  class << self
    def refresh()
      log = getval()
      hour = last_time(log)
      mes = "#{hour}時の東京電力の電力使用実績は、#{log[hour].first}万kW (前日比 "
      dif = log[hour].first - log[hour].last
      if dif == 0
        mes << "±0"
      elsif dif > 0
        mes << "+#{dif}"
      else
        mes << "#{dif}" end
      mes << "万kW) でした。" + yokeina_hitokoto(dif)
      Plugin.call(:update, nil, [Message.new(:message => mes,
                                             :system => true)])
    end

    def yokeina_hitokoto(dif)
      case
      when dif > 500
        "ﾋﾟｬｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱｱ"
      when dif > 100
        "節電しましょう！"
      when dif < 100
        "いい感じです"
      when dif < 500
        "すごく減ってます！Pen4のマシンつけても大丈夫ですよ！知らないけど"
      else
        "まあこんなものでしょう"
      end
    end

    def last_time(data = getval())
      data.each_with_index{ |data, hour|
        if(data.first == 0)
          return hour - 1
        end
      }
      return 23
    end

    # [時 => [当日実績, 前日実績]]
    def getval()
      open(URL){ |io|
        ary = io.to_a
        ary = ary[2..ary.size]
        ary.map{ |line|
          day, hour, today, yesterday = line.split(',').map{ |node|
            node.chomp }
          [today.to_i, yesterday.to_i]
        } } end
  end

end
