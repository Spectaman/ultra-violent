// class PunchableImpBall: DoomImpBall replaces DoomImpBall {

// 	Default{
// 		-NOBLOCKMAP;
// // 		+SHOOTABLE;
// 	}
// }

// class PunchableCacoBall: CacodemonBall replaces CacodemonBall {
// 	Default{
// 		-NOBLOCKMAP;
// // 		+SHOOTABLE;
// 	}
// }

class DelayedRocket : Rocket replaces Rocket {

    States{

        Death:
            MISL B 1 Bright ;
            MISL B 7 Bright A_Explode;
            MISL C 6 Bright;
            MISL D 4 Bright;
            Stop;
    }
}