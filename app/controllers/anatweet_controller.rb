# -*- coding: utf-8 -*-
class AnatweetController < ApplicationController

#  $KCODE = 'u'
  require'MeCab'
  require 'rexml/document'
  require 'open-uri'
  require 'nkf'

  $checkin_shops = Array.new()
  $match_tweets = Array.new()

  def push_tweet
    tweets = params[:tweets]
    tweets.each do |tweet|
      item = Tweet.new
      item.tweet = tweet
      item.save
    end
  end

  def view_analysis
    cate_list = ['名詞','動詞','形容詞']
    @items = AnaTweet.find(:all, :conditions => ["cate in (?)", cate_list], :order=>"count desc")
  end

  def analysis
    tweets = Array.new()
    tangos = Array.new()
    tweets = Tweet.find(:all)

    if tweets != nil then
      tweets.each do |tweet|
        mecab = MeCab::Tagger.new()
        #全部配列に入れる
        anaTweet = mecab.parseToNode(tweet.tweet)
        while anaTweet do
          #初登場時
          if (item = AnaTweet.find_by_word(anaTweet.surface, :first)) == nil then
            item = AnaTweet.new
            item.word = anaTweet.surface.force_encoding("utf-8")
            item.cate = anaTweet.feature.split(",")[0].force_encoding("utf-8")
            item.count = 1
            item.save
          else
            item.count += 1
            item.save
          end
          anaTweet = anaTweet.next
        end
      end
    end

    cate_list = ['名詞','動詞','形容詞']
    @items = AnaTweet.find(:all, :conditions => ["cate in (?)", cate_list], :order=>"count desc")
    @view =  true
  end

  def checkShop(shops)
    checkShops = ["マクドナルド","吉野家","サイゼリヤ","スタバ"]
    shop_flag = true

    #名詞がレストラン辞書にあれば
    if (checkShops & shops).length != 0 then
#    if (shop_flag) and ((checkShops & shops).blank? != true) then
      $checkin_shops << (checkShops & shops)[0].encode('utf-8')
      return true
    else
      return false
    end
  end

  def checkVerb(rowTweet)
    checkVerbs = ["食べ","たべ","買う","行く","食う","買っ","行っ","飲み","飲む"]
    checkVerbs = ["食べ","食う","飲み","飲む"]
    checkNouns = ["ディナー","フレンチ","イタリアン","中華","和食","ラーメン"]
    goto_shop_flag = false
    shops = Array.new()
    while rowTweet do
      #名詞を配列にいれる
      if (rowTweet.feature.force_encoding('utf-8').index("名詞")) then
        shops <<  rowTweet.surface.force_encoding("utf-8")
      end
      #どの単語をキーワードに解析を開始するか決める
      #動詞かつ上のcheckVerbsにあるどうしなら店チェックおこなう
      if ((checkVerbs.index(rowTweet.surface.force_encoding("utf-8"))) and (rowTweet.feature.force_encoding('utf-8').index("動詞"))) or 
          ((checkNouns.index(rowTweet.surface.force_encoding("utf-8"))) and (rowTweet.feature.force_encoding('utf-8').index("名詞"))) then
           goto_shop_flag = true
      end
      rowTweet = rowTweet.next
    end
    if goto_shop_flag == true then
#店判定はせずに常にtrue
#      return checkShop(shops)
      return true
    else
      return false
    end
  end

  def parseTweet(rowTweets)
    reTweets = Array.new()
    rowTweets.each do |tweet|
      mecab = MeCab::Tagger.new()
      #動詞チェック＆店チェックを行い、OKなら配列に格納
      if checkVerb(mecab.parseToNode(tweet.tweet)) then
        $match_tweets << tweet.tweet
        reTweets <<  mecab.parseToNode(tweet.tweet)
      end
    end
    return reTweets
  end

  def parseAllTweet(rowTweets)
=begin
   sentence = "太郎はこの本を二郎を見た女性に渡した。"
    model = MeCab::Model.new(ARGV.join(" "))
    tagger = model.createTagger()
    n = tagger.parseToNode(sentence)
