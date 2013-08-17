/**
 * Racesow_Player_Race
 *
 * @package Racesow
 * @subpackage Player
 * @version 1.0.3
 */
class Racesow_Player_Race : Racesow_Player_Implemented
{
	/**
	 * Checkpoints of the race
	 * @var uint
	 */
    uint[] checkPoints;

    /**
     * The checkpoints of the race as a string
     */
    String checkPointsString;

	/**
	 * uCmd timestamp when started race
	 * @var uint
	 */
    uint startTime;

	/**
	 * uCmd timestamp when stopped race
	 * @var uint
	 */
    uint stopTime;

	/**
	 * Distance when started race
	 * @var uint64
	 */
    uint64 startDistance;

	/**
	 * Speed when stopped race
	 * @var uint
	 */
    int stopSpeed;

	/**
	 * Distance when stopped race
	 * @var uint64
	 */
    uint64 stopDistance;

	/**
	 * Local time when race has finished
	 * @var uint64
	 */
	uint64 timeStamp;

	/**
	 * Difference to best race
	 * @var int
	 */
	int delta;

	/**
	 * The last passed checkpoint in the race
	 * @var int
	 */
    int lastCheckPoint;

	/* Prejumped race flag
	 * @var bool
	 */
    bool prejumped;

	/**
	 * Constructor
	 *
	 */
    Racesow_Player_Race()
    {
		this.delta = 0;
		this.stopTime = 0;
		this.checkPoints.resize( numCheckpoints );
		this.lastCheckPoint = 0;
		this.startTime = 0;
		this.prejumped = false;

		for ( int i = 0; i < numCheckpoints; i++ )
		{
            this.checkPoints[i] = 0;
		}
    }

	/**
	 * Check if it's is currently being raced
	 * @return bool
	 */
	bool inRace()
	{
		if ( this.startTime != 0 && this.stopTime == 0 )
			return true;
		else
			return false;
	}

	/**
	 * See if the race was finished
	 * @return bool
	 */
	bool isFinished()
	{
		return (this.stopTime != 0);
	}

	/**
	 * Get the race time
	 * @return uint
	 */
	uint getTime()
	{
		return this.stopTime - this.startTime;
	}

	/**
	 * Get the current race distance
	 * @return uint
	 */
	uint getCurrentDistance()
	{
	    if ( this.startDistance > 0 )
            return (this.player.distance - this.startDistance)/1000;
        else
            return 0;
	}

	/**
	 * getCheckPoint
	 * @param uint id
	 * @return uint
	 */
	uint getCheckPoint(uint id)
	{
		if ( id >= this.checkPoints.length() )
            return 0;

		return this.checkPoints[id];
	}

	/**
	 * Get all the checkpoint times as a token string
	 * @return String
	 */
	String getCheckpoints()
	{
        String checkpoints = "";
        for ( int i = 0; i < numCheckpoints; i++ )
        {
            checkpoints +=  this.checkPoints[i] + " ";
        }
        return checkpoints;
	}

	/**
	 * getStartTime
	 * @return uint
	 */
	uint getStartTime()
	{
		return this.startTime;
	}

	/**
	 * getCurrentTime
	 * @return uint
	 */
	uint getCurrentTime()
	{
		return this.player.getClient().uCmdTimeStamp - this.startTime;
	}

	/**
	 * getTimeStamp
	 * @return uint64
	 */
	uint64 getTimeStamp()
	{
		return this.timeStamp;
	}

	/**
	 * Save a checkpoint in the race
	 * @param int id
	 * @return void
	 */
	void check(int id)
	{
		if ( this.checkPoints[id] != 0 ) // already past this checkPoint
            return;

		this.checkPoints[id] = this.player.getClient().uCmdTimeStamp - this.startTime;

		uint newTime = this.checkPoints[id];
		uint serverBestTime = this.player.race.prejumped ? map.getPrejumpHighScore().getCheckPoint(id) : map.getHighScore().getCheckPoint(id);
		uint personalBestTime = this.player.getBestCheckPoint(id);

        this.addCheckpoint( this.lastCheckPoint, serverBestTime == 0 ? 0 : ( newTime - serverBestTime ) );
        this.player.distributeDiffed( id, newTime, personalBestTime, serverBestTime, serverBestTime );

        if ( newTime < serverBestTime || serverBestTime == 0 )
        {
            this.player.sendAward( S_COLOR_GREEN + "#" + ( this.lastCheckPoint + 1 ) + " checkpoint record!" );
        }
        else if ( newTime < personalBestTime || personalBestTime == 0 )
        {
            this.player.sendAward( S_COLOR_YELLOW + "#" + ( this.lastCheckPoint + 1 ) + " checkpoint personal record!" );
        }

        this.checkPointsString += S_COLOR_ORANGE + "#" + ( this.lastCheckPoint + 1 ) + ": "
                + S_COLOR_WHITE + TimeToString( newTime )
                + S_COLOR_ORANGE + " Speed: " + S_COLOR_WHITE + this.player.getSpeed()
                + S_COLOR_ORANGE + " Personal: " + S_COLOR_WHITE + diffString( personalBestTime, newTime )
                + S_COLOR_ORANGE + " Server: " + S_COLOR_WHITE + diffString( serverBestTime, newTime ) + "\n";

	    this.lastCheckPoint++;
	}

	/**
	 * Start the race timer
	 * @return void
	 */
	void start()
	{
		clearCheckpoints();
		this.startTime = this.player.getClient().uCmdTimeStamp;
		this.startDistance = this.player.distance;
        this.checkPointsString += S_COLOR_ORANGE + "Start speed: " + S_COLOR_WHITE + this.player.getSpeed();
        cEntity@ ent = @this.player.getClient().getEnt();
        Vec3 mins, maxs;
        ent.getSize( mins, maxs );
        Vec3 down = ent.origin;
        down.z -= 5000;
        cTrace tr;
        if( tr.doTrace( ent.origin, mins, maxs, down, ent.entNum, MASK_PLAYERSOLID ))
            this.checkPointsString += S_COLOR_ORANGE + " Height: " + S_COLOR_WHITE + int( ent.origin.z - tr.get_endPos().z );
        this.checkPointsString += "\n";
	}

	/**
	 * Stop the race timer and check the result
	 * @return bool
	 */
	bool stop()
	{
        if ( !this.inRace() )
            return false;

        this.stopTime = this.player.getClient().uCmdTimeStamp;
		this.stopDistance = this.player.distance;
		this.stopSpeed = this.player.getSpeed();
		this.timeStamp = localTime;

		return true;
	}

	/**
	 * Get race data as string
	 * @return String
	 */
	String toString()
	{
		String raceString;
		raceString += "\"" + this.getTime() + "\" \"" + this.player.getName() + "\" \"" + localTime + "\" ";
		raceString += "\"" + this.checkPoints.length() + "\" ";
		for ( uint i = 0; i < this.checkPoints.length(); i++ )
			raceString += "\"" + this.getCheckPoint( i ) + "\" ";

		raceString += "\n";

		return raceString;
	}

	/**
	 * Add a Checkpoint for client
	 * @param int id
	 * @param int time difference to best time
	 */
	void addCheckpoint( int id, int time )
	{
		this.player.getClient().execGameCommand( "cpa " + id + " " + time );
	}

	/**
	 * Clear Checkpoints for client
	 */
	void clearCheckpoints()
	{
		this.player.getClient().execGameCommand( "cpc" );
	}
}
