require 'net/http'
require 'json'

require_relative 'team_strength.rb'
require_relative 'constants.rb'

class Team_Compare
	def initialize(home, away)
		@home = home
		@away = away	
	end
	
	def compare
		calculate_factors
		calculate_h2h_factor
		return determine_overall_strength_factor
	end
	
	def get_completed_schedule(id)
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?teamId=#{id}&startDate=#{SEASON_START_DATE}&endDate=#{(Time.now - 86400).strftime("%Y-%m-%d")}")
		json_response = JSON.parse(response)
		return json_response["dates"]
	end
	
	def calculate_factors
		@record_factor = @home.record_factor / (@away.record_factor + @home.record_factor)
		shots_for_factor = @home.shots_for / (@away.shots_for + @home.shots_for)
		shots_against_factor = @away.shots_against / (@home.shots_against + @away.shots_against)
		@shots_factor = (shots_against_factor + shots_for_factor) * 0.5
		ppg_factor = @home.ppg / (@away.ppg + @home.ppg)
		ppga_factor = @away.ppga / (@home.ppga + @away.ppga)
		@special_teams_factor = (ppg_factor + ppga_factor) * 0.5
	end
	
	def determine_overall_strength_factor
		h2h_multiplier = @h2h_games * 0.05
		record_multiplier = 0.7 - h2h_multiplier
		return (@record_factor * record_multiplier) + (@shots_factor * 0.15) + (@special_teams_factor * 0.15) + (@h2h_factor * h2h_multiplier)
	end
	
	def calculate_h2h_factor
		home_games_played = get_completed_schedule(@home.team_id)
		wins = 0
		games = 0
		home_games_played.each do |game|
			if game["games"][0]["teams"]["away"]["team"]["id"] == @away.team_id
				if game["games"][0]["teams"]["away"]["score"] < game["games"][0]["teams"]["home"]["score"]
					wins += 1
				end
				games += 1
			elsif game["games"][0]["teams"]["home"]["team"]["id"] == @away.team_id
				if game["games"][0]["teams"]["away"]["score"] > game["games"][0]["teams"]["home"]["score"]
					wins += 1
				end
				games += 1
			end
		end
		if games == 0
			@h2h_games = 0
			@h2h_factor = 0.5 #wont need this once h2h factor is dynaically weighed
		else
			@h2h_games = games
			@h2h_factor = wins.to_f / games.to_f
		end
	end
end