=end
    reTweets = Array.new()
    rowTweets.each do |tweet|
      mecab = MeCab::Tagger.new()
      #全部配列に入れる
      reTweets <<  mecab.parseToNode(tweet.tweet)
    end
    return reTweets
  end

  def twitter
    rowTweets = Array.new()
    rowTweets = params[:tweets]
    @rowTweets = rowTweets
    rowTweets = Tweet.find(:all)

=begin
    rowTweets = rowTweets | ["ホットドッグを食べた","ゲームした","マクドナルドでハンバーガー食べた","パンたべようかなー","マクドナルド買う","マクド買う"]
    rowTweets <<  "やり方分からなければ教えますのでリムらないでください。マクドナルドクルー。よく荒ぶります、多少キチガイ入ってあげてください。"
    rowTweets <<  "友達と一緒に買うとき便利です。マクドナルドを実質500円で注文しちゃおう！"
    rowTweets <<  "昼飯を吉野家で食う"
    rowTweets <<  "スタバでレシートを持っていけば100円でおかわりができる】※ただしドリップコーヒーのみ。ホットでもアイスでも可。他店舗でも可。もちろん当日のレシートのみ有効。先に買ったものと同じサイズ。mymrmyk"
    rowTweets <<  "BBCフットボールのチーフ記者 ‏@philmcnulty ：香川真司に代わってライアン・ギグスが出場。ギグスはレアル・マドリーのファンからも素晴らしい喝采を浴びている。"
=end

    @tweets = parseTweet(rowTweets)
    @allTweets = parseAllTweet(rowTweets)
    @checkin_shops = $checkin_shops
    @match_tweets = $match_tweets
    @view = true
  end

  def all_twitter
    rowTweets = Array.new()
    rowTweets = params[:tweets]
    @rowTweets = rowTweets
    @allTweets = Tweet.find(:all)

#    @tweets = parseTweet(rowTweets)
#    @allTweets = parseAllTweet(rowTweets)
    @checkin_shops = $checkin_shops
    @match_tweets = $match_tweets
    @view = true
  end

  def login

require 'rubygems'
require 'crack'
require 'json'

#client = Foursquare2::Client.new(:client_id => 'Q4LVOVTZECDLOYRZBLIGYBRBG45111D51QL35GQC4US2AAC2', :client_secret => '0KEJYLGC12GPPUMHECOFYJ14VKZRNESIJQXJ0O0HOUGGB21O')
#client = Foursquare2::Client.new(:oauth_token => 'JYVAH0QM31GBZMJ0N0ZBOYWJRN0J23TL0EADHWZTNGQ23F54')
    client = Foursquare2::Client.new(:oauth_token => 'JYVAH0QM31GBZMJ0N0ZBOYWJRN0J23TL0EADHWZTNGQ23F54', :api_version => '20120505')


    @clientA = client.user(48067311)
    @clientB = client.user(48066671)
    @list = client.user_checkins()

    @checkin_count = @list.items.count

    @checkin_names = Array.new
    @value_categories = Array.new
    @rest_flags = Array.new

    i = 0 
    while i < @checkin_count
      @checkin_names[i] = @list.items[i].venue.name 
      venue = client.venue(@list.items[i].venue.id) 
      j = 0 
      while j < venue.categories.count
        if venue.categories[j].name.index("Restaurant") != nil then
          @rest_flags[i] = venue.categories[j].name 
        end
        j += 1 
      end 
      i += 1 
    end 


## CODE => PUIN2XPHGMNMAUTCP5KXEOOH0NP303LHF225HM4JOVAH1TEK
## {"access_token":"JYVAH0QM31GBZMJ0N0ZBOYWJRN0J23TL0EADHWZTNGQ23F54"}

=begin
    foursquare = Foursquare::Base.new("ACCESS_TOKEN")

    foursquare = Foursquare::Base.new("Q4LVOVTZECDLOYRZBLIGYBRBG45111D51QL35GQC4US2AAC2", "0KEJYLGC12GPPUMHECOFYJ14VKZRNESIJQXJ0O0HOUGGB21O")
    foursquare = Foursquare::Base.new("CLIENT_ID", "CLIENT_SECRET")

    foursquare.authorize_url("CALLBACK_SESSION_URL")
    access_token = foursquare.access_token(params["code"], "CALLBACK_SESSION_URL")

    foursquare = Foursquare::Base.new("ACCESS_TOKEN")
=end

  end

end
