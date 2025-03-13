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
	
	//this information comes from the hitbox
	// enum allDamageTypes {
	// 	// DamageType Identifiers
	// 	ATTACK_NOTHING = 0,
	// 	ATTACK_MELEE   = 999,
	// 	ATTACK_PROJ    = 9999, //easy to remember!
	// 	ATTACK_HITSCAN = 99999,
		
	// };

	Name incomingDamageType;

	//pointer to the fabled hitbox
	// Actor myParryHitbox;

	// pointers set from the  hitbox DamageMobj so I can access them from the the Pain State
	Actor ptr_Inflictor;
	Actor ptr_Source;
	int ptr_damage;
	Name ptr_mod;

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
			}

			PUNG B 1;
			PUNG C 1;

			PUNG D 1 {
				let Guy = UltraGuy(player.mo);
				if(Guy){
					Guy.doParry(invoker);//for some unholy reason, "self" does not refer to the instance of the class.
					// console.printf("%s",invoker.myParryHitbox.getclassname());
				}
			}
		// WaitForParryResponse:
		// 	PUNG D 1{
		// 		//after one tick, the tracer should exist now
		// 		A_JumpIf(invoker.myParryHitbox != null, "ArmRetract");
		// 		console.printf("he's in the goddamn walls");
		// 	}
		// 	loop;
		ArmRetract:	
			PUNG D 2 {
				// A_FireShotgun();
			}
			PUNG C 2 ;
			PUNG B 2;
			stop;

		//different behaviour based on what you are parrying
		// ParryBullet:
		// 	PUNG D 4 {
		// 		console.printf("this is a bullet");
		// 		A_FireShotgun;
		// 	}
		// 	goto ArmRetract;
		// ParryProjectile:
		// 	PUNG D 1 {
		// 		console.printf("this is a projectile");
		// 	}
		// 	goto ArmRetract;
		// ParryMelee:
		// 	PUNG D 1 {
		// 		console.printf("this is a fist");
		// 		A_FireShotgun2;
		// 	}
		// 	goto ArmRetract;
	//end of States
	}

	void setParryType(Name name){
		incomingDamageType = name;
	}
	Name getParryType(){
		return incomingDamageType;
	}

	//end of ParryController
}


class ParryHitbox : Actor { // heavily based on elSebas54's ParryBox from: https://forum.zdoom.org/viewtopic.php?t=80050
	//to clarify:
	// tracer will be the controller.
	// Target is the player
	//
	
	const PARRY_DMG_MULT = 1.5;
	
	vector3 hitDirection;


	Default{
		Radius 16;
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
			TNT1 AAAA 1 NoDelay; //this is your parrywindow. It is 4 A's, or 4 ticks, or a little over 1/8 of a second
		Pain:
			stop;
	}
	
	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
		//player's parry attack should phase through it. 
		//no need to put it back to true
		//you are going to die
		bSHOOTABLE = false;
		inflictor.bSOLID =false;


		//todo: parry back the inflictor
		// let controller = ParryController(tracer);

		if( inflictor.bMISSILE && inflictor!=source ){ //projectile attack
			console.printf("this is a projectile");//tells me that i hit a projectile

			//fire back!
			inflictor.bMISSILE = false;//please don't explode immediately
			inflictor.SetStateLabel("Spawn"); //the projectile is dying! bring my boy back
			

			//ParryProjectile is heavily based on elSabas54's work again

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
				//
			}
			

			// inflictor.angle = self.target.angle;//player angle and pitch (facing direction)
			// inflictor.pitch = self.target.pitch;
			// // inflictor.vel = getReflectedVel(inflictor);
			
			//inflictor.vel = ( sped*Cos(self.target.angle)*cos(self.target.pitch) , sped*sin(self.target.angle)*cos(self.target.pitch) , -sped*sin(self.target.pitch) );
		
			//ok now you can explode
			// inflictor.bMISSILE = true;
		}
		else if ( mod=='Hitscan' ){ //hitscan attack
			//shoot back at them!
			// controller.setParryType('ATTACK_HITSCAN');
		}
		else if ( source == target ){ //melee attack
			//punch them i guess
			// controller.setParryType('ATTACK_MELEE');
		}
		
		console.printf("eeyowch!");
		// console.printf("%s", mod);
		return 0;
		//end of DamageMobj
	}
	
	vector3 getReflectedVel(Actor ThingImGonnaParry){
		vector3 oldVel = ThingImGonnaParry.vel;
		vector2 horizontalVel = AngleToVector(  self.target.angle,oldVel.Length()  ); //built in functions my beloved.
		double verticalVel = sin(pitch);
		return (  horizontalVel.x,  horizontalVel.y,  verticalVel);
	}
	//end of ParryHitBox
}


//by elSebas54
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
			if(PrProjectile)
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
	
}


class PFlash : PowerTimeFreezer { //flash the screen during a parry. Also freezes the game for   i m p a c t
	Default{
		+INVENTORY.AUTOACTIVATE
		Powerup.Color "InverseMap"; //InvulnerabilitySphere screen effect
		Powerup.Duration 4;//4 ticks
		
	}
	States{
		HEAD A 1;//cacodemon sprite
		loop;
	}
}