//
//  GCDThreadsafeSpec.m
//  BrynKitTests
//
//  Created by bryn austin bellomy on 5.30.13.
//  Copyright (c) 2013 signalenvelope llc. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import <libextobjc/EXTScope.h>

#import "GCDThreadsafe.h"

@interface ThreadsafeClass : NSObject <GCDThreadsafe>
    @property (nonatomic, assign, readwrite) NSUInteger counter;
@end


@implementation ThreadsafeClass

@synthesize counter = _counter;

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        @gcd_threadsafe_init( self.queueCritical, CONCURRENT, "BrynKit.GCDThreadsafe critical queue" );
    }
    return self;
}

- (void) runTestingBlockAsCriticalMutableSection:(dispatch_block_t)block
{
    [self runCriticalMutableSection:^{
        block();
    }];
}

- (void) runTestingBlockAsCriticalReadSection:(dispatch_block_t)block
{
    [self runCriticalReadSection:^{
        block();
    }];
}

- (void) setCounter:(NSUInteger)counter
{
    [self runCriticalMutableSection:^{
        _counter = counter;
    }];
}

- (NSUInteger) counter
{
    __block NSUInteger theValue = 0;
    [self runCriticalReadSection:^{
        theValue = _counter;
    }];
    return theValue;
}

@end

SPEC_BEGIN(GCDThreadsafeSpec)

context(@"An object implementing GCDThreadsafe", ^{
    __block ThreadsafeClass *testObj = [[ThreadsafeClass alloc] init];

    describe(@"after initialization", ^{

        it(@"should have a non-nil queueCritical property", ^{
            [testObj.queueCritical shouldNotBeNil];
        });

        it(@"should run critical mutable section blocks on its self.queueCritical queue", ^{

            [testObj runTestingBlockAsCriticalMutableSection:^{
                [[theValue(BKCurrentQueueIs(testObj.queueCritical))     should] beYes];
                [[theValue(BKCurrentQueueIs(dispatch_get_main_queue())) should] beNo];
            }];

        });

        it(@"should run critical read section blocks on its self.queueCritical queue", ^{

            [testObj runTestingBlockAsCriticalReadSection:^{
                [[theValue(BKCurrentQueueIs(testObj.queueCritical))     should] beYes];
                [[theValue(BKCurrentQueueIs(dispatch_get_main_queue())) should] beNo];
            }];

        });

        it(@"should interoperate seamlessly with synchronous, declarative code", ^{

            [[theValue(testObj.counter) should] beZero];

            testObj.counter++;
            [[theValue(testObj.counter) should] equal:@1];

            testObj.counter++;
            testObj.counter++;
            testObj.counter++;
            [[theValue(testObj.counter) should] equal:@4];

            testObj.counter = 888;
            [[theValue(testObj.counter) should] equal:@888];

            // wait for async tests to catch up
            // @@TODO: come on bro do this better
            [testObj runCriticalReadSection:^{}];

        });

        it(@"should run critical blocks immediately when already on the critical queue", ^{

            [testObj runTestingBlockAsCriticalMutableSection:^{
                testObj.counter = 777;
                [[theValue(testObj.counter) should] equal:@777];
            }];

            // wait for async tests to catch up
            // @@TODO: come on bro do this better
            [testObj runCriticalReadSection:^{}];
        });

        it(@"", ^{

            [testObj runCriticalMutableSection:^{
                testObj.counter = 9999;
            }];

            [[theValue(testObj.counter) should] equal:@9999];

            // wait for async tests to catch up
            // @@TODO: come on bro do this better
            [testObj runCriticalReadSection:^{}];
        });
    });
    
    
});

SPEC_END




