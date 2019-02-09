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
		@names = Hash.new
		json_response["records"].each do |division|
			div_standings[division["division"]["name"]] = Hash.new
			division["teamRecords"].each do |team|
				div_standings[division["division"]["name"]][team["team"]["id"]] = team["points"]
				@strengths[team["team"]["id"]] = Team_Strength.new(team["team"]["id"])
				@names[team["team"]["id"]] = team["team"]["name"]
			end
		end
		return div_standings
	end
	
	def get_remaining_schedule
		response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?startDate=#{Time.now.strftime("%Y-%m-%d")}&endDate=#{SEASON_END_DATE}")
		json_response = JSON.parse(response)
		return json_response["dates"]
	end

	def gen_forward_factors
		forward_factors = Hash.new
		@strengths.each do |id, v|
			forward_factors[id] = Random.rand(1..10)
		end
		return forward_factors
	end
	
	def add_points(id, standings, points)
		standings.each do |div|
			if div[1].key?(id)
				div[1][id] += points
			end
		end
	end

	def tie_breaker(div)
		i = 0
		while i < 4 #only go this far becuase teams out of top five dont matter
			if div[i][1] == div[i + 1][1]
				result = Team_Compare.new(@strengths[div[i][0]], @strengths[div[i + 1][0]])
				odds = result.compare
				if odds < 0.5 #we switch the teams, as the team lower in the standings won the tie breaker, else do nothing
					tmp_id = div[i][0]
					div[i][0] = div[i + 1][0]
					div[i + 1][0] = tmp_id
				end
			end
			i += 1
		end
		return div
	end
	
	def determine_playoff_spots(div1, div2)
		playoff_teams = Array.new
		sorted1 = tie_breaker(div1.sort_by { |k,v| -v })
		sorted2 = tie_breaker(div2.sort_by { |k,v| -v })

		if sorted1[0][1] > sorted2[0][1]
			top_conf = sorted1[0][0]
			top_conf_points = sorted1[0][1]
		else
			top_conf = sorted2[0][0]
			top_conf_points = sorted2[0][1]
		end
			
		for i in 0..2
			playoff_teams.push(sorted1[i][0])
			playoff_teams.push(sorted2[i][0])
		end

		#spots 3 and four in arrays are potential wildcard candidates, will need special cases if the are equal
		#admittedly somewhat confusing

		if sorted1[3][1] > sorted2[3][1]
			playoff_teams.push(sorted1[3][0])
			if sorted1[4][1] > sorted2[3][1]
				playoff_teams.push(sorted1[4][0])
			else
				playoff_teams.push(sorted2[3][0])
			end
		else
			playoff_teams.push(sorted2[3][0])
			if sorted2[4][1] > sorted1[3][1]
				playoff_teams.push(sorted2[4][0])
			else
				playoff_teams.push(sorted1[3][0])
			end
		end

		return {:teams => playoff_teams, :top_id => top_conf , :top_points => top_conf_points}
	end

	def ot_point(id)
		randomizer = Random.new
		ot_point = randomizer.rand
		return true if ot_point < @strengths[id].team_info["otl_rate"]
		return false
	end
	
	def simulate_season
		forward_factors = gen_forward_factors
		randomizer = Random.new
		standings_copy = @standings # to prevent multi access issues
		@remaining_schedule.each do |day|
			next if day["date"] == ASG_DATE
			day["games"].each do |game|
				#puts "home id: #{game["teams"]["home"]["team"]["id"]} | away id: #{game["teams"]["home"]["team"]["id"]}"
				result = Team_Compare.new(@strengths[game["teams"]["home"]["team"]["id"]], @strengths[game["teams"]["away"]["team"]["id"]], true,
					forward_factors[game["teams"]["home"]["team"]["id"]], forward_factors[game["teams"]["away"]["team"]["id"]])
				odds = result.compare
				game_result = randomizer.rand
				if odds > game_result
					add_points(game["teams"]["home"]["team"]["id"], standings_copy, 2)
					add_points(game["teams"]["away"]["team"]["id"], standings_copy, 1) if ot_point(game["teams"]["away"]["team"]["id"])
				else
					add_points(game["teams"]["away"]["team"]["id"], standings_copy, 2)
					add_points(game["teams"]["home"]["team"]["id"], standings_copy, 1) if ot_point(game["teams"]["home"]["team"]["id"])
				end
			end
		end
		east_playoff_info = determine_playoff_spots(standings_copy["Metropolitan"], standings_copy["Atlantic"])
		west_playoff_info = determine_playoff_spots(standings_copy["Central"], standings_copy["Pacific"])
		west_playoff_info[:top_points] > east_playoff_info[:top_points] ? pres_id = west_playoff_info[:top_id] : pres_id = east_playoff_info[:top_id]

		return {:west => west_playoff_info[:teams], :east => east_playoff_info[:teams], :pres => pres_id}
	end

	def simulate_season_controller(n)
		threads = Array.new(n)
		i = 0
		while i < n
			threads[i] = Thread.new{simulate_season}
			i += 1
		end
		east_playoffs = Hash.new
		west_playoffs = Hash.new
		pres_trophy = Hash.new
		threads.each do |t|
			playoff_teams = t.value

			if pres_trophy.key?(playoff_teams[:pres]) #write a function to do this hash incrementing
				pres_trophy[playoff_teams[:pres]] += 1
			else
				pres_trophy[playoff_teams[:pres]] = 1
			end

			playoff_teams[:east].each do |id|
				if east_playoffs.key?(id)
					east_playoffs[id] += 1
				else
					east_playoffs[id] = 1
				end
			end
			#repetition
			playoff_teams[:west].each do |id|
				if west_playoffs.key?(id)
					west_playoffs[id] += 1
				else
					west_playoffs[id] = 1
				end
			end
		end
		
		sorted_east = east_playoffs.sort_by { |k,v| -v }
		sorted_west = west_playoffs.sort_by { |k,v| -v }
		sorted_pres = pres_trophy.sort_by { |k,v| -v }

		puts "\nEastern Conference playoff odds:"
		sorted_east.each do |i|
			puts "#{@names[i[0]]} #{((i[1].to_f / n) * 100).round(2)}%"
		end
		puts "\nWestern Conference playoffs odds:"
		sorted_west.each do |i|
			puts "#{@names[i[0]]} #{((i[1].to_f / n) * 100).round(2)}%"
		end
		puts "\nPresidents Trophy odds:"
		sorted_pres.each do |i|
			puts "#{@names[i[0]]} #{((i[1].to_f / n) * 100).round(2)}%"
		end
	end
end
