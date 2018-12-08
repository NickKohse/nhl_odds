require 'net/http'
require 'json'

require_relative 'constants.rb'

class Team_Strength
	def initialize(id)
		#store the values in a hash, or just extract the already existing hash to reduce the number of attr_readers
		@team_info = Hash.new
		@team_id = id 
		stats = get_team_stats

		@team_info["record_factor"] = stats["wins"].to_f / stats["gamesPlayed"].to_f

		@team_info["ppg"] = stats["powerPlayGoals"].to_f
		@team_info["ppga"] = stats["powerPlayGoalsAgainst"].to_f

		@team_info["shots_for"] = stats["shotsPerGame"].to_f #these to_f's might be unnecessary 
		@team_info["shots_against"] = stats["shotsAllowed"].to_f
		@team_info["completed_schedule"] = get_completed_schedule
		@team_info["recent_factor"] = get_recent_factor
		get_venue_factors
	end
	
	def get_team_stats
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/teams/#{@team_id}?expand=team.stats")
		json_response = JSON.parse(response)
		return json_response["teams"][0]["teamStats"][0]["splits"][0]["stat"]
	end
	
	def get_completed_schedule
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?teamId=#{@team_id}&startDate=#{SEASON_START_DATE}&endDate=#{(Time.now - 86400).strftime("%Y-%m-%d")}")
		json_response = JSON.parse(response)
		return json_response["dates"]
	end
	
	def get_recent_factor
		last_x = 7
		index = @team_info["completed_schedule"].length - 1
		count = 0
		wins = 0
		
		while count < last_x
			if @team_info["completed_schedule"][index]["games"][0]["teams"]["away"]["team"]["id"] == @team_id
				wins += 1 if @team_info["completed_schedule"][index]["games"][0]["teams"]["away"]["score"] > @team_info["completed_schedule"][index]["games"][0]["teams"]["home"]["score"]	
			elsif @team_info["completed_schedule"][index]["games"][0]["teams"]["home"]["team"]["id"] == @team_id
				wins += 1 if @team_info["completed_schedule"][index]["games"][0]["teams"]["away"]["score"] < @team_info["completed_schedule"][index]["games"][0]["teams"]["home"]["score"]
			end
			count += 1
			index -= 1
		end
		
		return wins.to_f / last_x
	end
	
	def get_venue_factors
		home_w = 0
		home_g = 0
		away_w = 0
		away_g = 0
		@team_info["completed_schedule"].each do |game|
			if game["games"][0]["teams"]["away"]["team"]["id"] == @team_id
				away_w += 1 if game["games"][0]["teams"]["away"]["score"] > game["games"][0]["teams"]["home"]["score"]
				away_g += 1
			else
				home_w +=1 if game["games"][0]["teams"]["away"]["score"] < game["games"][0]["teams"]["home"]["score"]
				home_g += 1
			end
		end
		@team_info["away_record_factor"] = away_w.to_f / away_g
		@team_info["home_record_factor"] = home_w.to_f / home_g
	end
	
	attr_reader :team_id
	attr_reader :team_info
end
