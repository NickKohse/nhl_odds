# NHL Odds
A program which calculates odds for NHL games, and possibly playoff odds in the future
## Algorithm
### Six Factors
- Overall Record
- Head to Head Record
- Shots for and against
- Special teams
- Venue
- Recent
- Multiplying these six together gives chance home team will win as a decimal from 0 - 1
#### Overall Record
- (Wins % Home) / (Wins % Away + Wins % Home)
#### H2H
- (Win % for Home in games against opponent)
- If they haven't played use .5
#### Shots 
- (SF_Home / (SF_Away + SF_Home) * .5) + (SA_Away / (SA_Away + SA_Home) * .5)
#### Special Teams
- ((PPG_Home / (PPG_Away + PPG_Home)) * .5) + (PPGA_Away / (PPGA_Home + PPGA_Away) * .5)
#### Venue
- Home Home Win % / (Home Home Win % + Away Away Win %)
#### Recent
- Home recent win % / (Away recent win % + Home recent win %)

## Behavior
- Specified by command line flags
### Flags
- 'g' generate: generate odds for todays games store results in a file
- 's' <int> simulate: simulate some number of runs through the rest of the season, specified by the passed integer. Return playoff odds [Planned]
- 'a' archive: move old generated odds files to an archive to speed up checking [Planned]
- 'c' check: check generated odds against actual results and report accuracy

## Future Improvements
- Make a system for weighing the factors differently(a function to do this would be good)
- Add the option of archiving/deleteing old results files
- Run a preformance benchmark and try to imporve on it by any means possible
- Add playoff simulation, showing who is predicted to win each round


## Versions
- 1.0.0: Basic system generate a file for the results of a daily odds generation and can check the results of past generated odds
- 1.1.0: Fix a number of bugs, add more factors to odds weighing, reduce calls to NHL stats API

## Branches
- master: Working project that can simulate games on a given day
- season_sim: Will be able to simulate the odds of teamss making the playoffs, work in progress
