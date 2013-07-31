
# // gcd threadsafe'ing

[![Build Status](https://travis-ci.org/brynbellomy/GCDThreadsafe.png)](https://travis-ci.org/brynbellomy/GCDThreadsafe)

The main idea with this thing is to make it feel extremely familiar to implement.  The conventions herein should look and feel like old-school Objective-C `@synchronized` blocks and `@property (atomic)` declarations.

*Note: like plenty of other folks these days, I'm interested in forcefully phasing out `@synchronized`/`atomic` -- it's some slow ass grandma shit and has no place in the future next to the flying cars.*

You can use nearly the same patterns, the only real exception being the `@strongify(self)` and `@weakify(self)` boilerplate stuff from [libextobjc](http://github.com/jspahrsummers/libextobjc) (which simply exists to prevent block-related retain cycles).



# critical sections

A critical section is a portion of your code that needs threadsafe access to some resource.  There are two types of critical sections, at least for the purposes of `GCDThreadsafe`.

- **Critical writes (i.e., 'mutable' sections)**
    + can write to any properties/ivars that need to be synchronized/threadsafe.
    + dispatched as __async__ barrier blocks.  fast as lightning.  synchronized but don't necessarily run immediately.
- **Critical reads (i.e., 'readonly' sections)**
    + dispatched as __sync__ barrier blocks.  synchronized and run immediately.  (after all, you're extracting a value from the critical section -- gotta wait for it before you proceed, right?)
    + technically, you're allowed to do reads *and* writes in these.

It's probably a smart idea to only do what you say you're gonna do in each section.  Read in read sections, write in write sections.  Don't mix your shit up, bartender.  Somebody paid for that drink.



# auto-getters, auto-setters

Yep, GCDThreadsafe has a few `#define`macros that automatically implement getters and setters for the properties on your threadsafe class.  It's like being able to specify `@property (atomic)`, except it's fast and doesn't suck.

An example from the tests:

```objective-c
@interface ThreadsafeClass : NSObject <GCDThreadsafe>
    @property (nonatomic, assign, readwrite) NSUInteger counter;
@end


@implementation ThreadsafeClass

@synthesize counter = _counter;

@gcd_threadsafe_implementSetter( NSUInteger, counter, setCounter: )
@gcd_threadsafe_implementGetter_assign( NSUInteger, counter )

// ...

@end
```

There's also `@gcd_threadsafe_implementGetter_object()` for Objective-C objects and `@gcd_threadsafe_implementGetter_dispatch()` for GCD objects (which will automatically figure out whether GCD objects are being treated by the runtime as Objective-C objects or as old-school C pointers).



# tl;dr

To threadsafe your class with all of this nonsense, all you have to do is declare that it conforms to the `GCDThreadsafe` protocol.

That's it.

This protocol is actually defined using [libextobjc](http://github.com/jspahrsummers/libextobjc)'s magical "concrete protocol" mechanism, meaning that it automatically implements the methods it declares (unless you define your own implementation, which you shouldn't).  Ain't gotta do a thing.  It's a lot like a mixin or a class extension, but a little bit gentler (in case you do for some idiotic reason want to override my **free**, **no questions asked**, **drive it out of the lot** default implementations).

So in your Podfile (you're using [CocoaPods](http://cocoapods.org), right?):

```ruby
pod 'GCDThreadsafe'
```



In your class's header:

```objective-c
#import <GCDThreadsafe/GCDThreadsafe.h>

@interface MyClass <GCDThreadsafe>
// ...
@end
```



And to perform **critical writes** in your code:

```objective-c
@weakify(self);
[self runCriticalMutableSection:^{
    @strongify(self);

    self.someProperty = @"a new value";
    [self someMethodThatMutatesObjectState];
}];
```



...and **critical reads**:

```objective-c
__block NSString *synchronizedValue = nil;

@weakify(self);
[self runCriticalReadSection:^{
    @strongify(self);
    
    synchronizedValue = [_someHiddenIvar copy];
}];

NSLog( @"synchronizedValue = %@", synchronizedValue );
```




That's all there is to it, really.  The framework will (should? ... might???) line everything up as it oughta be.  This is an alpha release, to be
sure, so I'd very much welcome any traffic that would like to make its way into the issue queue.

Then again, if I have the balls to throw alpha code into production apps, shouldn't you?



# custom queues

If you're a fool and want to initialize your queue with non-standard characteristics (i.e., giving it a custom name or making it concurrent), you can do so in your class's `-init` method, before doing anything else:

```objective-c
self = [super init];
if (self)
{
    // the queueCritical property has to be named as such right now... i'll fix this eventually, maybe.
    // also, you should definitely use a SERIAL queue, but if you're feeling ridiculous, you can always
    // give CONCURRENT a shot as well.

    @gcd_threadsafe_init( self.queueCritical, SERIAL, "com.pton.queueCritical" );

    // ...
}
```

([libextobjc](http://github.com/jspahrsummers/libextobjc)'s concrete protocols are fkn sick, rite???)






