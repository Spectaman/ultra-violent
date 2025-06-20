//this is to simulate parrying without defining a weapon
class ParryController : CustomInventory {

	//to clarify:
	//TRACER is the hitbox

	const PARRYLAYER = -100;//underneath weapons
	// double oldBob;//for toggling the viewbob
	
	

	//pointer to the fabled hitbox
	ParryHitBox myParryHitbox;

	Default{
		//cannot be taken from player by "dropping it".
		+INVENTORY.UNDROPPABLE
        +INVENTORY.UNTOSSABLE
        +INVENTORY.PERSISTENTPOWER
	}
	
	States{
		Use: 
			TNT1 A 0
			{
				let psp = player.FindPSprite(PARRYLAYER);
				
				//are we doing a punch already?
				if (!psp) { 
					A_Overlay(PARRYLAYER, "DoParry");
				}
		
			}
		fail;//it must fail so game doesnt take away the ParryController
		
		DoParry:
			TNT1 A 0 {
				A_OverlayOffset(OverlayID(), -20, WEAPONTOP);
				// setParryType('ATTACK_NOTHING');//assume nothing
				// if (self && InStateSequence(self.curstate, ResolveState("Pain"))){//cannot parry during pain state
				// 	console.printf("im taking damage!");
				// }
			}

			PUNG C 1 {
				let Guy = UltraGuy(player.mo);
				if(Guy){
					invoker.myParryHitbox = ParryHitbox( Guy.doParry(invoker) );   //for some unholy reason, "self" does not refer to the instance of the class.
					invoker.myParryHitbox.controllerPSprite = player.FindPSprite( OverlayID() );
					// console.printf("%s",invoker.myParryHitbox.getclassname());
				}
			}
			PUNG C 1;
			PUNG D 4;
		LamePunch:
			PUNG D 3 A_Punch;
		ArmRetract:	
			PUNG D 3 {
				// if(invoker.oldBob != 0){
				// 	CVAR bobCVAR = CVar.GetCVar('movebob');
				// 	bobCVAR.SetFloat(invoker.oldBob);
				// }
				
			}
			PUNG C 4 ;
			PUNG B 10;
			stop;
		ParrySuccess:
			PUNG D 1 bright {
				//temporarly turn off viewbob (TURN IT BACK ON LATER)
				// double bobCVAR = GetCVar('movebob');
				// invoker.oldBob = bobCVAR.GetFloat();
				// bobCVAR.SetFloat(0.0);
			}
			PUNG D 13 Offset(44, 32); // wow great parry dude
			PUNG D 1  Offset(2, 32); // ok put the offset back now 
			goto ArmRetract;
	//end of States
	}

	//end of ParryController
}


class ParryHitbox : Actor { // heavily based on elSebas54's work: https://forum.zdoom.org/viewtopic.php?t=80050
	//to clarify:
	// tracer will be the controller.
	// Target is the player
	//
	
	PSprite controllerPSprite; //I can change states this way

	Default{
		Radius 18;
		Height 32;
		Projectilekickback 800;// i want to use this for knockback but idk if i will
		species "player"; //please do not parry yourself
		PainChance 256;

		//imporant flag stuff
		+SHOOTABLE		//Enemies can hit it.
		+NOBLOOD		//if it could bleed that would be weird
		+NOGRAVITY		//if it could fall  that would be weird
		+NOCLIP
		+NOTIMEFREEZE 
		+NEVERTARGET		//target is the player, so i can't let it switch
		+NOTARGETSWITCH

		+NOTIMEFREEZE 
		+THRUSPECIES
	}
	
	States {
		Spawn: 
			TNT1 A 0 NoDelay {
				let Guy = UltraGuy(self.target);
				if(Guy){
					Guy.canParryMelee = true;
				}
			} 
			//uncomment only one of these lines. 
			//BBRN is for me to debug stuff
			//TNT1 is for normal people who dont want to see romero up in their face
			BBRN AAAA 1;
			// TNT1 AAAA 1; 
			//this is your parrywindow. It is 4 ticks, or less than 1/7 of a second
		Pain:
			TNT1 A 0 {
				let Guy = UltraGuy(self.target);
				if(Guy){
					Guy.canParryMelee = false;
				}
			}
			stop;
	}
	
