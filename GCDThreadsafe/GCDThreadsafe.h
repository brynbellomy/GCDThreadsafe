//
//  GCDThreadsafe.h
//  GCDThreadsafe
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 bryn austin bellomy.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libextobjc/metamacros.h>
#import <libextobjc/EXTConcreteProtocol.h>

///**
// * @@TODO: These constants indicate the desired behavior when synchronously dispatching
// * a block to a given queue and we are already within the queue.
// *
// * - **SEDispatchSourceDeadlockBehaviorExecute**:   do not add the block to the queue, execute inline (default)
// * - **SEDispatchSourceDeadlockBehaviorSkip**:      do not add the block to the queue, drop it silently
// * - **SEDispatchSourceDeadlockBehaviorLog**:       do not add the block to the queue, log to console
// * - **SEDispatchSourceDeadlockBehaviorException**: do not add the block to the queue, raise an exception
// * - **SEDispatchSourceDeadlockBehaviorBlock**:     add the block to the queue, and be damned
// */
//typedef NS_ENUM(NSUInteger, SEDispatchSourceDeadlockBehavior)
//{
//    SEDispatchSourceDeadlockBehaviorExecute = 1,
//    SEDispatchSourceDeadlockBehaviorSkip = 2,
//    SEDispatchSourceDeadlockBehaviorLog = 3,
//    SEDispatchSourceDeadlockBehaviorAssert = 4,
//    SEDispatchSourceDeadlockBehaviorBlock = 5
//};


/**---------------------------------------------------------------------------------------
 * @name ARC / OS_OBJECT_USE_OBJC compatibility macros
 *  ---------------------------------------------------------------------------------------
 */

#pragma mark- ARC / OS_OBJECT_USE_OBJC compatibility macros
#pragma mark-

#if __has_feature(objc_arc) // ARC enabled

#   define gcd_retain(...)
#   define gcd_release(...)

#   if OS_OBJECT_USE_OBJC
#       define gcd_strong                                   strong
#       define gcd_threadsafe_implementGetter_dispatch      gcd_threadsafe_implementGetter_object
#   else
#       define gcd_strong                                   assign
#       define gcd_threadsafe_implementGetter_dispatch      gcd_threadsafe_implementGetter_assign
#   endif

#else // non-ARC

#   define gcd_retain(...)                                  dispatch_retain(__VA_ARGS__)
#   define gcd_release(...)                                 dispatch_release(__VA_ARGS__)

#   if OS_OBJECT_USE_OBJC
#       define gcd_strong                                   retain
#       define gcd_threadsafe_implementGetter_dispatch      gcd_threadsafe_implementGetter_assign
#   else
#       define gcd_strong                                   assign
#       define gcd_threadsafe_implementGetter_dispatch      gcd_threadsafe_implementGetter_assign
#   endif

#endif

#define gcd_releaseOnScopeExit(...) \
        @onExit { gcd_release( (__VA_ARGS__) ); }

#define gcd_retainUntilScopeExit(...) \
        gcd_retain( (__VA_ARGS__) ); \
        @onExit { gcd_release( (__VA_ARGS__) ); }

/**
 * @name Dispatch queue helper functions
 *
 * These functions allow for safer use of basic Grand Central Dispatch functionality.
 */

#pragma mark- Dispatch queue helper functions
#pragma mark-

/**
 * Initialize \c queue such that other BrynKit/GCDThreadsafe functions can be called on it.
 *
 * @param queue The dispatch queue to initialize.
 *
 * @see GCDCurrentQueueIs
 * @see GCDDispatchSafeSync
 */
void GCDInitializeQueue( dispatch_queue_t queue ) __attribute__((nonnull (1)));

/**
 * Returns \c YES if the current queue is the same as \c otherQueue.
 *
 * @warning The \c dispatch_queue_t passed to this function must have had \c GCDInitializeQueue called on it prior to this (or any other) BrynKit/GCDThreadsafe function.
 */
BOOL GCDCurrentQueueIs( dispatch_queue_t otherQueue ) __attribute__((nonnull (1)));

/**
 * Dispatches \c block on \c queue synchronously without risking certain basic forms of queue deadlock.
 *
 * If the current queue == \c queue, then \c block will simply be executed immediately rather than dispatched.
 *
 * @param queue The queue on which to dispatch \c block
 * @param block The block to dispatch synchronously
 *
 * @warning The \c dispatch_queue_t passed to this function must have had \c GCDInitializeQueue called on it prior to this (or any other) BrynKit/GCDThreadsafe function.
 */
