require 'net/http'
require 'json'
require 'date'

###
# A class used to show how past bets on games would've gone
# Just does puckline for now, could be expanded later
###
class Puckline

    @@pl_rate = 1.5
    def initialize(years)
        @years_checked = years
    end

    ###
    # Checks the past @@years_checked of games between the teams matched up today
    # and print how often each would win a puckline bet as the underdog and favourite
    # No Arguments
    # No Return
    ###
    def daily_puckline_history
        today = Time.now.strftime("%Y-%m-%d")
        n_years_ago = (Date.today - (@years_checked * 365)).strftime("%Y-%m-%d")

        response = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?date=#{today}")
        json_response = JSON.parse(response)
        
        if json_response["dates"].length == 0
            puts "No games today ... exiting"
            return
        end

        games = json_response["dates"][0]["games"]
        games.each do |game|
            home_id = game["teams"]["home"]["team"]["id"]
            away_id = game["teams"]["away"]["team"]["id"]
            game_history = Net::HTTP.get(NHL_STATS_API_HOST, "/api/v1/schedule?teamId=#{home_id}&startDate=#{n_years_ago}&endDate=#{today}")
            schedule = JSON.parse(game_history)
            favourite_wins = 0;
            underdog_wins = 0;
            total_games = 0

            schedule["dates"].each do |day|
                old_game = day["games"][0]
                if old_game["gameType"] == "R" # i.e. its a regular season game
                    diff = nil
                    if old_game["teams"]["away"]["team"]["id"] == away_id
                        diff = old_game["teams"]["home"]["score"] - old_game["teams"]["away"]["score"]
                    elsif old_game["teams"]["home"]["team"]["id"] == away_id
                        diff = old_game["teams"]["away"]["score"] - old_game["teams"]["home"]["score"]
                    end
                    if diff != nil
                        favourite_wins += 1 if diff > @@pl_rate
                        underdog_wins += 1 if (diff * -1) < @@pl_rate
                        total_games += 1
                    end
                end
            end
            puts "In the last #{total_games} regular season games since #{n_years_ago} #{game["teams"]["home"]["team"]["name"]} would've won:
            #{favourite_wins} puckline bets as the favourite, #{underdog_wins} puckline bets as the underdog in a total of 
            #{total_games} games against #{game["teams"]["away"]["team"]["name"]}, who would win #{total_games - favourite_wins} as the underdog and #{total_games - underdog_wins} as the favourite.\n\n"
        end
    end
end