	override void Tick(){
		Super.Tick();
		let john = UltraGuy(target);
		// direction vector from: https://forum.zdoom.org/viewtopic.php?t=62666
		Vector3 direction;
		direction.xy = Actor.AngleToVector(john.Angle);
		direction.z = sin(-john.Pitch);
		SetOrigin(john.pos + direction*john.PARRY_DIST, true);
		self.vel = john.vel; //match player vel
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
		//todo: cant parry dead projectiles.
		if (InStateSequence(inflictor.curState, inflictor.ResolveState("XDeath")) ||  InStateSequence(inflictor.curState, inflictor.ResolveState("Death"))){
			return 0;
		}

		//player's parry attack should phase through it. 
		//no need to put it back to true
		//you are going to die anyways
		bSHOOTABLE = false;
		inflictor.bSOLID =false;

		// viewbob toggle is in the Controller ParrySuccess State
		
		//audio cue
		S_StartSound("dsskepch",CHAN_BODY);
		//visual cue
		self.target.GiveInventory("PFlash",1);
		//give player health for parrying
		if(self.target.player.health < 100){
			self.target.player.health = min(self.target.player.health + 20, 100);
		}

		//todo: parry back the inflictor
		// let controller = ParryController(tracer);

		if( inflictor.bMISSILE && inflictor!=source){ //projectile attack
			// console.printf("this is a projectile");//tells me that i hit a projectile

			//fire back!
			inflictor.bMISSILE = false;//please don't explode immediately
			inflictor.SetStateLabel("Spawn"); //the projectile is dying! bring my boy back
			

			//ParryProjectile is heavily based on elSabas54's work again.

			ParryProjectile PProj = ParryProjectile( Spawn("ParryProjectile",inflictor.pos) ); //the new projectile that drags the parried projectile
			if(PProj){

				if(Inflictor is "FastProjectile") //fast projectiles go to their death state after this call so here i just spawn a copy
				{
						PProj.PrProjectile = spawn(inflictor.getclass(),inflictor.pos);
						PProj.PrProjectile.bMissile = false;
						Inflictor.Destroy();
						Inflictor = PProj.PrProjectile;
				}
				else {
					PProj.PrProjectile = inflictor;
				}

				double sped = inflictor.speed+30;
				PProj.pDamg = damage * 5;

				//this is my projectile now loser
				inflictor.Target = self.target; //I'm the owner now
				inflictor.Tracer = source; 		//homing missiles go back to their original shooter

				
				//again, pretty much 1-to-1 with elSabas54's ParryKick 
				PProj.Target = Target; PProj.Tracer = source; PProj.Master = self; 
				PProj.A_SetSize(inflictor.Radius,inflictor.Height);//same hitbox
				PProj.Angle = Target.angle; PProj.Pitch = Target.Pitch; 
				PProj.vel = ( sped*Cos(self.target.angle)*cos(self.target.pitch) , sped*sin(self.target.angle)*cos(self.target.pitch) , -sped*sin(self.target.pitch) );
				PProj.bMISSILE = true;
				PProj.bSEEKERMISSILE = inflictor.bSEEKERMISSILE;
				//im adding this extra thing
				PProj.DeathSound = PProj.PrProjectile.DeathSound;

				inflictor.SetStateLabel("Spawn"); //the projectile is dying! bring my boy back

			}

		}
		

		if(controllerPSprite) controllerPSprite.SetState(controllerPSprite.Caller.FindState("ParrySuccess") ); //tell the controller it's parry time

		// console.printf("eeyowch!");
		// console.printf("%s", mod);

		return 0; 
		//end of DamageMobj
	}


	//end of ParryHitBox
}


