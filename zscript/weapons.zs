class NoAutoAimPlease : DoomWeapon replaces DoomWeapon {
    Default{
        +WEAPON.NOAUTOAIM;
    }
}

class DelayedRocket : Rocket replaces Rocket {
    Default{
        DeathSound "";
    }
    States{
        Spawn:
            MISL A 1 Bright;
            Loop;
        Death:
            // MISL A 2 Bright ; // little gap before explode
            MISL B 1 Bright {
                A_Explode();
            }
            MISL B 7 Bright {
                A_StartSound("weapons/rocklx");
            }
            MISL C 6 Bright;
            MISL D 4 Bright;
            Stop;
    }
}

class FasterLauncher : RocketLauncher {
	States {
        Fire:   //immediate fire, in exchange for a longer endlag
            MISG B 16 A_FireMissile;
            MISG B 0 A_ReFire;
            Goto Ready;
    }
}
