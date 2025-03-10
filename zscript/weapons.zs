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
	const PARRYLAYER = -100;//underneath weapons
	
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
			TNT1 A 0 A_OverlayOffset(OverlayID(), -20, WEAPONTOP);
			PUNG B 1 {
				let Guy = UltraGuy(player.mo);
				if(Guy){
					Guy.doParry(invoker);//for some unholy reason, "self" does not refer to the instance of the class.
				}
			}
			PUNG B 3 ;
			PUNG C 4 ;
		ArmRetract:	
			PUNG D 5 {
				A_FireShotgun();
			}
			PUNG C 4 ;
			PUNG B 5;
			stop;
		ParryBullet:
			PUNG D 1 {
				console.printf("this is a bullet");
			}
			stop;
		ParryProjectile:
			PUNG D 1 {
				console.printf("this is a projectile");
			}
			stop;
		ParryMelee:
			PUNG D 1 {
				console.printf("this is a fist");
			}
			stop;
	//end of States
	}

	
	//end of ParryController
}


class ParryHitbox : Actor { // heavily based on elSebas54's ParryBox from: https://forum.zdoom.org/viewtopic.php?t=80050
	//to clarify:
	// Target is the actor that fired at it
	// Master is the actor that spawned it. This will always be the player (PLEASE BE THE CASE SO I DONT LOOK DUMB)
	
	const PARRY_DMG_MULT = 1.5;
	
	Default{
		Radius 32;
		Height 32;
		Projectilekickback 800;
		species "player"; //please do not parry yourself
		//imporant flag stuff
		+SHOOTABLE		//Projectiles can hit it.
		+NOBLOOD		//if it could bleed that would be weird
		+NOGRAVITY		//if it could fall  would be weird
	}
	
	States {
		Spawn:
			TNT1 AAAAAAAA 1;//this is your parrywindow. It is 8 As, or 8 ticks, or a little over 1/4 of a second
			Stop;
		Pain:
			TNT1 A 1;//do the parry thing aaccoring to DamageMobj
			Stop;
	}

	override void Tick(){
		Super.Tick();
		// console.printf("I Exist!");
		// if(tracer){
		// 	console.printf("%s",tracer.getclassname());
		// }
	}
	
	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle) {
		
		//todo: parry back the inflictor
		
		if( inflictor.bMISSILE && inflictor!=source){ //missile attack
			//fire back
			
		}
		else if ( source != target && mod == "Melee"){ //melee attack
			//punch back?
			
		}
		else if ( inflictor!=source && (mod=="Hitscan")           && false){ //hitscan attack. not working rn
			//shoot back at them!
			Inflictor.bMISSILE = False;
			bSHOOTABLE = False;//not you, them!
			
			// FLineTraceData john;//i cant think of a name for this one im ngl
			// bool didIShootSomeone = Target.LineTrace(Target.angle, 9000, Target.pitch, TRF_ABSPOSITION, Inflictor.Pos.z, Inflictor.Pos.x, Inflictor.Pos.y, john);
				
			// if(didIShootSomeone){

			// 	if(john.HitType == TRACE_HitActor && john.HitActor.bSHOOTABLE){


			// 	}
			// 	//john.HitActor.vel += john.HditDir );// throw inflictor thataway!
			// 	// john.HitActor.DamageMobj(Inflictor,Target,damage*1000,mod,DMG_INFLICTOR_IS_PUFF|DMG_THRUSTLESS,master.angle);
				
				
			// }
			//A_CustomBulletAttack(2,2,1,20);
			// A_FireBullets(0, 0, 1, 45, "RiflePuff", FBF_USEAMMO|FBF_NORANDOM);
			tracer.A_FireShotgun();
			bSHOOTABLE = True;
		}
		
		console.printf("eeyowch!");
		return 0;
	} 
}