//by elSebas54. 
Class ParryProjectile : Actor //the projectile actor that drags the parried projectile and deals desired damage
{ 
	Actor PrProjectile, HitActor;
	Int pDamg;//the damage to deal
	Property pDamg: pDamg;
	Default {
		RenderStyle "Add";
		Radius 4;
		Height 2;
		Speed 50;
		BounceFactor 1;
		WallBounceFactor 1;
		Projectile;
		ParryProjectile.pDamg 30;
		DamageFunction (pDamg);
		ProjectileKickback 200;
		+SKYEXPLODE
		+SCREENSEEKER
		-MISSILE
		+ACTIVATEIMPACT;
		+ACTIVATEPCROSS;
	} 
	  
	States
	{
	  Spawn:
		TNT1 A 1 NoDelay
		{
			if(PrProjectile) //keep projectile in the right direction
			{
				PrProjectile.SetOrigin( Pos , true);
				PrProjectile.Vel = Vel;
				PrProjectile.Angle = Angle;
				PrProjectile.Pitch = Pitch;
				if(bSEEKERMISSILE) {A_SeekerMissile(0,9,SMF_LOOK|SMF_PRECISE|SMF_CURSPEED,256);}
				PrProjectile.SetStateLabel("Spawn");
			}
			else {Destroy();}
		}
		loop;
	  Death:
		TNT1 A 2 {
			If(PrProjectile)
			{
				PrProjectile.SetOrigin( Pos , true);
				PrProjectile.Vel = (0,0,0); 
				PrProjectile.SetStateLabel("Death");
				// ExplodeMissile();
			}
		}
		stop;
	  XDeath: 
		TNT1 A 2 {
			If(PrProjectile)
			{
				//give pointers if nedded and explode the original projectile too
				if(PrProjectile.bHITTRACER) PrProjectile.tracer = HitActor;
				if(PrProjectile.bHITTARGET) PrProjectile.target = HitActor;
				if(PrProjectile.bHITMASTER) PrProjectile.master = HitActor;
				PrProjectile.SetOrigin( Pos , true);
				PrProjectile.Vel = (0,0,0);
				If(PrProjectile.FindState("XDeath") ) {PrProjectile.SetStateLabel("XDeath");}
				else {PrProjectile.SetStateLabel("Death");}
			}
		}
		stop;
  }
	//is called to check it a projectile should collide with an actor,
	//return -1 is just default collition, 0 explodes without dealing damage and 1 passes through
	override int SpecialMissileHit(Actor victim)
	{
		// pass thou if its the player, parrybox, the projectile if its also shootable..
		if (Victim == Master || Victim == Target || Victim == PrProjectile || Victim.bCORPSE || Victim.health <=0) Return MHIT_PASS;
		
		If ( bRIPPER && !Victim.bDONTRIP && !Victim.bREFLECTIVE && Victim.bSHOOTABLE )
		{
			Return 1;
		}
		else {Return -1;}

		return MHIT_DEFAULT;
	}
	//end of ParryProjectile
}


class PFlash : Powerup { //flash the screen during a parry. Also freezes the game for   i m p a c t
	Default{
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.NOSCREENBLINK
		Powerup.Color "FF FF FF" ; //Whitescreen screen effect
		Powerup.Duration 11;
	}

	override void InitEffect() //
	{
		Super.InitEffect();		
		//stop the music
		S_PauseSound(false, false);

		//freeze the game 
		level.SetFrozen(true);

		//grant iframes
		if(owner){
			owner.GiveInventory('PIFrame',1);
		}

	}

	override void DoEffect(){ //this runs on every tick but InitEffect wasn't working soooooo
		Super.DoEffect();
		// //freeze the game 
		// level.SetFrozen(true);
		// //stop the music, but not the sound
		S_PauseSound(false, true);
		// // ACS_NamedExecute ("SetMusicVolume", 0, 0.0); 

		if (owner && owner.health <= 0) {
			Destroy();
		}

	}

	override void EndEffect()
	{
		Super.EndEffect();

		Level.SetFrozen(false);

		S_ResumeSound(false);
		// ACS_NamedExecute ("SetMusicVolume", 0, 1.0); 
		let john = UltraGuy(owner);
	}


	//end of PFlash
}
class PIFrame : PowerInvulnerable{	//iframes for the parry. needs to be independant so it lasts a little bit longer
	Default{
		Powerup.Duration 9;
		Powerup.Mode 'None';
	}
}


class DashCharge : Inventory {    //uses these to
    Default{
        Inventory.MaxAmount 300;    //you use 100 per dash but it would make cool charguing ui thuing
        //important flag stuff
        +INVENTORY.UNTOSSABLE;
        +INVENTORY.NOSCREENFLASH;
    }

