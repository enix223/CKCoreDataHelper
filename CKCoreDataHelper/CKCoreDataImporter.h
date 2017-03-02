//
//  CKCoreDataImporter.h
//  CKCoreDataHelper
//
//  Created by Enix Yu on 28/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CKCoreDataImportCompletion)(BOOL success, NSError * _Nullable error);

@protocol CKCoreDataImportable <NSObject>

@required

/**
 * Import data from given data source
 * @param dataURL:    The URL for the data source you want to import
 * @param entity:     The target entity name for the data import operation 
 * @param completion: A completion callback when dat import process is done.
 *                    If no error occurred, `success` will be equal to TRUE;
 *                    If error occurred, `success` will be equal to FALSE, and the `error`
 *                    will hold the failure reason.
 * @return None
 */
- (void)importDataFrom:(NSURL *)dataURL
             forEntity:(NSString *)entity
            completion:(CKCoreDataImportCompletion)completion;

/**
 * Map the data source attribute dictionary to target entity property dictionary
 * @param attributes: The data source attributes dict
 * @param entity: The target Entity to be mapped.
 * @param error: If error occurred, upon return contains an NSError that describe the problem
 */
- (NSDictionary *)mapAttributes:(NSDictionary *)attributes
                       toEntity:(NSManagedObject *)entity
                          error:(NSError **)error;

@end

@interface CKCoreDataImporter : NSObject

/** 
 * The manage object context for import operation.
 * It is usually not the same as the main thread context, 
 * to prevent blocking the main thead context.
 */
@property (nonatomic, strong) NSManagedObjectContext *context;


/**
 * Initialize data importer
 * @param coordinator: The persistent store coordinator
 * @param attributes: The entities's unique attribute mapping
 * @return An instance of data importer
 */
- (instancetype)initWithCoordinator:(NSPersistentStoreCoordinator *)coordinator
           entitiesUniqueAttributes:(NSDictionary *)attributes NS_DESIGNATED_INITIALIZER;

/**
 * Get unique attribute name for given entity
 * @param entity:   The entity name
 * @return:         The unique attribute name for given entity
 */
- (NSString *)uniqueAttributeNameForEntity:(NSString *)entity;

/**
 * Retrieve a managed object for given entity with unique attribute value
 * If no record found, return nil instead.
 * @param context:          The managed object context for record checking
 * @param entity:           The entity name for existence checking
 * @param uniqueAttrValue:  The unique attribute value
 * @param error:            If error occurred, upon return contains an NSError that describe the problem
 * @return:                 Return corresponding record for the entity if found,
 *                          return nil if not.
 */
- (NSManagedObject *)existingObjectInContext:(NSManagedObjectContext *)context
                                   forEntity:(NSString *)entity
                    withUniqueAttributeValue:(NSString *)uniqueAttrValue
                                       error:(NSError ** _Nullable)error;
/**
 * Insert a managed object into given context. If record exist, return it directly.
 * @param entity:           The entity name
 * @param uniqueAttrValue:  The unique attribute name
 * @param attributeValues:  A dict for the entity attribute values
 * @param context:          The managed object context for the insert operation
 * @return:                 New inserted object, nil if error occurred
 * @param error:            If error occurred, upon return contains an NSError that describe the problem
 */
- (NSManagedObject *)insertObjectForEntity:(NSString *)entity
                      uniqueAttributeValue:(NSString *)uniqueAttrValue
                           attributeValues:(NSDictionary *)attributeValues
                                 inContext:(NSManagedObjectContext *)context
                                     error:(NSError ** _Nullable)error;

/**
 * Save changes to given context
 * @param error:   An error pointer for the context saving error.
 * @return:        YES if save success, NO if not.
 */
- (BOOL)saveContextWithError:(NSError ** _Nullable)error;

- (NSString *)getPropertyTypeForEntity:(NSManagedObject *)entity
                      withPropertyName:(NSString *)propertyName;

@end

NS_ASSUME_NONNULL_END
