
# // gcd threadsafe'ing

The main idea with this thing is to make it feel extremely familiar to implement.  It more or less looks and acts like an old-school Objective-C `@synchronized` block.

*Note: like plenty of other folks these days, I'm interested in forcefully phasing out `@synchronized` -- it's some slow ass grandma shit and has no place in the future next to the flying cars.*

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



# tl;dr

To set up your class with this nonsense, all you have to do is declare that it conforms to the `GCDThreadsafe` protocol.  This protocol is actually defined using [libextobjc](http://github.com/jspahrsummers/libextobjc)'s magical "concrete" protocol mechanism, meaning that it automatically implements the methods it declares (unless you define your own implementation, which you shouldn't).  Ain't gotta do a thing.  It's a lot like a mixin or a class extension.

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


In your class's `-init` method, before doing anything else:

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
[self runCriticalReadonlySection:^{
    @strongify(self);
    
    synchronizedValue = [_someHiddenIvar copy];
}];

NSLog( @"synchronizedValue = %@", synchronizedValue );
```




... the framework will (should? ... might???) line everything up as it oughta be.  This is an alpha release, to be
sure, so I'd very much welcome any traffic that would like to make its way into the issue queue.

Then again, if I have the balls to throw alpha code into production apps, shouldn't you?





