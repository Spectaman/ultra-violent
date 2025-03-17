
class ultraGuy: DoomPlayer {
	
	
	//parrying stuff
	const PARRY_DIST = 10;
	
	Default{
		// Player.StartItem "Pistol";
		Player.StartItem "ParryController"; //parry/punch functionality
	}
	
	Actor doParry(Actor ControllerThePlatypus){
		// console.printf("hello, I am parrying");
		
		FLineTraceData WhoIParried;
		//this is player camera z. Trust me bro
		double pz = player.viewz - pos.z;
		bool didIParrySomething = LineTrace(
				angle,
				PARRY_DIST,
				pitch,
				offsetz: pz,
				data: WhoIParried
			);
		vector3 whereToParry = WhoIParried.HitDir*PARRY_DIST;

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
		
// 		console.printf("look ma im being executed!");
	}

}