void GCDDispatchSafeSync( dispatch_queue_t queue, dispatch_block_t block ) __attribute__((nonnull (1, 2)));

/**
 * Dispatches \c block on \c queue synchronously (as a barrier block) without risking certain basic forms of queue deadlock.
 *
 * If the current queue == \c queue, then \c block will simply be executed immediately rather than dispatched.
 *
 * @param queue The queue on which to dispatch \c block
 * @param block The block to dispatch synchronously
 *
 * @warning The \c dispatch_queue_t passed to this function must have had \c GCDInitializeQueue called on it prior to this (or any other) BrynKit/GCDThreadsafe function.
 */
void GCDDispatchSafeBarrierSync( dispatch_queue_t queue, dispatch_block_t block ) __attribute__((nonnull (1, 2)));


// @@TODO: document these
void *GCDQueueEnsureQueueHasUUID( dispatch_queue_t queue );
void *GCDQueueGetUUID( dispatch_queue_t queue );
void *GCDQueueGetCurrentQueueUUID();


/** @/functiongroup */


/**---------------------------------------------------------------------------------------
 * @name The GCDThreadsafe concrete protocol
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- @concreteprotocol GCDThreadsafe
#pragma mark-


/**
 * When a class declares that it implements GCDThreadsafe, default implementations of the methods in this protocol
 * are automatically added to that class unless it defines its own custom implementations (as with a normal protocol).
 */

@protocol GCDThreadsafe

@concrete
    @property (nonatomic, gcd_strong, readwrite) dispatch_queue_t queueCritical;

    - (void) runCriticalMutableSection:(dispatch_block_t)block_mutationOperation __attribute__((nonnull (1)));
    - (void) runCriticalReadSection:(dispatch_block_t)block_readOperation __attribute__((nonnull (1)));

@end



/**
 * @define @gcd_threadsafe_init
 *
 * @param queue
 * @param concurrency Either SERIAL or CONCURRENT
 * @param queueLabel
 */
#define gcd_threadsafe_init( QUEUE, CONCURRENCY, QUEUE_LABEL ) \
    try{}@finally{} \
    do { \
        QUEUE = dispatch_queue_create( QUEUE_LABEL, metamacro_concat( DISPATCH_QUEUE_, CONCURRENCY )); \
        GCDInitializeQueue( QUEUE ); \
    } while(0)


#define gcd_threadsafe_implementGetter_object( TYPE, PROPERTY ) \
        class NSObject; \
\
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wshadow-ivar\"") \
\
        - (TYPE) PROPERTY \
        { \
            __block TYPE instance = nil; \
\
            [self runCriticalReadSection:^{ \
                instance = metamacro_concat(_,PROPERTY); \
            }]; \
\
            return instance; \
        } \
\
        _Pragma("clang diagnostic pop")



#define gcd_threadsafe_implementGetter_assign( TYPE, PROPERTY ) \
        class NSObject; \
\
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wshadow-ivar\"") \
\
        - (TYPE) PROPERTY \
        { \
            __block TYPE instance; \
\
            [self runCriticalReadSection:^{ \
                instance = metamacro_concat(_,PROPERTY); \
            }]; \
\
            return instance; \
        } \
\
        _Pragma("clang diagnostic pop")



/**
 * Expands into the default implementation of a property setter that runs on the critical section queue.
 *
 * For example, in your `@implementation` block:
 
      @gcd_threadsafe_implementSetter( dispatch_block_t, handler, setHandler: );

 */

#define gcd_threadsafe_implementSetter( TYPE, PROPERTY, SETTER_SELECTOR ) \
        class NSObject; \
\
        _Pragma("clang diagnostic push") \
        _Pragma("clang diagnostic ignored \"-Wshadow-ivar\"") \
\
        - (void) SETTER_SELECTOR (TYPE) obj \
        { \
            @weakify(self); \
\
            [self runCriticalMutableSection:^{ \
                @strongify(self); \
                assert( self != nil ); \
\
                metamacro_concat(_,PROPERTY) = obj; \
            }]; \
        }





#define GCDCastObjectPointerToDispatchObject( TYPE, VOID_PTR ) \
            ({ (OS_OBJECT_BRIDGE TYPE)(OS_OBJECT_BRIDGE void *) VOID_PTR; })











