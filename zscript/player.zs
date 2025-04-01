
class ultraGuy: DoomPlayer {
	
	
	//parrying stuff
	const PARRY_DIST = 10;
	bool canParryMelee;
	const PARRY_PUNCH_KNOCKBACK = 1;
	
	//dash stuff
	const DASH_SPEED = 200;	
	
	//wall jump stuff
	const MAX_WALLJUMP_COUNT = 3; //how many walljumps can you do before touching the ground
	const WALL_SEARCH_DIST = 32;
	const WJUMP_FORCE = 65;
	bool canWallJump;
	int jumpAngle;
	int currentWallJumpCount;

	Default{
		// Player.StartItem "Pistol";
		Player.StartItem "ParryController"; //parry/punch functionality
	}
	
	Actor doParry(Actor ControllerThePlatypus){
		// console.printf("hello, I am parrying");
		
		// FLineTraceData WhoIParried;
		//this is player camera z. Trust me bro
		double pz = player.viewz - pos.z;
		
		// direction vector based on: https://forum.zdoom.org/viewtopic.php?t=62666
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
	
	
	override void Tick(){
		Super.Tick();
		// Usercmd cmd = self.cmd;	//pass player inputs to functions

		// canWallJump = CheckWallJump();

		// console.printf("look ma im being executed!");
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




	void doDash(){

		
	}

	bool CheckWallJump()
	{
		// if(!self.onGround){	//dont bother if player is on the ground
		// 	return false;
		// }

		//wall-finding algorithm from Ivory Duke's ZMovement mod
		FLineTraceData wallData;

		for(int i = 0; i < 8; i++){
			LineTrace(i*45, WALL_SEARCH_DIST, 0, 0, data: wallData);

			if(wallData.distance < WALL_SEARCH_DIST && wallData.HitType == TRACE_HitWall){	//if linetrace ended before the wallsearch limit
				// double wallAngle = VectorAngle(wallData.HitLine.Delta.x, wallData.HitLine.Delta.y);
				// jumpAngle = Angle - VectorAngle(cmd.forwardmove, cmd.sidemove);
				return true;
			}
		}

		return false;
	}


	void doWallJump(){ //it is assumed you can wall jump here.

		// todo: jump opposite from wall
		Vector3 direction;
		direction.xy = WJUMP_FORCE * Actor.AngleToVector(self.jumpAngle+180);
		direction.z = (JumpZ + 50);
		

	}

	vector2 vec2ToLine(Line theLine){	//returns the shortest vector from the wall to the player
		//get player position
		
		//get v1 (haha like ultrakill)
		Vertex vertex1 = theLine.v1;

		//find vector from v1 to player
		vector2 vToPlayer = self.pos.xy - vertex1.p;

		//project that vector onto theLine delta
		//find how much of that vector is delta
		vector2 vec3AlongLine = vec2_project(vToPlayer, theLine.delta);

		//find the orthogonal projection of vToPlayer
		vector2 orthproj = vToPlayer - vec3AlongLine;

		return (0,0);
	}

	//for projecting a vector u onto another vector v
	vector2 vec2_project(vector2 u, vector2 v){
		//this comes up more often than you think
		if(v.LengthSquared() == 0){
			return (0,0);
		}
	
		return (u dot v)/(v.LengthSquared())*(v);
	}

	//end of ultraGuy
}