class NoAutoAimPlease : DoomWeapon replaces DoomWeapon {
    Default{
        +WEAPON.NOAUTOAIM;
    }
}

class DelayedRocket : Rocket replaces Rocket {

    States{
        Spawn:
            MISL A 1 Bright;
            Loop;
        Death:
            // MISL A 5 Bright ; // little gap before explode
            MISL B 8 Bright A_Explode;
            MISL C 6 Bright;
            MISL D 4 Bright;
            Stop;
    }
}