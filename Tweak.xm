#import <Foundation/Foundation.h>
#import <substrate.h>
#import <sys/time.h>
#import <time.h>

// Subway Surfers 2.36.0 was current in July 2022.
// This tweak makes ONLY the injected app see 2022-07-09 12:00:00 UTC.
static const time_t kFakeUnixTime = 1657368000;

// -------- Objective-C / Foundation --------

%hook NSDate

+ (instancetype)date {
    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)kFakeUnixTime];
}

+ (instancetype)now {
    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)kFakeUnixTime];
}

+ (NSTimeInterval)timeIntervalSinceReferenceDate {
    // Apple's reference date is 2001-01-01 00:00:00 UTC.
    static const NSTimeInterval appleEpochOffset = 978307200.0;
    return (NSTimeInterval)kFakeUnixTime - appleEpochOffset;
}

%end

// -------- C time APIs --------

static time_t (*orig_time)(time_t *tloc);
static time_t repl_time(time_t *tloc) {
    if (tloc) *tloc = kFakeUnixTime;
    return kFakeUnixTime;
}

static int (*orig_gettimeofday)(struct timeval *tv, void *tz);
static int repl_gettimeofday(struct timeval *tv, void *tz) {
    if (tv) {
        tv->tv_sec = kFakeUnixTime;
        tv->tv_usec = 0;
    }
    return 0;
}

static int (*orig_clock_gettime)(clockid_t clk_id, struct timespec *tp);
static int repl_clock_gettime(clockid_t clk_id, struct timespec *tp) {
    // Only fake wall-clock time. Do NOT fake monotonic clocks used for animations/timers.
    if (clk_id == CLOCK_REALTIME && tp) {
        tp->tv_sec = kFakeUnixTime;
        tp->tv_nsec = 0;
        return 0;
    }
    return orig_clock_gettime ? orig_clock_gettime(clk_id, tp) : -1;
}

%ctor {
    @autoreleasepool {
        MSHookFunction((void *)time, (void *)repl_time, (void **)&orig_time);
        MSHookFunction((void *)gettimeofday, (void *)repl_gettimeofday, (void **)&orig_gettimeofday);
        MSHookFunction((void *)clock_gettime, (void *)repl_clock_gettime, (void **)&orig_clock_gettime);
    }
}
