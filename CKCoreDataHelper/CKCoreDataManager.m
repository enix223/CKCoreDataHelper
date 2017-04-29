//
//  CKCoreDataManager.m
//  FoodReminder
//
//  Created by Enix Yu on 27/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import "CKCoreDataManager.h"

//-----------------------------------------------------------------
#pragma MARK - Settings
//-----------------------------------------------------------------

static NSString *const kCKStoreDirName                  = @"Stores";
static NSString *const kCKErrorDomain                   = @"CKCoreDataManagerErrorDomain";
static NSInteger const kCKErrorGetMappingModelErrorCode = -1;


//-----------------------------------------------------------------
#pragma MARK - Extension
//-----------------------------------------------------------------

@interface CKCoreDataManager () <NSXMLParserDelegate>

@property (nonatomic, copy) NSString *storeFileName;
@property (nonatomic, strong, nullable) CKCoreDataMigrationProgress progressCallback;
@property (nonatomic, strong, nullable) CKCoreDataMigrationCompletion completion;

@end

@implementation CKCoreDataManager

//-----------------------------------------------------------------
#pragma MARK - Life cycle
//-----------------------------------------------------------------

+ (instancetype)sharedInstanced
{
    static CKCoreDataManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CKCoreDataManager new];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _model = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
        _coordinator = [[NSPersistentStoreCoordinator alloc]
                        initWithManagedObjectModel:_model];
        _context = [[NSManagedObjectContext alloc]
                    initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_context setPersistentStoreCoordinator:_coordinator];
    }
    return self;
}

- (BOOL)loadStoreWithLightWeightMigration:(BOOL)lightWeightMigration
                                    error:(NSError **)error
{
    if ([_coordinator.persistentStores containsObject:_store]) return YES;
    
    NSDictionary *options = nil;
    if (lightWeightMigration) {
        // Config
        options = @{// automatically migrate to latest version model
                    NSMigratePersistentStoresAutomaticallyOption: @YES,
                    
                    // automatically map the filed to new version
                    NSInferMappingModelAutomaticallyOption: @YES,
                    
                    // Prevent creating Journal
                    NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}
                    };
    } else {
        options = @{NSSQLitePragmasOption: @{@"journal_mode": @"DELETE"}};
    }
    
    NSError *localErr = nil;
    _store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                        configuration:nil
                                                  URL:[self storeURL]
                                              options:options
                                                error:&localErr];
    if (!_store) {
        if (error) *error = localErr;
        return NO;
    }
    
    return YES;
}

- (BOOL)setupCoreDataWithStoreFileName:(NSString *)fileName
                  lightWeightMigration:(BOOL)lightWeightMigration
                                 error:(NSError **)error
{
    _storeFileName = fileName;
    return [self loadStoreWithLightWeightMigration:lightWeightMigration
                                             error:error];
}

- (BOOL)setDefaultDataStoreFromStoreURL:(NSURL *)storeURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:storeURL.path]) {
        return NO;
    }
    
    NSError *error = nil;
    if (![fileManager moveItemAtURL:storeURL
                              toURL:[self storeURL]
                              error:&error]) {
        return NO;
    }
    
    return YES;
}

//-----------------------------------------------------------------
#pragma MARK - Files
//-----------------------------------------------------------------

- (NSString *)applicationDocumentDir
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask,
                                                YES)
            lastObject];
}

- (NSURL *)applicationStoreDir
{
    NSString *docDir = [self applicationDocumentDir];
    NSString *storeDir = [docDir stringByAppendingPathComponent:kCKStoreDirName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // Dir exist or not
    if (![fileManager fileExistsAtPath:storeDir]) {
        [fileManager createDirectoryAtPath:storeDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    
    return [NSURL fileURLWithPath:storeDir];
}

- (NSURL *)storeURL
{
    return [[self applicationStoreDir]
            URLByAppendingPathComponent:_storeFileName];
}

- (BOOL)replaceSourceStore:(NSURL *)sourceStoreURL
      withDestinationStore:(NSURL *)destStoreURL
                     error:(NSError **)error
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager removeItemAtPath:sourceStoreURL.path
                                 error:error]) {
        
        return NO;
    }
    
    if (![fileManager moveItemAtURL:destStoreURL
                              toURL:sourceStoreURL
                              error:error]) {
        return NO;
    }
    
    return YES;
}

//-----------------------------------------------------------------
#pragma MARK - Migration
//-----------------------------------------------------------------

- (BOOL)isMigrationNeededForStore:(NSURL *)storeURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:storeURL.path]) {
        return NO;
    }
    
    NSError *error = nil;
    NSDictionary *sourceMeta = [NSPersistentStoreCoordinator
                                metadataForPersistentStoreOfType:NSSQLiteStoreType
                                URL:storeURL
                                error:&error];
    NSManagedObjectModel *destModel = _coordinator.managedObjectModel;
    
    if ([destModel isConfiguration:nil
       compatibleWithStoreMetadata:sourceMeta]) {
        return NO;
    }
    
    return YES;
}

