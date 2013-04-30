# -*- coding: utf-8 -*-
class CreateAnaTweets < ActiveRecord::Migration
  def change
    create_table :ana_tweets do |t|

      t.string :word, :limit=>100              #タイトル
      t.string :cate, :limit=>100          #詳細


      t.integer :count               #予備のフラグエリア

      t.timestamps
    end
  end
end
