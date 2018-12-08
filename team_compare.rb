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
	
	def calculate_factors
		@record_factor = @home.team_info["record_factor"] / (@away.team_info["record_factor"] + @home.team_info["record_factor"])
		shots_for_factor = @home.team_info["shots_for"] / (@away.team_info["shots_for"] + @home.team_info["shots_for"])
		shots_against_factor = @away.team_info["shots_against"] / (@home.team_info["shots_against"] + @away.team_info["shots_against"])
		@shots_factor = (shots_against_factor + shots_for_factor) * 0.5
		ppg_factor = @home.team_info["ppg"] / (@away.team_info["ppg"] + @home.team_info["ppg"])
		ppga_factor = @away.team_info["ppga"] / (@home.team_info["ppga"] + @away.team_info["ppga"])
		@special_teams_factor = (ppg_factor + ppga_factor) * 0.5
		@recent_factor = @home.team_info["recent_factor"] / (@away.team_info["recent_factor"] + @home.team_info["recent_factor"])
		@venue_factor = @home.team_info["home_record_factor"] / (@home.team_info["home_record_factor"] + @away.team_info["away_record_factor"])
	end
	
	def determine_overall_strength_factor
		h2h_multiplier = @h2h_games * 0.05
		record_multiplier = 0.55 - h2h_multiplier #will need to change this to work for playoffs
		return (@record_factor * record_multiplier) + (@shots_factor * 0.10) + (@special_teams_factor * 0.10) + (@recent_factor * 0.10) + (@venue_factor * 0.15) + (@h2h_factor * h2h_multiplier)
	end
	
	def calculate_h2h_factor
		home_games_played = @home.team_info["completed_schedule"]
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

