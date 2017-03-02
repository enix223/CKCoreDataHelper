//
//  CKCoreDataJSONImporter.m
//  CKCoreDataHelper
//
//  Created by Enix Yu on 28/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import "CKCoreDataJSONImporter.h"

static NSString *const kCKErrorDomain = @"CKCoreDataJSONImporterErrorDomain";
static NSInteger const kCKErrorFailedToReadDataErrorCode = -1;

@interface CKCoreDataJSONImporter ()

/// The entity name for the import operation
@property (nonatomic, copy)   NSString *entityName;

@end

@implementation CKCoreDataJSONImporter

- (void)importDataFrom:(NSURL *)dataURL
             forEntity:(NSString *)entity
            completion:(CKCoreDataImportCompletion)completion
{
    // Run in a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        __block NSError *error = nil;
        __block BOOL flag = YES;
        
        // 1. Read the content
        NSData *jsonData = [NSData dataWithContentsOfURL:dataURL];
        if (jsonData) {
            
            // 2. Convert to JSON dict
            NSArray *json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:0
                                                              error:&error];
            
            [json enumerateObjectsUsingBlock:^(NSDictionary *entry, NSUInteger idx, BOOL * _Nonnull stop) {
                // 3. Insert into current context
                NSString *uniqueAttrName = [self uniqueAttributeNameForEntity:entity];
                NSString *uniqueAttrValue = [entry objectForKey:uniqueAttrName];
                NSManagedObject *newObj = [self insertObjectForEntity:entity
                                                 uniqueAttributeValue:uniqueAttrValue
                                                      attributeValues:entry
                                                            inContext:self.context
                                                                error:&error];
                
                // Notify the caller
                if (!newObj) {
                    if (completion) completion(NO, error);
                    flag = NO;
                    *stop = YES;
                }
            }];
            
            // Successfully insert new objects
            if (flag && completion) {
                NSError *error = nil;
                if ([self saveContextWithError:&error]) {
                    if (completion) completion(YES, nil);
                } else {
                    if (completion) completion(NO, error);
                }
            }
        } else {
            NSError *error = [NSError errorWithDomain:kCKErrorDomain
                                                 code:kCKErrorFailedToReadDataErrorCode
                                             userInfo:nil];
            if (completion) completion(NO, error);
        }
    });
}

- (NSDictionary *)mapAttributes:(NSDictionary *)attributes
                       toEntity:(NSManagedObject *)entity
                          error:(NSError * _Nullable __autoreleasing *)error
{
    __block NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // Map all keys and values in JSON to target entity properties
    [attributes.allKeys
     enumerateObjectsUsingBlock:^(NSString *propertyName, NSUInteger idx, BOOL * stop) {
         NSString *originAttrValue = attributes[propertyName];
         
         // Get the relationship desc from current entity
         NSRelationshipDescription *relDesc = [entity.entity.relationshipsByName
                                               objectForKey:propertyName];
         if (relDesc) {
             NSError *localError = nil;
             
             // Find the corresponding relationship entity
             NSManagedObject *relObj = [self existingObjectInContext:self.context
                                                           forEntity:relDesc.destinationEntity.name
                                            withUniqueAttributeValue:originAttrValue
                                                               error:&localError];
             if (!relObj) {
                 if (error) *error = localError;
             } else {
                 [dict setObject:relObj forKey:propertyName];
             }
         } else {
             // non relationship properties
             [dict setObject:originAttrValue forKey:propertyName];
         }
     }];
    
    return [NSDictionary dictionaryWithDictionary:[dict copy]];
}

@end
