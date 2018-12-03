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
		last_x = 10
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
		
		return wins.to_f / last_x.to_f
	end
	
	attr_reader :team_id
	attr_reader :team_info
end
