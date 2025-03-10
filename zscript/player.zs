
class ultraGuy: DoomPlayer {
	
	
	//parrying stuff
	const PARRY_DIST = 500;
	
	Default{
		Player.StartItem "Pistol";
		Player.StartItem "ParryController"; //parry/punch functionality
	}
	
	bool doParry(Actor ControllerThePlatypus){
// 		console.printf("hello, I am parrying");
		
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
		vector3 whereToParry = WhoIParried.HitDir;

		//let this guy to the whole parrying shabam
		bool didParrySpawn;
		Actor ParryThePlatypus;
		[didParrySpawn, ParryThePlatypus] = A_SpawnItemEx("ParryHitbox",whereToParry.x, whereToParry.y, whereToParry.z, angle: self.angle, flags:SXF_SETMASTER);
		ParryThePlatypus.tracer = ControllerThePlatypus;
		// console.printf("%d",didParrySpawn);
		return didParrySpawn;
	}
	
	
	
	override void Tick(){
		Super.Tick();
		
// 		console.printf("look ma im being executed!");
	}

}