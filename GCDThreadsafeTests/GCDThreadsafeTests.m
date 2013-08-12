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

@gcd_threadsafe_implementSetter( NSUInteger, counter, setCounter: )
@gcd_threadsafe_implementGetter_assign( NSUInteger, counter )

- (instancetype) init
{
    self = [super init];
    if ( self ) {
    }
    return self;
}

- (void) runTestingBlockAsCriticalMutableSection:(dispatch_block_t)block
{
    assert(self != nil);
    @weakify(self);

    [self runCriticalMutableSection:^{
        @strongify(self);
        assert(self != nil);

        block();
    }];
}

- (void) runTestingBlockAsCriticalReadSection:(dispatch_block_t)block
{
    [self runCriticalReadSection:^{
        block();
    }];
}

@end




SPEC_BEGIN(GCDThreadsafeSpec)

context(@"An object implementing GCDThreadsafe", ^{
    __block ThreadsafeClass *testObj = [[ThreadsafeClass alloc] init];

    describe(@"after initialization", ^{

        it(@"should have a non-nil queueCritical property", ^{
            [testObj.queueCritical shouldNotBeNil];

            // wait for async tests to catch up
            // @@TODO: come on bro do this better
//            [testObj runCriticalReadSection:^{}];
        });

        it(@"should run critical mutable section blocks on its self.queueCritical queue", ^{

            [testObj runTestingBlockAsCriticalMutableSection:^{
                [[theValue(GCDCurrentQueueIs(testObj.queueCritical))     should] beYes];
                [[theValue(GCDCurrentQueueIs(dispatch_get_main_queue())) should] beNo];
            }];

        });

        it(@"should run critical read section blocks on its self.queueCritical queue", ^{

            [testObj runTestingBlockAsCriticalReadSection:^{
                [[theValue(GCDCurrentQueueIs(testObj.queueCritical))     should] beYes];
                [[theValue(GCDCurrentQueueIs(dispatch_get_main_queue())) should] beNo];
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
//            [testObj runCriticalReadSection:^{}];

        });

        it(@"should run critical blocks immediately when already on the critical queue", ^{

            [testObj runTestingBlockAsCriticalMutableSection:^{
                testObj.counter = 777;
                [[theValue(testObj.counter) should] equal:@777];
            }];

            // wait for async tests to catch up
            // @@TODO: come on bro do this better
//            [testObj runCriticalReadSection:^{}];
        });

        it(@"", ^{

            [testObj runCriticalMutableSection:^{
                testObj.counter = 9999;
            }];

            // wait for async tests to catch up
            // @@TODO: come on bro do this better
//            [testObj runCriticalReadSection:^{}];

            [[theValue(testObj.counter) should] equal:@9999];

            // wait for async tests to catch up
            // @@TODO: come on bro do this better
//            [testObj runTestingBlockAsCriticalReadSection:^{}];
        });
    });


});

SPEC_END




