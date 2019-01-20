require 'net/http'
require 'json'

require_relative 'team_strength.rb'
require_relative 'constants.rb'
require_relative 'team_compare.rb'

class Season
	def initialize
		@remaining_schedule = get_remaining_schedule
		@standings = get_standings
	end
	
	def test
		sc = @standings
		add_points(20, sc)
		puts sc
	end
	
	def get_standings
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/standings")
		json_response = JSON.parse(response)
		div_standings = Hash.new
		@strengths = Hash.new
		json_response["records"].each do |division|
			div_standings[division["division"]["name"]] = Hash.new
			division["teamRecords"].each do |team|
				div_standings[division["division"]["name"]][team["team"]["id"]] = team["points"]
				@strengths[team["team"]["id"]] = Team_Strength.new(team["team"]["id"])
			end
		end
		return div_standings
	end
	
	def get_remaining_schedule
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?startDate=#{Time.now.strftime("%Y-%m-%d")}&endDate=#{SEASON_END_DATE}")
		json_response = JSON.parse(response)
		return json_response["dates"]
	end
	
	def add_points(win_id, standings)
		standings.each do |div|
			if div[1].key?(win_id)
				div[1][win_id] += 2
			end
		end
	end

	def simulate_season(n)
		#multi-thread one per specified iteration
		randomizer = Random.new
		standings_copy = @standings # to prevent multi access issues
		@remaining_schedule.each do |day|
			next if day["date"] == ASG_DATE
			day["games"].each do |game|
				#puts "home id: #{game["teams"]["home"]["team"]["id"]} | away id: #{game["teams"]["home"]["team"]["id"]}"
				result = Team_Compare.new(@strengths[game["teams"]["home"]["team"]["id"]], @strengths[game["teams"]["away"]["team"]["id"]])
				odds = result.compare
				game_result = randomizer.rand
				if odds > game_result
					add_points(game["teams"]["home"]["team"]["id"], standings_copy)
				else
					add_points(game["teams"]["away"]["team"]["id"], standings_copy)
				end
			end
		end
		puts standings_copy
		#determine whose in the playoffs
	end
end


#test driver

s = Season.new
#s.test
s.simulate_season(5)
puts "done"