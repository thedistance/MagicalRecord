//
//  ARCoreDataAction.m
//  Freshpod
//
//  Created by Saul Mora on 2/24/11.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

//#import "ARCoreDataAction.h"
#import "CoreData+MagicalRecord.h"
#import <dispatch/dispatch.h>

dispatch_queue_t background_save_queue(void);
void cleanup_save_queue(void);

static dispatch_queue_t coredata_background_save_queue;

dispatch_queue_t background_save_queue()
{
    if (coredata_background_save_queue == NULL)
    {
        coredata_background_save_queue = dispatch_queue_create("com.magicalpanda.magicalrecord.backgroundsaves", 0);
    }
    return coredata_background_save_queue;
}

void cleanup_save_queue()
{
	if (coredata_background_save_queue != NULL)
	{
		dispatch_release(coredata_background_save_queue);
	}
}

@implementation MRCoreDataAction

+ (void) cleanUp
{
	cleanup_save_queue();
}

#ifdef NS_BLOCKS_AVAILABLE

+ (void) saveDataWithBlock:(void (^)(NSManagedObjectContext *localContext))block errorHandler:(void (^)(NSError *))errorHandler
{
    NSManagedObjectContext *mainContext  = [NSManagedObjectContext defaultContext];
    NSManagedObjectContext *localContext = mainContext;
    
    if (![NSThread isMainThread]) 
    {
        
#if kCreateNewCoordinatorOnBackgroundOperations == 1
        NSPersistentStoreCoordinator *localCoordinator = [NSPersistentStoreCoordinator coordinatorWithPersitentStore:[NSPersistentStore defaultPersistentStore]];
        localContext = [NSManagedObjectContext contextThatNotifiesDefaultContextOnMainThreadWithCoordinator:localCoordinator];
#else
        localContext = [NSManagedObjectContext contextThatNotifiesDefaultContextOnMainThread];
#endif
        
        [mainContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        [localContext setMergePolicy:NSOverwriteMergePolicy];
    }
    
    block(localContext);
    
    if ([localContext hasChanges]) 
    {
        [localContext saveWithErrorHandler:errorHandler];
    }
    
    localContext.notifiesMainContextOnSave = NO;
    [mainContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
}

+ (void) saveDataWithBlock:(void(^)(NSManagedObjectContext *localContext))block
{   
    [self saveDataWithBlock:block errorHandler:NULL];
}

+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block
{
    dispatch_async(background_save_queue(), ^{
        [self saveDataWithBlock:block];
    });
}

+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(void(^)(void))callback
{
    dispatch_async(background_save_queue(), ^{
        [self saveDataWithBlock:block];
        
        if (callback) 
        {
            dispatch_async(dispatch_get_main_queue(), callback);
        }
    });
}

+ (void) saveDataInBackgroundWithBlock:(void (^)(NSManagedObjectContext *localContext))block completion:(void (^)(void))callback errorHandler:(void (^)(NSError *))errorHandler
{
    dispatch_async(background_save_queue(), ^{
        [self saveDataWithBlock:block errorHandler:errorHandler];
        
        if (callback)
        {
            dispatch_async(dispatch_get_main_queue(), callback);
        }
    });
}

+ (void) lookupWithBlock:(void(^)(NSManagedObjectContext *localContext))block
{
    NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];

    if (block)
    {
        block(context);
    }
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *localContext))block;
{
    [self saveDataWithOptions:options withBlock:block completion:NULL];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *localContext))block completion:(void(^)(void))callback;
{
    //TODO: add implementation    
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void (^)(NSManagedObjectContext *))block completion:(void (^)(void))callback errorHandler:(void(^)(NSError *))errorCallback
{
    
}

#endif

@end