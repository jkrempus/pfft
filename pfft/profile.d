module pfft.profile;


template ProfileMixin(E)
{
    version(Profile)
    {
        import std.stdio, std.traits;
        import core.time;

        version(X86_64)
        {
            // TODO: use actuall frequency
            float seconds(ulong ticks){ return  ticks / 3.7e9; }

            ulong time()
            {
                ulong a, d;
                version(GNU)
                    asm { "rdtsc" : "=a" a, "=d" d; }
                else
                    asm
                    {
                        rdtsc;
                        mov a, RAX;
                        mov d, RDX;
                    }

                return (d << 32) | a;
            }
        }
        else
        {
            float seconds(ulong ticks){ return TickDuration(ticks).nsecs * 1e-9; }
            
            ulong time()
            {
                return TickDuration.currSystemTick.length;
            }
        }

        static assert(EnumMembers!(E).length == E.max + 1 && E.min == 0);

        shared ulong[E.max + 1] profTimes;

        static ~this()
        {
            foreach(e; EnumMembers!E)
                stderr.writefln("%-15s %sms", 
                    e, seconds(profTimes[e]) * 1e3); 
        }

        void profStart(E e)
        {
            profTimes[e] -= time();
        }

        void profStop(E e)
        {
            profTimes[e] += time(); 
        }

        void profStopStart(E e1, E e2)
        {
            auto t = time();
            profTimes[e1] += t;
            profTimes[e2] -= t;
        }
    } 
    else
    {
        void profStart(E e){}
        void profStop(E e){}
        void profStopStart(E e1, E e2){}
    }
}