- (void)migrateStore:(NSURL *)sourceStoreURL
            progress:(__nullable CKCoreDataMigrationProgress)progress
          completion:(CKCoreDataMigrationCompletion)completion
{
    _progressCallback = progress;
    _completion = completion;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

        BOOL success = NO;
        NSError *error = nil;

        // STEP 1. Gather store, destination and mapping model
        NSDictionary *sourceMeta = [NSPersistentStoreCoordinator
                                    metadataForPersistentStoreOfType:NSSQLiteStoreType
                                    URL:sourceStoreURL
                                    error:&error];
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
        
        NSManagedObjectModel *sourceModel = [NSManagedObjectModel
                                             mergedModelFromBundles:[NSBundle allBundles]
                                             forStoreMetadata:sourceMeta];

        NSMappingModel *mappingModel = [NSMappingModel
                                        mappingModelFromBundles:[NSBundle allBundles]
                                        forSourceModel:sourceModel
                                        destinationModel:_model];
        
        // STEP 2. Perform migration
        if (mappingModel) {
            NSMigrationManager *manager = [[NSMigrationManager alloc]
                                           initWithSourceModel:sourceModel
                                           destinationModel:_model];
            
            // Monitor migration process
            [manager addObserver:self
                      forKeyPath:@"migrationProgress"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
            
            // Destination store
            NSURL *destStoreURL = [[self applicationStoreDir]
                                   URLByAppendingPathComponent:@"temp.sqlite"];
            
            success = [manager migrateStoreFromURL:sourceStoreURL
                                              type:NSSQLiteStoreType
                                           options:nil
                                  withMappingModel:mappingModel
                                  toDestinationURL:destStoreURL
                                   destinationType:NSSQLiteStoreType
                                destinationOptions:nil
                                             error:&error];
            if (!success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, error);
                });
            }
            
            // STEP 3. Replace the source store file with dest store file
            if (![self replaceSourceStore:sourceStoreURL
                     withDestinationStore:destStoreURL
                                    error:&error]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO, error);
                });
            }
            
            [manager removeObserver:self forKeyPath:@"migrationProgress"];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        } else {
            error = [NSError
                     errorWithDomain:kCKErrorDomain
                                code:kCKErrorGetMappingModelErrorCode
                            userInfo:@{NSLocalizedDescriptionKey:
                                       NSLocalizedString(@"Failed to get Mapping model", @"")}];
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error);
            });
        }
    });
}

//-----------------------------------------------------------------
#pragma MARK - Data Import
//-----------------------------------------------------------------

- (BOOL)isDefaultDataImportedForStoreWithURL:(NSURL *)storeURL
                                       error:(NSError **)error
{
    NSDictionary *metaData = [NSPersistentStoreCoordinator
                              metadataForPersistentStoreOfType:NSSQLiteStoreType
                              URL:storeURL error:error];
    if (error) {
        return NO;
    }
    
    BOOL imported = [[metaData objectForKey:@"DefaultDataImported"] boolValue];
    return imported;
}

- (void)setDefaultDataAsImportedForStore:(NSPersistentStore *)store
{
    NSMutableDictionary *meta = [NSMutableDictionary
                                 dictionaryWithDictionary:[[store metadata] copy]];
    [meta setObject:@YES forKey:@"DefaultDataImported"];
    [_context.persistentStoreCoordinator setMetadata:meta
                                  forPersistentStore:store];
}

//-----------------------------------------------------------------
#pragma MARK - Misc
//-----------------------------------------------------------------

- (BOOL)saveContextWithError:(NSError **)error
{
    if ([_context hasChanges]) {
        NSError *localError = nil;
        if (![_context save:&localError]) {
            if (error) *error = localError;
            return NO;
        }
    }
    
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"migrationProgress"]) {
        float process = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
        if ( _progressCallback ) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _progressCallback(process);
            });
        }
    }
}

- (NSString *)descriptionForError:(NSError *)error {
    switch (error.code) {
        case 1560:
            return @"NSValidationMultipleErrorsError: Invalid mulitple errors";
            break;
        case 1570:
            return @"NSValidationMissingMandatoryPropertyError: Missing value for mandatory property";
            break;
        case 1580:
            return @"NSValidationRelationshipLacksMinimumCountError: Relationship lack of minimum count";
            break;
        case 1590:
            return @"NSValidationRelationshipExceedsMaximumCountError: Relationship exceed max count";
            break;
        case 1600:
            return @"NSValidationRelationshipDeniedDeleteError: Denied to delete due to relationship restriction";
            break;
        case 1610:
            return @"NSValidationNumberTooLargeError: Validation error, number too large";
            break;
        case 1620:
            return @"NSValidationNumberTooSmallError: Validation error, number too small";
            break;
        case 1630:
            return @"NSValidationDateTooLateError: Validation error, date too late";
            break;
        case 1640:
            return @"NSValidationDateTooSoonError: Validation error, date too soon";
            break;
        case 1650:
            return @"NSValidationInvalidDateError: Invalid date";
            break;
        case 1660:
            return @"NSValidationStringTooLongError: Validation error, string too long";
            break;
        case 1670:
            return @"NSValidationStringTooShortError: Validation error, string too short";
            break;
        case 1680:
            return @"NSValidationStringPatternMatchingError: Validation error, string pattern not match";
            break;
        default:
            return nil;
            break;
    }
}

- (BOOL)destroyStoreForStoreFile:(NSString *)storeFile
                       withError:(NSError **)error
{
    if ([_coordinator.persistentStores count] > 0) {
        if (![_coordinator removePersistentStore:_store error:error]) {
            return NO;
        }
    }
    
    NSURL *storePath = [[self applicationStoreDir] URLByAppendingPathComponent:storeFile];
    if (storePath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager removeItemAtPath:[storePath path] error:error]) {
            return YES;
        }
    }
    
    return NO;
}

@end
