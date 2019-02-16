require 'net/http'
require 'json'

require_relative 'team_strength.rb'
require_relative 'constants.rb'

###
# A class composed of two team strength objects, used to compare various factors between those objects
# for the purpose of generating odds for games between them
###
class Team_Compare
	###
	# Constructor
	# Argument home: Team_Strength, the home team
	# Argument away: Team_Strength, the away team 
	# Argument season_sim: bool, will this be used in the contet of a season simulation, defualt false
	# Argument home_ff: int, home forward factor, default 1
	# Argument away_ff: int, away forward factor, default 1
	# No Return
	###
	def initialize(home, away, season_sim=false, home_ff=1, away_ff=1)
		@home = home
		@away = away	
		@season_sim = season_sim
		@home_ff = home_ff
		@away_ff = away_ff
	end
	
	###
	# Compare the two given teams
	# No Arguments
	# Return: float, the chance of the home team winning between 0 and 1
	###
	def compare
		calculate_factors
		calculate_h2h_factor
		return determine_overall_strength_factor
	end
	
	###
	# Compare the Team_Strength objects with each other to get the factors
	# No Arguments 
	# No Return
	###
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
		@forward_factor = @home_ff / (@home_ff + @away_ff)
	end
	
	###
	# Combine the factors with the appropriate multipliers to create the odds of a home team win
	# No Arguments
	# Return: float, the chance of the home team winning between 0 and 1
	###
	def determine_overall_strength_factor
		h2h_multiplier = @h2h_games * 0.05
		record_multiplier = 0.55 - h2h_multiplier #will need to change this to work for playoffs
		if @season_sim
			recent_multiplier = 0
			forward_multiplier = 0.10
			venue_multiplier = 0.15
		else
			recent_multiplier = 0.10
			forward_multiplier = 0
			venue_multiplier = 0.15
		end
			
		return (@record_factor * record_multiplier) + (@shots_factor * 0.10) + (@special_teams_factor * 0.10) + (@recent_factor * recent_multiplier) + (@venue_factor * venue_multiplier) + (@h2h_factor * h2h_multiplier) + (@forward_factor * forward_multiplier)
	end
	
	###
	# Compare the games the home and away team have played against each other to get the head 2 head factor
	# No Arguements
	# No Return
	###
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

