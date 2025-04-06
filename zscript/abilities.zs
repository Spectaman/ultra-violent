//test weapon to understand Overlays
//copy-pasted from https://jekyllgrim.github.io/ZScript_Basics/12_Weapons_Overlays_PSprite.html#overview
// class PistolAngled : Pistol
// {
//     States
//     {
//     Ready:
//         PGUN A 1 A_WeaponReady;
//         loop;
//     Fire:
//         PGUN A 2
//         {
//             A_FireBullets(5.6, 0, 1, 5);
//             A_StartSound("weapons/pistol", CHAN_WEAPON);
//             A_Overlay(-2, "Flash");
//             A_Overlay(2, "Highlights");
//         }
//         PGUN BD 1;
//         PGUN CBA 2;
//         PGUN A 5 A_ReFire;
//         goto Ready;
//     Flash:
//         PGUF Z 2 bright A_Light1;
//         TNT1 A 0 A_Light0;
//         stop;
//     Highlights:
//         PGUF A 2 bright;
//         stop;
//     Select:
//         PGUN A 1 A_Raise;
//         loop;
//     Deselect:
//         PGUN A 1 A_Lower;
//         loop;
//     }
// }


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

			PUNG B 1 {
				let Guy = UltraGuy(player.mo);
				if(Guy){
					invoker.myParryHitbox = ParryHitbox( Guy.doParry(invoker) );   //for some unholy reason, "self" does not refer to the instance of the class.
					invoker.myParryHitbox.controllerPSprite = player.FindPSprite( OverlayID() );
					// console.printf("%s",invoker.myParryHitbox.getclassname());
				}
			}
			PUNG B 2;
			// {
			// 	int greg = self.player.mo.CountInv('PFlash');//i kinda forgot how to make a good name but its used to much i cant change it :P
			// 	//go here if nothing happened
			// 	A_JumpIf(greg > 0, "WaitForParryVisual");
			// 	// console.printf("%d",greg);
			// }
		ParryFail:
			PUNG C 3;
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
			PUNG D 13 Offset(42, 35); // wow great parry dude
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
		Radius 17;
		Height 32;
		Projectilekickback 800;// i want to use this for knockback but idk if i will
		species "player"; //please do not parry yourself
		PainChance 256;

		//imporant flag stuff
		+SHOOTABLE		//Enemies can hit it.
		+NOBLOOD		//if it could bleed that would be weird
		+NOGRAVITY		//if it could fall  that would be weird
		+noclip
		+NOTIMEFREEZE 
		+NEVERTARGET		//target is the player, so i can't let it switch
		+NOTARGETSWITCH

		+NOTIMEFREEZE 
		+thruspecies
	}
	
	States {
		Spawn: 
			TNT1 A 1 NoDelay {
				let Guy = UltraGuy(self.target);
				if(Guy){
					Guy.canParryMelee = true;
				}
			} 
			TNT1 AAAAA 1; //this is your parrywindow. It is 5 ticks, or 1/7 of a second
		Pain:
			TNT1 A 1 NoDelay {
				let Guy = UltraGuy(self.target);
				if(Guy){
					Guy.canParryMelee = false;
				}
			}
			stop;
	}
	
	override void Tick(){
		Super.Tick();

		self.vel = target.vel; //match player vel
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
		//player's parry attack should phase through it. 
		//no need to put it back to true
		//you are going to die anyways
		bSHOOTABLE = false;
		inflictor.bSOLID =false;

		// viewbob toggle is in the Controller ParrySuccess State
		
		//audio cue
		S_StartSound("dspunch",CHAN_BODY);
		//visual cue
		self.target.GiveInventory("PFlash",1);
		//give player health for parrying
		self.target.player.health = min(self.target.player.health + 25, 100);


		// "Good. I'm giving you a bonus."
		// if(self.target.player.health < 100){//no overheal thats a little too busted tbh
		// 	self.target.player.health += 20;
		// 	if(self.target.player.health > 100){
		// 		self.target.player.health = 100;
		// 	}
		// }

		//todo: parry back the inflictor
		// let controller = ParryController(tracer);

		if( inflictor.bMISSILE && inflictor!=source ){ //projectile attack
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
					PProj.PrProjectile = Inflictor;
				}

				double sped = inflictor.speed+30;
				PProj.pDamg = damage * 5;

				//this is my projectile now loser
				inflictor.Target = self.target; //I'm the owner now
				inflictor.Tracer = source; 		//homing missiles go back to their original shooter

				
				//again, pretty much 1-to-1 with elSabas54's ParryKick thingy that I linked in the class declaration
				PProj.Target = Target; PProj.Tracer = source; PProj.Master = self; 
				PProj.A_SetSize(Inflictor.Radius,Inflictor.Height);//same hitbox
				PProj.Angle = Target.angle; PProj.Pitch = Target.Pitch; 
				PProj.vel = ( sped*Cos(self.target.angle)*cos(self.target.pitch) , sped*sin(self.target.angle)*cos(self.target.pitch) , -sped*sin(self.target.pitch) );
				PProj.bMISSILE = true;
				PProj.bSEEKERMISSILE = inflictor.bSEEKERMISSILE;
				//im adding this extra thing
				PProj.DeathSound = PProj.PrProjectile.DeathSound;
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


class PFlash : PowerInvulnerable { //flash the screen during a parry. Also freezes the game for   i m p a c t
	Default{
		+INVENTORY.AUTOACTIVATE
		+INVENTORY.NOSCREENBLINK
		Powerup.Color "FF FF FF" ; //Whitescreen screen effect
		Powerup.Duration 12;//12 ticks
		
	}

	// override void InitEffect() //
	// {
	// 	Super.InitEffect();		
	// 	//stop the music
	// 	S_PauseSound(false, false);

	// 	//freeze the game 
	// 	level.SetFrozen(true);

	// }

	override void DoEffect(){ //this runs on every tick but InitEffect wasn't working soooooo
		Super.DoEffect();
		//freeze the game 
		level.SetFrozen(true);
		//stop the music, but not the sound
		S_PauseSound(false, true);

		if (owner && owner.health <= 0) {
			Destroy();
		}

	}

	override void EndEffect()
	{
		Super.EndEffect();

		Level.SetFrozen(false);

		S_ResumeSound(false);
	}



}




