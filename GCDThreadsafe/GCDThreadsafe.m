//
//  GCDThreadsafe.m
//  GCDThreadsafe
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 bryn austin bellomy.  All rights reserved.
//

#import <libextobjc/EXTConcreteProtocol.h>
#import "GCDThreadsafe.h"


#define GCDDefineVoidKey(key) \
        static void *const key = (void *)&key

GCDDefineVoidKey( GCDThreadsafeQueueIDKey );
GCDDefineVoidKey( GCDThreadsafeAssociatedObject_CriticalQueue );


void *GCDQueueEnsureQueueHasUUID( dispatch_queue_t queue ) __attribute__(( nonnull (1) ));
void *GCDQueueGetUUID( dispatch_queue_t queue ) __attribute__(( nonnull (1) ));
void *GCDQueueGetCurrentQueueUUID();



/**---------------------------------------------------------------------------------------
 * @name Public API
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Public API
#pragma mark-

void GCDDispatchSafeSync( dispatch_queue_t queue, dispatch_block_t block )
{
    assert( queue != NULL );
    assert( block != NULL );

    GCDCurrentQueueIs( queue )
        ? block()
        : dispatch_sync( queue, block );
}



void GCDDispatchSafeBarrierSync( dispatch_queue_t queue, dispatch_block_t block )
{
    assert( queue != NULL );
    assert( block != NULL );

    GCDCurrentQueueIs( queue )
        ? block()
        : dispatch_barrier_sync( queue, block );
}



void GCDInitializeQueue( dispatch_queue_t queue )
{
    gcd_retain( queue );
    {
        GCDQueueEnsureQueueHasUUID( queue );
    }
    gcd_release( queue );
}



BOOL GCDCurrentQueueIs( dispatch_queue_t otherQueue )
{
    assert( otherQueue != NULL );

    void *uuidOther = GCDQueueEnsureQueueHasUUID( otherQueue );
    void *uuidMine  = GCDQueueGetCurrentQueueUUID();

    assert( uuidOther != NULL );

    return uuidMine != NULL && uuidMine == uuidOther;
}


/**---------------------------------------------------------------------------------------
 * @name Private helper functions
 * ---------------------------------------------------------------------------------------
 */

#pragma mark- Private helper functions
#pragma mark-

void *GCDQueueUUIDCreate()
{
    void *uuid = calloc( 1, 1 );
    assert( uuid != NULL );

    return uuid;
}



void GCDQueueUUIDRelease(void *context)
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
void *GCDQueueEnsureQueueHasUUID( dispatch_queue_t queue )
{
    void *uuid = GCDQueueGetUUID( queue );

    gcd_retain( queue );
    {
        if ( !uuid )
        {
            uuid = GCDQueueUUIDCreate();
            assert( uuid != NULL );
            
            dispatch_queue_set_specific( queue, GCDThreadsafeQueueIDKey, uuid, GCDQueueUUIDRelease );
        }
    }
    gcd_release( queue );

    return uuid;
}



void *GCDQueueGetUUID( dispatch_queue_t queue )
{
    void *uuid = NULL;
    gcd_retain( queue );
    {
        uuid = dispatch_queue_get_specific( queue, GCDThreadsafeQueueIDKey );
    }
    gcd_release( queue );
    return uuid;
}



void *GCDQueueGetCurrentQueueUUID()
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
    dispatch_queue_t queueCritical = GCDCastObjectPointerToDispatchObject( dispatch_queue_t, pointerToQueue );

    // auto-initialize the queue as a serial queue with a default label "{CLASS}.queueCritical"
    if ( queueCritical == NULL )
    {
        NSString *label = [NSString stringWithFormat:@"%@.queueCritical", NSStringFromClass(self.class) ];
        @gcd_threadsafe_init( queueCritical, SERIAL, [label UTF8String] );

        self.queueCritical = queueCritical;

    }

    return queueCritical;
}



- (void) setQueueCritical:(dispatch_queue_t)queueCritical
{
    objc_setAssociatedObject( self,
                              GCDThreadsafeAssociatedObject_CriticalQueue,
                              GCDCastObjectPointerToDispatchObject(id, queueCritical),
                              OBJC_ASSOCIATION_RETAIN );
}



- (void) runCriticalMutableSection: (dispatch_block_t)block_mutationOperation
{
    assert( self.queueCritical != nil );

    if ( GCDCurrentQueueIs( self.queueCritical ) ) {
        block_mutationOperation();
    }
    else {
        dispatch_barrier_async( self.queueCritical, block_mutationOperation );
    }
}



- (void) runCriticalReadSection: (dispatch_block_t)block_readOperation
{
    assert( self.queueCritical != nil );

    GCDDispatchSafeBarrierSync( self.queueCritical, block_readOperation );

//    if ( GCDCurrentQueueIs( self.queueCritical ) ) {
//        block_readOperation();
//    }
//    else {
//        GCDDispatchSafeBarrierSync( self.queueCritical, block_readOperation );
//    }
}


@end





