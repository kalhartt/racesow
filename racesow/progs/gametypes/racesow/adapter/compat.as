/**
 * Just leave out methos which are not required and
 * basically copy others from basewsw race
 */
class Racesow_Adapter_Compat : Racesow_Adapter_Abstract
{
    /**
	 * Event: player finishes a race
     * 
     * @param ...
	 * @return void
	 */
    void raceFinish(Racesow_Player_Race @race)
    {
        race.getPlayer().raceCallback(0,0,0,
                race.getPlayer().bestRaceTime,
                race.prejumped ? map.getPrejumpHighScore().getTime() : map.getHighScore().getTime(),
                race.getTime());
    }
}
