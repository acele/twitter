# -*- coding: utf-8 -*-
Twitter::Application.routes.draw do

  match 'anatweet' => 'anatweet#login'
  match 'twitter' => 'anatweet#twitter'
  match 'all_twitter' => 'anatweet#all_twitter'
  match 'getweet/get' => 'getweet#get'
  match 'getweet' => 'getweet#index'
  match 'analysis' => 'anatweet#analysis'
  match 'view/analysis' => 'anatweet#view_analysis'
  match 'getweet/serch' => 'getweet#search'
  match 'push/tweet' => 'anatweet#push_tweet'

  match 'test' => 'anatweet#test'
end
