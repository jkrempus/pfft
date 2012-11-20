module pfft.profile;

template ProfileMixin(E)
{
    version(Profile)
    {
        import std.stdio, std.traits;
        import core.time;

        static assert(EnumMembers!(E).length == E.max + 1 && E.min == 0);

        ulong[E.max + 1] profTimes;

        static ~this()
        {
            foreach(e; EnumMembers!E)
                writefln("%s\t%sms", e, profTimes[e] * 1e-6); 
        }

        void profStart(E e)
        {
            synchronized
                profTimes[e] -= TickDuration.currSystemTick.nsecs;
        }

        void profStop(E e)
        {
            synchronized
                profTimes[e] += TickDuration.currSystemTick.nsecs; 
        }
    
        void profStopStart(E e1, E e2)
        {
            synchronized
            {
                auto t = TickDuration.currSystemTick.nsecs;
                profTimes[e1] += t;
                profTimes[e2] -= t;
            }
        }
    } 
    else
    {
        void profStart(Action a){}
        void profStop(Action a){}
        void profStopStart(E e1, E e2){}
    }
}
