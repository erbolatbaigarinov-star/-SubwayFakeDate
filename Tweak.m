#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/time.h>
#import <time.h>
#import <dlfcn.h>

// Fake wall-clock date for Subway Surfers: 2022-07-09 12:00:00 UTC
static const time_t kFakeUnixTime = 1657368000;

// ---------- NSDate hooks (no CydiaSubstrate) ----------

static id fake_NSDate_date(id self, SEL _cmd) {
    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)kFakeUnixTime];
}

static id fake_NSDate_now(id self, SEL _cmd) {
    return [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)kFakeUnixTime];
}

static NSTimeInterval fake_NSDate_timeIntervalSinceReferenceDate(id self, SEL _cmd) {
    static const NSTimeInterval appleEpochOffset = 978307200.0;
    return (NSTimeInterval)kFakeUnixTime - appleEpochOffset;
}

static void HookClassMethod(Class cls, SEL sel, IMP newImp) {
    Method method = class_getClassMethod(cls, sel);
    if (!method) return;
    method_setImplementation(method, newImp);
}

// ---------- dyld interpose for C time APIs ----------

static time_t fake_time(time_t *tloc) {
    if (tloc) *tloc = kFakeUnixTime;
    return kFakeUnixTime;
}

static int fake_gettimeofday(struct timeval *tv, void *tz) {
    if (tv) {
        tv->tv_sec = kFakeUnixTime;
        tv->tv_usec = 0;
    }
    return 0;
}

static int fake_clock_gettime(clockid_t clk_id, struct timespec *tp) {
    // Fake only wall clock. Leave monotonic clocks alone.
    if (clk_id == CLOCK_REALTIME && tp) {
        tp->tv_sec = kFakeUnixTime;
        tp->tv_nsec = 0;
        return 0;
    }
    // Fallback to mach_continuous style source is not appropriate here.
    // For non-realtime clocks, call the original symbol through dlsym.
    typedef int (*clock_gettime_fn)(clockid_t, struct timespec *);
    static clock_gettime_fn orig = NULL;
    if (!orig) {
        orig = (clock_gettime_fn)dlsym(RTLD_NEXT, "clock_gettime");
    }
    return orig ? orig(clk_id, tp) : -1;
}

#define DYLD_INTERPOSE(_replacement,_replacee) \
    __attribute__((used)) static struct { const void* replacement; const void* replacee; } \
    _interpose_##_replacee __attribute__ ((section ("__DATA,__interpose"))) = { \
        (const void*)(unsigned long)&_replacement, (const void*)(unsigned long)&_replacee \
    };

DYLD_INTERPOSE(fake_time, time)
DYLD_INTERPOSE(fake_gettimeofday, gettimeofday)
DYLD_INTERPOSE(fake_clock_gettime, clock_gettime)

__attribute__((constructor))
static void init_SubwayFakeDate(void) {
    @autoreleasepool {
        Class dateClass = objc_getClass("NSDate");
        HookClassMethod(dateClass, @selector(date), (IMP)fake_NSDate_date);

        if (class_getClassMethod(dateClass, @selector(now))) {
            HookClassMethod(dateClass, @selector(now), (IMP)fake_NSDate_now);
        }

        HookClassMethod(dateClass,
                        @selector(timeIntervalSinceReferenceDate),
                        (IMP)fake_NSDate_timeIntervalSinceReferenceDate);
    }
}
