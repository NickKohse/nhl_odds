# Instructions for changing puckline class

## Issue
The class currently shows who would've won puckline bets over the last n years of h2h matchups. The issue with that is teams change alot over the years, and especially for inter conference games the smaple size is small. So changes need to be made.

## Changes
- Make the class applicable to different typese of bets, puckline, moneyline, over/under goals, possibly more. 
- Stop relying on any data from past seasons, focus on current state of team.
- Accept a flag so that either todays mtachup info is shown or tommorows

### Show the following for each matchup
- h2h record wrt both teams
    - show scores of past games
- Last 10 for both teams
- Games played in the last four days, and whether or not its a back to back
- Show how mny losses out of total were 1 goal for both teams 

## Final result mockup
```
Edmonton Oilers @ Calgary Flames
Head to Head:
Edmonton Oilers: 1-2-1
Calgary: 3-1-0
    jan-1-2020  Calgary Flames 3 : Edmonton Oilers 2 (OT)
    jan-3-2020  Calgary Flames 2 : Edmonton Oilers 3
    mar-5-2020  Calgary Flames 7 : Edmonton Oilers 1
    mar-15-2020 Edmonton Oilers 0: Calgary Flames 10

Last 10:
Edmonton Oilers: 4-5-1
Calgary Flames: 9-1-0

Games in last 4 days (including today):
Edmonton Oilers: 3
Calgary Flames: 2

Back to back:
Edmonton Oilers: Yes
Calgary Flames: No

One goal losses:
Edmonton Oilers: 4 of 63
Calgary Flames: 3 of 7
```
