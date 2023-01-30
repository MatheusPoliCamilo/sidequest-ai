require 'json'

class SearchController < ApplicationController
  def index
    response = OpenaiClient.new.call(movie: params[:search])
    games_names = response["choices"].map do |choice|
      choice["text"].split("\n")
    end.flatten.compact_blank.map do |text|
      text.gsub(/^\d+.|\)/, '').strip
    end
    recommended_games_steam_ids = games_names.map {|recommended_game| game_basic_infos(recommended_game)}

    @recommended_games = recommended_games_steam_ids.map do |game_id|
      next if game_id.nil?

      game = SteamClient.new(game_id).game_info
      next if game.nil? || game['success'] == false
      game
    end.compact
  end

  def game_basic_infos(recommended_game)
    file = File.open("games.json")
    all_games = JSON.load(file)

    steam_game = all_games['applist']['apps'].find {|game| game["name"].strip == recommended_game}

    steam_game['appid'] if steam_game.present?
  end
end
