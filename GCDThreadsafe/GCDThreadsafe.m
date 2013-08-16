//
//  GCDThreadsafe.m
//  GCDThreadsafe
//
//  Created by bryn austin bellomy on 2.23.13.
//  Copyright (c) 2013 bryn austin bellomy.  All rights reserved.
//

#import <libextobjc/EXTScope.h>
#import <libextobjc/EXTConcreteProtocol.h>
#import "GCDThreadsafe.h"


#define GCDDefineVoidKey( key ) \
        static void *const key = (void *)&key

GCDDefineVoidKey( GCDThreadsafeQueueIDKey );
GCDDefineVoidKey( GCDThreadsafeAssociatedObject_CriticalQueue );



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
    gcd_retainUntilScopeExit( queue );

    GCDCurrentQueueIs( queue )
        ? block()
        : dispatch_sync( queue, block );
}



void GCDDispatchSafeBarrierSync( dispatch_queue_t queue, dispatch_block_t block )
{
    assert( queue != NULL );
    assert( block != NULL );
    gcd_retainUntilScopeExit( queue );

    GCDCurrentQueueIs( queue )
        ? block()
        : dispatch_barrier_sync( queue, block );
}



void GCDInitializeQueue( dispatch_queue_t queue )
{
    assert( queue != NULL );
    gcd_retainUntilScopeExit( queue );

    GCDQueueEnsureQueueHasUUID( queue );
}



BOOL GCDCurrentQueueIs( dispatch_queue_t otherQueue )
{
    assert( otherQueue != NULL );
    gcd_retainUntilScopeExit( otherQueue );

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
    void *uuid = calloc( 1, sizeof(uuid) );
    assert( uuid != NULL );

    return uuid;
}



void GCDQueueUUIDRelease( void *context )
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
    assert( queue != NULL );
    gcd_retainUntilScopeExit( queue );

    void *uuid = GCDQueueGetUUID( queue );
    if ( !uuid )
    {
        uuid = GCDQueueUUIDCreate();
        assert( uuid != NULL );
        
        dispatch_queue_set_specific( queue, GCDThreadsafeQueueIDKey, uuid, GCDQueueUUIDRelease );
    }

    return uuid;
}



void *GCDQueueGetUUID( dispatch_queue_t queue )
{
    assert( queue != NULL );
    gcd_retainUntilScopeExit( queue );

    void *uuid = dispatch_queue_get_specific( queue, GCDThreadsafeQueueIDKey );

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
        NSString *label = [NSStringFromClass(self.class) stringByAppendingString:@".queueCritical"];
        @gcd_threadsafe_init( queueCritical, SERIAL, [label UTF8String] );
        gcd_retain( queueCritical );

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





