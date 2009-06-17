// A Better Logging Function
// Source: http://blog.mbcharbonneau.com/post/56581688/better-logging-in-objective-c
#define DebugLog(format, ...) NSLog(@"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(format), ##__VA_ARGS__])
// Source: http://zathras.de/angelweb/blog-uk-helper-macros.htm
// #define  DebugLog(format, ...) NSLog( @"%s: %@", __PRETTY_FUNCTION__, [NSString stringWithFormat: format, ## __VA_ARGS__])

// A quick check if an object is empty.
// Source: http://www.wilshipley.com/blog/2005/10/pimp-my-code-interlude-free-code.html
static inline BOOL isEmpty(id thing)
{
    return (thing == nil)
        || ([thing respondsToSelector:@selector(length)]
            && [(NSData *)thing length] == 0)
        || ([thing respondsToSelector:@selector(count)]
            && [(NSArray *)thing count] == 0);
}

// Helpful macros for object creation.
// Source: http://cbarrett.tumblr.com/post/53371495/some-helpful-macros-for-object-creation
#define NSARRAY(...) [NSArray arrayWithObjects: __VA_ARGS__, nil]
#define NSDICT(...) [NSDictionary dictionaryWithObjectsAndKeys: __VA_ARGS__, nil]
#define NSSET(...) [NSSet setWithObjects: __VA_ARGS__, nil]
#define NSBOOL(_X_) ((_X_) ? (id)kCFBooleanTrue : (id)kCFBooleanFalse)

// Use Unions (instead of type-punning) to recast Structs.
// Source: http://cocoawithlove.com/2008/04/using-pointers-to-recast-in-c-is-bad.html
#define UNION_CAST(x, destType) (((union {__typeof__(x) a; destType b;})x).b)

// Automatically release objects when they leave their scope.
// Source: http://www.cocoabuilder.com/archive/message/cocoa/2009/3/13/232287
#define autoscoped __attribute__((cleanup(releaseObject)))

static inline void releaseObject(id *thing)
{
    [*thing release];
}

// Compile-Time Assertions
// Source: http://unixjunkie.blogspot.com/2007/10/better-compile-time-asserts_29.html
#define _COMPILE_ASSERT_SYMBOL_INNER(line, msg) __COMPILE_ASSERT_ ## line ## __ ## msg
#define _COMPILE_ASSERT_SYMBOL(line, msg) _COMPILE_ASSERT_SYMBOL_INNER(line, msg)
#define COMPILE_ASSERT(test, msg) typedef char _COMPILE_ASSERT_SYMBOL(__LINE__, msg) [ ((test) ? 1 : -1) ]

// COMPILE_ASSERT(1 == 1, foo);
// COMPILE_ASSERT(2 == 2, foo);

// Defensive Coding: Set released ivars to nil.
// Source: http://zathras.de/angelweb/blog-defensive-coding-in-objective-c.htm
#define DESTROY(obj)    do {\
                            [obj release];\
                            obj = nil;\
                        } while(0)

// Proper Key-Value Observer Usage
// Source: http://www.dribin.org/dave/blog/archives/2008/09/24/proper_kvo_usage/
#define KVO_Context(_X_) static NSString *const _X_ = @#_X_
