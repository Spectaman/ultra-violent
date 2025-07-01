class UltraGuy: DoomPlayer {
	//parrying stuff
	const PARRY_DIST = 10;
	bool canParryMelee;
	const PARRY_PUNCH_KNOCKBACK = 1;
	
	//dash stuff
	const DASH_SPEED = 50;	//how fast the dash is.
	// const DASH_LENGTH = 25;	//how many ticks to dash for.
	// bool isDashing;
	int dashAngle;
	
	//wall jump stuff
	const MAX_WALLJUMP_COUNT = 3; //how many walljumps can you do before touching the ground
	const WALL_SEARCH_DIST = 15;
	const WJUMP_FORCE = 18;
	bool canWallJump;
	int jumpAngle;
	vector2 jumpVector;
	int currentWallJumpCount;

	//stomp 'n slide stuff
	const STOMP_SPEED = -35;	//negative vertical velocity
	const SLIDE_SPEED = 10;	//todo: figure out better numbers for this
	const SLIDE_DECEL_RATE = 1;
	bool isStomping;
	int slidingAngle;
	// uint stompTicks;


	Default{
		// Player.StartItem "Pistol";
		Player.StartItem "ParryController"; //parry/punch functionality
		Player.JumpZ 11; //higher jump than 8
		SelfDamageFactor 0.5;	// i like doing dangerous things
	}
	
	Actor doParry(Actor ControllerThePlatypus){
		// console.printf("hello, I am parrying");
		
		// FLineTraceData WhoIParried;
		//this is player camera z. Trust me bro
		double pz = player.viewz - pos.z;
		
		// direction vector from: https://forum.zdoom.org/viewtopic.php?t=62666
		Vector3 direction;
		direction.xy = Actor.AngleToVector(self.Angle);
		direction.z = sin(-self.Pitch);

		vector3 whereToParry = direction*PARRY_DIST;

		//let this guy to the whole parrying shabam
		bool didParrySpawn;
		Actor P;
		[didParrySpawn, P] = A_SpawnItemEx("ParryHitbox",whereToParry.x, whereToParry.y, whereToParry.z, angle: self.angle, flags:SXF_SETTARGET | SXF_SETMASTER);
		let ParryThePlatypus = ParryHitbox(P);
		// ParryThePlatypus.hitDirection =  WhoIParried.HitDir;

		// ParryThePlatypus.Target = self;
		//now i can access them in between
		// ParryThePlatypus.tracer = ControllerThePlatypus;
		ControllerThePlatypus.tracer = ParryThePlatypus;

		// console.printf("%d",didParrySpawn);
		return ParryThePlatypus;
	}
	
	override void PostBeginPlay(){
		super.PostBeginPlay();
		//walljump setup
		currentWallJumpCount = 0;
		//dash setup
		self.GiveInventory("DashCharge",300);
		//stomp/slide setup
		isStomping = false;
		// stompTicks = 0;
	}
	
	override void Tick(){
		Super.Tick();
		
		self.GiveInventory("DashCharge",1);

		//stop trying to do anything until the dash is over.
		if(isDashing()){
			return;
		}

		// //allow air control only when the player is pressing buttons THAT MOVE THE PLAYER
		if(  GetPlayerInput(MODINPUT_BUTTONS) & (BT_FORWARD | BT_BACK | BT_MOVELEFT | BT_MOVERIGHT )  ) {
			if(!isStomping){
				ACS_NamedExecute("AirOn");
			}
		}
		else{
			ACS_NamedExecute("AirOff");
		}

		doWallJump();	//do a wall jump (if the conditions for it arise)
		doStompSlide();		//do a stomp/slide if you can and want to.

	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
		if(canParryMelee && source == inflictor) { //melee attack parry?			//audio cue
			S_StartSound("dspunch",CHAN_BODY);
			//visual cue
			GiveInventory("PFlash",1);
			
			//todo: attack enemy
			if(source){
				// direction vector based on: https://forum.zdoom.org/viewtopic.php?t=62666
				Vector3 direction;
				direction.xy = Actor.AngleToVector(self.Angle);
				direction.z = 0;

				source.vel += (direction*PARRY_PUNCH_KNOCKBACK);
				source.DamageMobj(self, self, damage*5, mod, flags, angle);
			}

			return 0;
		}
		else {
			return super.DamageMobj(inflictor, source, damage, mod, flags, angle);
		}
	}

	bool, vector2 CheckWallJump()
	{
		// if(!self.onGround){	//dont bother if player is on the ground
		// 	return false;
		// }

		//wall-finding algorithm inspired by Ivory Duke's ZMovement mod
		FLineTraceData wallData;
		bool didIhitAWall;
		vector2 johnVector;

		for(int i = 0; i < 360; i++){
			didIhitAWall = LineTrace(i, self.radius + WALL_SEARCH_DIST, 0, flags: TRF_THRUACTORS | TRF_BLOCKSELF , data: wallData);

			if(didIhitAWall && wallData.HitType == TRACE_HitWall){	//if linetrace ended before the wallsearch limit
				// double wallAngle = VectorAngle(wallData.HitLine.Delta.x, wallData.HitLine.Delta.y);
				// jumpAngle = Angle - VectorAngle(cmd.forwardmove, cmd.sidemove);

				//get angle based on the Line's delta vector
				// double johnAngle = VectorAngle (wallData.HitLine.delta.x, wallData.HitLine.delta.y);

				//get vector from v1 to player
				johnVector = self.pos.xy - wallData.HitLine.v1.p;
				//find how much of vector is along Line delta
				vector2 alongVector = project2(johnVector, wallData.HitLine.delta);
				//get the orthogonal projection. This is the vector from the line directly to the player
				johnVector = johnVector - alongVector;

				break;
			}
		}

		if(didIhitAWall){
			return true, johnVector.Unit();
		}

		return false, (0,0);
	}

	void doWallJump(){ //it is assumed you can wall jump here.
		//pressed the jump button.
		bool justJumped = GetPlayerInput(MODINPUT_BUTTONS) & BT_JUMP && !(GetPlayerInput(MODINPUT_OLDBUTTONS) & BT_JUMP);

		[canWallJump, jumpVector] = CheckWallJump();
		if(canWallJump && justJumped && !self.player.onGround && currentWallJumpCount < 3){
			//console.printf("john walljump");
			//fire player in that vector
			self.vel = WJUMP_FORCE * (jumpVector.x, jumpVector.y, 0.75);
			//increment walljump counter
			currentWallJumpCount += 1;
			
		}

		if(self.player.onGround){
			currentWallJumpCount = 0;
		}

	}

	bool isDashing(){
		return CountInv("DashPower")>0;
	}

	//for projecting a vector3 u onto another vector v
	vector3 project3(vector3 u, vector3 v){
		//this comes up more often than you think
		if(v.LengthSquared() == 0){
			return (0,0,0);
		}
	
		return (u dot v)/(v.LengthSquared())*(v);
	}
	//version for vector2
	vector2 project2(vector2 u, vector2 v){
		if(v.lengthSquared() == 0){
			(0,0,0);
		}
		return (u dot v)/(v.LengthSquared())*(v);
	}

	void doStompSlide() {
		slidingAngle = updateSlidingAngle(GetPlayerInput(MODINPUT_BUTTONS));

		bool wasntCrouchingBefore = !(GetPlayerInput(MODINPUT_OLDBUTTONS) & BT_CROUCH);
		bool isCrouching = GetPlayerInput(MODINPUT_BUTTONS) & BT_CROUCH;
		bool justCrouched = isCrouching && wasntCrouchingBefore;
		

		if(self.player.onGround) {
			//start sliding bucko
			if(justCrouched) {
				//visual thing and audio i think?
				self.GiveInventory('SlidePower', 1);

			}
		}
		else {
			if (justCrouched && !isStomping) {
				//start stomping bucko
				self.GiveInventory('StompPower', 1);
			}
		}	

	}

	int updateSlidingAngle(int playerButtons){	
		// //slide the player based on their inputs
		int forwardback = 0;
		int leftright = 0;

		// int playerButtons = owner.GetPlayerInput(MODINPUT_BUTTONS);
		if(playerButtons & (BT_FORWARD | BT_BACK | BT_MOVELEFT | BT_MOVERIGHT )){
			if (playerButtons & BT_BACK){	//backwards takes precedence
				forwardback -= 1;
			}
			else if(playerButtons & BT_FORWARD){
				forwardback += 1;
			}

			//do the same for left and right'
			if(playerButtons & BT_MOVELEFT){
				leftright += 1;
			}
			if (playerButtons & BT_MOVERIGHT){
				leftright -= 1;
			}
			// and it's zero if you are pressing both
		}

		//create angle offset using good ol trig
		return self.angle + atan2(leftright,forwardback);
	}

	// helper function thats mostly just for non-player actors
	bool amITryingToJump(){
		return (GetPlayerInput(MODINPUT_BUTTONS) & BT_JUMP);
	}

	int justGiveMeTheButtonsDammit(){
		return GetPlayerInput(MODINPUT_BUTTONS);
	}
	//end of ultraGuy
}