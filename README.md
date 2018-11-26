# NHL Odds
A program which calculates odds for NHL games, and possibly playoff odds in the future
## Algorithm
### Four Factors
- Overall Record
- Head to Head Record
- Shots for and against
- Special teams
- Multiplying these four together gives chance home team will win as a decimal from 0 - 1
#### Overall Record
- (Points % Home) / (Points % Away + Points % Home)
#### H2H
- (Win % for Home in games against opponent)
- If they haven't played use .5
#### Shots 
- (SF_Home / (SF_Away + SF_Home) * .5) + (SA_Away / (SA_Away + SA_Home) * .5)
#### Special Teams
- ((PPG_Home / (PPG_Away + PPG_Home)) * .5) + (PPGA_Away / (PPGA_Home + PPGA_Away) * .5)

## Behavior
- Specified by command line flags
### Flags
- 'g' generate: generate odds for todays games store results in a file
- 's' <int> simulate: simulate some number of runs through the rest of the season, specified by the passed integer. Return playoff odds
- 'a' archive: move old generated odds files to an archive to speed up checking
- 'c' check: check generated odds against actual results and report accuracy

## Future Improvements
- Weigh stats to count recent games for more
- Get team stats once instead of once per function that needs it
- Find a way to eliminate repetition in special teams and shooting functions(add team strength class)
- Find a way to run the job daily from windows
- Make a system for weighing the factors differently
- Add multithreading
- Add overall home/away strength as a factor
- Add last X days as factor
- Add the usage function
- After changing the factor system to use dynamic weights make weight of h2h factor depend on number of games played against each other

## Versions
- 1.0.0: Basic system generate a file for the results of a daily odds generation and can check the results of past generated odds