    override bool Use(bool pickup){
        if(owner && owner.CountInv("DashCharge") > 100){
            owner.TakeInventory("DashCharge", 100);

			let Guy = UltraGuy(owner);

            // //thrust the player based on their inputs
			int forwardback = 0;
			int leftright = 0;

            int playerButtons = owner.GetPlayerInput(MODINPUT_BUTTONS);
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
				//it's zero if you are pressing both
            }

			//create angle offset using good ol trig
			Guy.dashAngle = Guy.angle + atan2(leftright,forwardback);
			Guy.GiveInventory("DashPower",1);
			console.printf("%d", Guy.dashAngle);
        }

        
        return false;   //I don't want this to use itself.
    }

    //end of DashCharge
}

class DashPower : Powerup {

	Default{
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.NOSCREENBLINK
		Powerup.Duration 4;//5 ticks
	}

	override void InitEffect() //
	{
		Super.InitEffect();
		//stop moving in the beginning		
		let john = UltraGuy(owner);
		john.A_Stop();
	}

	override void DoEffect(){ //this runs on every tick but InitEffect wasn't working soooooo
		Super.DoEffect();
		let john = UltraGuy(owner);

		//make bro floatier

		if(owner){
			if(!owner.player.onGround){
				owner.gravity = 0.0;
			}
			if (owner.health <= 0 ) {
				Destroy();
			}
			if(john && john.canWallJump){
				Destroy();
			}
		}
		

		//send player dashing yeah
		john.vel.xy = AngleToVector(john.dashAngle, john.DASH_SPEED);

		//check if player if moving away from the dash angle

	}

	override void EndEffect()
	{
		Super.EndEffect();

		//undo the Init effects
		if(owner){
			owner.gravity = 1.0;
			let john = UltraGuy(owner);
			john.vel /= 100;
		}

	}


	//end of DashPower
}

class StompCharge: Inventory { //more stompinvs = more stomp jump height
	Default{
		Inventory.MaxAmount 300; 
		//important flag stuff that i shamelessly stole from myself a few lines above
		+INVENTORY.UNTOSSABLE;
		+INVENTORY.NOSCREENFLASH;
	}

	


	//end of StompInv
}

class StompPower : Powerup {	// you are in the air!
	Default{
		Inventory.MaxAmount 1; 
		//important flag stuff that i shamelessly stole from myself a few lines above
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.NOSCREENBLINK
		Powerup.Duration  0x7FFFFFFF; //two years LOLOLOLOL
	}

	override void InitEffect() {
    	super.InitEffect();
		if(owner){
			let john = UltraGuy(owner);
			john.vel.xy = (0,0);
			john.vel.z = john.STOMP_SPEED;

			john.isStomping = true;
		}
	}

	override void DoEffect() {
		Super.DoEffect();
		if(owner){
			if(owner.player.onGround){
				Destroy();
			}
			else{	//count stomp ticks
				//keep looping until player hits ground or dies
				let john = UltraGuy(owner);
				john.GiveInventory('StompCharge', 1);
			}
		}
	}
	
	override void EndEffect()
	{
		Super.EndEffect();

		//undo the Init effects
		if(owner){
			let john = UltraGuy(owner);
			john.isStomping = false;
		}

	}

}

class SlidePower : Powerup {
	vector2 oldForwardMove;
	vector2 oldSideMove;
	vector2 slidingFM;
	vector2 slidingSM;

	Default{
		Inventory.MaxAmount 1; 
		//important flag stuff that i shamelessly stole from myself a few lines above
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.NOSCREENBLINK
		Powerup.Duration  0x7FFFFFFF; //two years LOL
	}

	// override void AttachToOwner(Actor other) {
    // 	super.AttachToOwner(other);
	// 	if(owner){
	// 		self.slidingFM = (0.3, 0.3);
	// 		self..slidingFM = (0, 0);

	// 		let john = UltraGuy(owner);
	// 		self.oldForwardMove = john.player.ForwardMove;
	// 		self.oldSideMove = john.player.SideMove;
			
	// 		john.player.SideMove = self.slidingSM;
	// 		john.player.ForwardMove = self.slidingFM;
	// 	}
	// }
}

class SlamPower : Powerup {	//does the ground slam. if player jumps during this, they will jump higher.
	Default{
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.NOSCREENBLINK
		Powerup.Duration 4;
	}
	override void InitEffect() //
	{
		Super.InitEffect();
		
		//create AOE that sends enemies upwards
	}
	override void DoEffect(){
		Super.DoEffect();

		//check for jumping input
	}
	override void EndEffect(){
		Super.EndEffect();

		//if there was a jump input then send player up based on stompTicks

	}

}
