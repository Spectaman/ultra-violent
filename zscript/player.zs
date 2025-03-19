
class ultraGuy: DoomPlayer {
	
	
	//parrying stuff
	const PARRY_DIST = 10;
	bool canParryMelee;
	const PARRY_PUNCH_KNOCKBACK = 1;
	
	//dash stuff
	const DASH_SPEED = 200;	
	
	//wall jump stuff
	const MAX_WALLJUMP_COUNT = 3; //how many walljumps can you do in air
	bool canWallJump;
	int jumpAnglel;
	int currentWallJumpCount;

	Default{
		// Player.StartItem "Pistol";
		Player.StartItem "ParryController"; //parry/punch functionality
	}
	
	Actor doParry(Actor ControllerThePlatypus){
		// console.printf("hello, I am parrying");
		
		FLineTraceData WhoIParried;
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
		[didParrySpawn, P] = A_SpawnItemEx("ParryHitbox",whereToParry.x, whereToParry.y, whereToParry.z + pz, angle: self.angle, flags:SXF_SETTARGET | SXF_SETMASTER);
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
		
// 		console.printf("look ma im being executed!");
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
		if(canParryMelee && source == inflictor) { //melee attack parry?
			//audio cue
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

	void CheckWallJump()
	{
		bool isTouchingWall = false;
		for (int x = 0; x <= 360; x += 90) {
			isTouchingWall = CheckLOF(CLOFF_JUMP_ON_MISS | CLOFF_SKIPENEMY | CLOFF_SKIPFRIEND | CLOFF_SKIPOBJECT | CLOFF_MUSTBESOLID | CLOFF_ALLOWNULL | CLOFF_NOAIM_VERT, 32, 0, x);
			if (isTouchingWall) {
				jumpAnglel = x;
				canWallJump = false;
				break;
			}
		}
		if (!isTouchingWall) {
			canWallJump = false;
		}
	}

	void doWallJump(){
		if(canWallJump){
			// todo: jump opposite from wall
			
		}
	}

}