//
//  CKCoreDataManager.h
//  FoodReminder
//
//  Created by Enix Yu on 27/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

//-----------------------------------------------------------------
#pragma MARK - Callback type def
//-----------------------------------------------------------------

/**
 Migration Progress callback block.
 */
typedef void (^CKCoreDataMigrationProgress)(float progress);

/**
 Migration result callback block. If success, then success = YES, else success = NO,
 And the error will hold the NSError for the failed reason.
 */
typedef void (^CKCoreDataMigrationCompletion)(BOOL success, NSError * _Nullable error);

//-----------------------------------------------------------------
#pragma MARK - Core data helper def.
//-----------------------------------------------------------------

@interface CKCoreDataManager : NSObject

/// Manage object context
@property (nonatomic, readonly) NSManagedObjectContext *context;

/// Manage object model
@property (nonatomic, readonly) NSManagedObjectModel *model;

/// Manage object coordinator
@property (nonatomic, readonly) NSPersistentStoreCoordinator *coordinator;

/// Manage object persistent store
@property (nonatomic, readonly) NSPersistentStore *store;

/// Core Data Store URL
@property (nonatomic, readonly, strong) NSURL *storeURL;


/**
 * Get a shared instance for the core data helper
 * @return An shared instance of CKCoreDataManager
 */
+ (instancetype)sharedInstanced;

/**
 * Use a given store as the default store
 * @param storeURL: The store file URL (should be the path of the store back sqlite file)
 * @return          YES if set to default success, NO if not
 */
- (BOOL)setDefaultDataStoreFromStoreURL:(NSURL *)storeURL;

/**
 * Setup core data persistent store with given store file name
 * @param fileName: The file name for the store
 * @param lightWeightMigration: Whether trigger light weight migration.
 * @param If error occcurred, error return contains the problem for the failure.
 * @return: YES if setup success, NO if not.
 */
- (BOOL)setupCoreDataWithStoreFileName:(NSString *)fileName
                  lightWeightMigration:(BOOL)lightWeightMigration
                                 error:(NSError * _Nullable *)error;

/**
 * Save the model update in core data context
 * @param If error occcurred, error return contains the problem for the failure.
 * @return: YES if setup success, NO if not. If context no changed, always return YES.
 */
- (BOOL)saveContextWithError:(NSError * _Nullable *)error;

/**
 * Determine whether migration is needed or not
 * @param storeURL: The store URL for the migration checking
 * @return YES if migration is need, NO if not.
 */
- (BOOL)isMigrationNeededForStore:(NSURL *)storeURL;

/**
 * Determine default data is imported to the given store or not
 * @param storeURL: The store url for default data import checking
 * @param error:    The error for the data checking
 * @return YES if default data imported, NO if not.
 */
- (BOOL)isDefaultDataImportedForStoreWithURL:(NSURL *)storeURL
                                       error:(NSError **)error;

/**
 * Set the default data as imported for given store
 * @param store:    The store needed to be set default data imported
 */
- (void)setDefaultDataAsImportedForStore:(NSPersistentStore *)store;

/**
 * Start to migrate store to new Managed object model.
 * @param sourceStoreURL: The store URL for the migration
 * @param progress:   Callback when migration progress is updated.
 *                    `progress` indicate the progress, range from 0.0 to 1.0.
 * @param completion: Callback when migration is finished. 
 *                    `success` indicate the migration result.
 *                    `error` indicate the error for the failed reason.
 */
- (void)migrateStore:(NSURL *)sourceStoreURL
            progress:(__nullable CKCoreDataMigrationProgress)progress
          completion:(CKCoreDataMigrationCompletion)completion;

/**
 * Get the error description
 * @param error: The core data error
 * @return The description for the error
 */
- (nullable NSString *)descriptionForError:(NSError *)error;

/**
 * Destroy the store, and remove the related files
 * @param storeFile: The file name for the store you need to destroy. 
 * @param error: If error occcurred, error return contains the problem for the failure.
 * @return YES if success, NO if not.
 */
- (BOOL)destroyStoreForStoreFile:(NSString *)storeFile
                       withError:(NSError * _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
