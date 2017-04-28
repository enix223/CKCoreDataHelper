//
//  CKCoreDataImporter.m
//  CKCoreDataHelper
//
//  Created by Enix Yu on 28/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>

#import "CKCoreDataImporter.h"
#import "NSDate+ConventKit.h"

static NSString *const kCKErrorDomain = @"CKCoreDataImporterErrorDomain";
static NSInteger const kCKErrorFailedInsertErrorCode = -1;

//-----------------------------------------------------------------
#pragma MARK - Extention
//-----------------------------------------------------------------

@interface CKCoreDataImporter () <CKCoreDataImportable>

/// Entity unique attribute name mapping
@property (nonatomic, strong) NSDictionary *entitiesUniqueAttributes;

@end

@implementation CKCoreDataImporter

//-----------------------------------------------------------------
#pragma MARK - Life cycle
//-----------------------------------------------------------------

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Must use -initWithCoordinator: instead"
                                 userInfo:nil];
}
#pragma clang diagnostic pop

- (instancetype)initWithCoordinator:(NSPersistentStoreCoordinator *)coordinator
           entitiesUniqueAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (self) {
        _entitiesUniqueAttributes = attributes;
        _context = [[NSManagedObjectContext alloc]
                    initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_context performBlockAndWait:^{
            _context.persistentStoreCoordinator = coordinator;
            _context.undoManager = nil;
        }];
    }
    return self;
}

//-----------------------------------------------------------------
#pragma MARK - Record Query/insertion
//-----------------------------------------------------------------

/**
 * Get unique attribute name for given entity
 */
- (NSString *)uniqueAttributeNameForEntity:(NSString *)entity
{
    return [_entitiesUniqueAttributes objectForKey:entity];
}

/**
 * Retrieve a managed object for given entity with unique attribute value
 * If no record found, return nil instead
 */
- (NSManagedObject *)existingObjectInContext:(NSManagedObjectContext *)context
                                   forEntity:(NSString *)entity
                    withUniqueAttributeValue:(NSString *)uniqueAttrValue
                                       error:(NSError **)error
{
    NSString *uniqueAttributeName = [self uniqueAttributeNameForEntity:entity];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K == %@",
                         uniqueAttributeName, uniqueAttrValue];
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:entity];
    [req setPredicate:pred];
    [req setFetchLimit:1];
    
    NSArray *result = [context executeFetchRequest:req error:error];
    return [result lastObject];
}

/**
 * Insert a managed object into given context. 
 * If record exist, return it directly.
 */
- (NSManagedObject *)insertObjectForEntity:(NSString *)entity
                      uniqueAttributeValue:(NSString *)uniqueAttrValue
                           attributeValues:(NSDictionary *)attributeValues
                                 inContext:(NSManagedObjectContext *)context
                                     error:(NSError **)error
{
    NSString *uniqueAttrName = [self uniqueAttributeNameForEntity:entity];
    if ([uniqueAttrName length] > 0) {
        NSManagedObject *obj = [self existingObjectInContext:context
                                                   forEntity:entity
                                    withUniqueAttributeValue:uniqueAttrValue
                                                       error:error];
        if (obj) {
            // Object exist
            return obj;
        } else {
            NSManagedObject *newObj = [NSEntityDescription insertNewObjectForEntityForName:entity
                                                                    inManagedObjectContext:context];
            @try {
                NSDictionary *mapAttrs = [self mapAttributes:attributeValues
                                                    toEntity:newObj
                                                       error:error];
                
                [newObj setValuesForKeysWithDictionary:mapAttrs];
            } @catch (NSException *exception) {
                if (error) {
                    *error = [NSError errorWithDomain:kCKErrorDomain
                                                 code:kCKErrorFailedInsertErrorCode
                                             userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
                }
                return nil;
            }

            return newObj;
        }
    } else {
        return nil;
    }
}

- (BOOL)saveContextWithError:(NSError **)error
{
    if ([_context hasChanges]) {
        if (![_context save:error]) {
            return NO;
        }
    }
    return YES;
}

#pragma MARK - CKCoreDataImportable

- (void)importDataFrom:(NSURL *)dataURL
             forEntity:(NSString *)entity
            completion:(CKCoreDataImportCompletion)completion {
    @throw [NSException exceptionWithName:@"Not implement"
                                   reason:@"Should be implement by subclass"
                                 userInfo:nil];
}

- (NSDictionary *)mapAttributes:(NSDictionary *)attributes
                       toEntity:(NSManagedObject *)entity
                          error:(NSError * _Nullable __autoreleasing *)error {
    @throw [NSException exceptionWithName:@"Not implement"
                                   reason:@"Should be implement by subclass"
                                 userInfo:nil];
}

- (NSString *)getPropertyTypeForEntity:(NSManagedObject *)entity
                      withPropertyName:(NSString *)propertyName
{
    Class entityClass = [entity class];
    unsigned int propCount = 0;
    objc_property_t *properties = class_copyPropertyList(entityClass, &propCount);
    const char *propertyNameStr = [propertyName cStringUsingEncoding:[NSString defaultCStringEncoding]];
    
    for (int i = 0; i < propCount; i ++) {
        objc_property_t prop = properties[i];
        const char *propNameStr = property_getName(prop);
        if (strcmp(propNameStr, propertyNameStr) == 0) {
            NSString *propTypeName = [self getPropertyTypeForProperty:prop];
            return propTypeName;
        }
    }
    
    return nil;
}

- (NSString *)getPropertyTypeForProperty:(objc_property_t)property {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T') {
            if (strlen(attribute) <= 4) {
                break;
            }
            
            // Attribute style: "T@\"NSString\""
            unsigned long len = strlen(attribute);
            char temp[len - 4];
            memcpy(temp, attribute + 3, len - 4);
            temp[strlen(attribute) - 4] = '\0';
            
            NSString *typeStr = [NSString stringWithCString:temp
                                                   encoding:[NSString defaultCStringEncoding]];
            return typeStr;
        }
    }
    
    return nil;
}

@end;
