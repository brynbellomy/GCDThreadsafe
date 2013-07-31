//
//  GCDThreadsafe.m
//  BrynKit
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 bryn austin bellomy.  All rights reserved.
//

#import <libextobjc/EXTConcreteProtocol.h>
#import "GCDThreadsafe.h"


#define BKDefineVoidKey(key) \
        static void *const key = (void *)&key

BKDefineVoidKey( GCDThreadsafeQueueIDKey );
BKDefineVoidKey( GCDThreadsafeAssociatedObject_CriticalQueue );


void *BKQueueEnsureQueueHasUUID( dispatch_queue_t queue ) __attribute__(( nonnull (1) ));
void *BKQueueGetUUID( dispatch_queue_t queue ) __attribute__(( nonnull (1) ));
void *BKQueueGetCurrentQueueUUID();



/**---------------------------------------------------------------------------------------
 * @name Public API
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Public API
#pragma mark-

void BKDispatchSafeSync( dispatch_queue_t queue, dispatch_block_t block )
{
    assert( queue != NULL );
    assert( block != NULL );

    BKCurrentQueueIs( queue )
        ? block()
        : dispatch_sync( queue, block );
}



void BKInitializeQueue( dispatch_queue_t queue )
{
    gcd_retain( queue );
    {
        BKQueueEnsureQueueHasUUID( queue );
    }
    gcd_release( queue );
}



BOOL BKCurrentQueueIs( dispatch_queue_t otherQueue )
{
    void *uuidOther = BKQueueEnsureQueueHasUUID( otherQueue );
    void *uuidMine  = BKQueueGetCurrentQueueUUID();

    assert( uuidOther != NULL );

    return uuidMine != NULL && uuidMine == uuidOther;
}


/**---------------------------------------------------------------------------------------
 * @name Private helper functions
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Private helper functions
#pragma mark-

void *BKQueueUUIDCreate()
{
    void *uuid = calloc(1, 1);
    assert( uuid != NULL );

    return uuid;
}



void BKQueueUUIDRelease(void *context)
{
    if ( context )
    {
        free( context );
        context = NULL;
    }
}



/**
 * Ensures that \c queue has a UUID string identifier (for distinguishing it from other queues).
 */
void *BKQueueEnsureQueueHasUUID( dispatch_queue_t queue )
{
    void *uuid = BKQueueGetUUID( queue );

    gcd_retain( queue );
    {
        if ( !uuid )
        {
            uuid = BKQueueUUIDCreate();
            assert( uuid != NULL );
            
            dispatch_queue_set_specific( queue, GCDThreadsafeQueueIDKey, uuid, BKQueueUUIDRelease );
        }
    }
    gcd_release( queue );

    return uuid;
}



void *BKQueueGetUUID( dispatch_queue_t queue )
{
    void *uuid = NULL;
    gcd_retain( queue );
    {
        uuid = dispatch_queue_get_specific( queue, GCDThreadsafeQueueIDKey );
    }
    gcd_release( queue );
    return uuid;
}



void *BKQueueGetCurrentQueueUUID()
{
    void *uuid  = dispatch_get_specific( GCDThreadsafeQueueIDKey );
    return uuid;
}



/**
 * @protocol GCDThreadsafe
 */

@concreteprotocol(GCDThreadsafe)

- (dispatch_queue_t) queueCritical
{
    id pointerToQueue              = objc_getAssociatedObject( self, GCDThreadsafeAssociatedObject_CriticalQueue );
    dispatch_queue_t queueCritical = BKCastObjectPointerToDispatchObject( dispatch_queue_t, pointerToQueue );

    // auto-initialize the queue as a serial queue with a default label "{CLASS}.queueCritical"
    if ( !queueCritical )
    {
        NSString *label = [NSString stringWithFormat:@"%@.queueCritical", NSStringFromClass(self.class) ];
        @gcd_threadsafe_init( queueCritical, SERIAL, [label UTF8String] );
    }

    return queueCritical;
}



- (void) setQueueCritical:(dispatch_queue_t)queueCritical
{
    objc_setAssociatedObject( self,
                              GCDThreadsafeAssociatedObject_CriticalQueue,
                              BKCastObjectPointerToDispatchObject(id, queueCritical),
                              OBJC_ASSOCIATION_RETAIN_NONATOMIC );
}



- (void) runCriticalMutableSection: (dispatch_block_t)block_mutationOperation
{
    assert( self.queueCritical != nil );

    if ( BKCurrentQueueIs( self.queueCritical ) ) {
        block_mutationOperation();
    }
    else {
        dispatch_barrier_async( self.queueCritical, block_mutationOperation );
    }
}



- (void) runCriticalReadSection: (dispatch_block_t)block_readOperation
{
    assert( self.queueCritical != nil );

    if ( BKCurrentQueueIs( self.queueCritical ) ) {
        block_readOperation();
    }
    else {
        BKDispatchSafeSync( self.queueCritical, block_readOperation );
    }
}


@end





