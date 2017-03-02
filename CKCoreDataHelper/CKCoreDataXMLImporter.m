//
//  CKCoreDataXMLImporter.m
//  CKCoreDataHelper
//
//  Created by Enix Yu on 28/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <objc/objc-runtime.h>
#import <CoreData/CoreData.h>

#import "CKCoreDataXMLImporter.h"
#import "NSDate+ConventKit.h"

@interface CKCoreDataXMLImporter () <NSXMLParserDelegate>

/// Callback when import is done
@property (nonatomic, strong) CKCoreDataImportCompletion completion;

/// The entity name for the import operation
@property (nonatomic, copy)   NSString *entityName;

@end

@implementation CKCoreDataXMLImporter

- (void)importDataFrom:(NSURL *)dataURL
             forEntity:(NSString *)entity
            completion:(CKCoreDataImportCompletion)completion
{
    _completion = completion;
    _entityName = entity;
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:dataURL];
    parser.delegate = self;
    [parser parse];
}

//-----------------------------------------------------------------
#pragma MARK - NSXMLParser delegate
//-----------------------------------------------------------------

- (void)    parser:(NSXMLParser *)parser
parseErrorOccurred:(NSError *)parseError
{
    DDLogError(@"Error occurred when parsing XML. Reason: %@",
               [parseError localizedDescription]);
    
    if (parseError.code != NSXMLParserDelegateAbortedParseError) {
        if (_completion) {
            _completion(NO, parseError);
            _completion = nil;
        }
    }
}

- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
     attributes:(NSDictionary<NSString *,NSString *> *)attributeDict
{
    if ([_entityName isEqualToString:elementName]) {
        NSError *error = nil;
        
        NSString *uniqueValue = [attributeDict objectForKey:[self uniqueAttributeNameForEntity:_entityName]];
        [self insertObjectForEntity:_entityName
               uniqueAttributeValue:uniqueValue
                    attributeValues:attributeDict
                          inContext:self.context
                              error:&error];
        
        if ( error ) {
            [parser abortParsing];
            if (_completion) {
                _completion(NO, error);
                _completion = nil;
            }
            
        }
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    NSError *error = nil;
    if ([self saveContextWithError:&error]) {
        if (_completion) _completion(YES, nil);
    } else {
        if (_completion) _completion(NO, error);
    }
    _completion = nil;
}

/**
 * Insert a managed object into given context only populating the unique attribute value.
 *
 * @param entity:           The entity name
 * @param targetAttr:       The entity attribute name
 * @param sourceXMLAttr:    The corresponding XML attribute value for given attribute name
 * @param attrDict:         The entity attributes name and values dictionary
 * @param context:          The managed object context for the insert operation
 * @return:                 New inserted object, nil if error occurred
 */
- (NSManagedObject *)insertBasicObjectForEntity:(NSString *)entity
                                targetAttribute:(NSString *)targetAttr
                             sourceXMLAttribute:(NSString *)sourceXMLAttr
                                  attributeDict:(NSDictionary *)attrDict
                                        context:(NSManagedObjectContext *)context
                                          error:(NSError **)error
{
    NSArray *attributes = @[targetAttr];
    NSArray *values = @[[attrDict valueForKey:sourceXMLAttr]];
    NSDictionary *attrValues = @{attributes: values};
    
    return [self insertObjectForEntity:entity
                  uniqueAttributeValue:[attrDict valueForKey:sourceXMLAttr]
                       attributeValues:attrValues
                             inContext:context
                                 error:error];
}

- (NSDictionary *)mapAttributes:(NSDictionary *)attributes
                       toEntity:(NSManagedObject *)entity
                          error:(NSError **)error
{
    __block NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    // Map all keys and values in XML to target entity properties
    [attributes.allKeys
     enumerateObjectsUsingBlock:^(NSString *propertyName, NSUInteger idx, BOOL * stop) {
         NSString *originAttrValue = attributes[propertyName];
         NSString *propTypeName = [self getPropertyTypeForEntity:entity
                                                withPropertyName:propertyName];
         
         if ([propTypeName isEqualToString:@"NSNumber"])
         {
             [dict setObject:@([originAttrValue integerValue]) forKey:propertyName];
         } else if ([propTypeName isEqualToString:@"NSString"])
         {
             [dict setObject:originAttrValue forKey:propertyName];
         } else if ([propTypeName isEqualToString:@"NSDecimalNumber"])
         {
             [dict setObject:[NSDecimalNumber decimalNumberWithString:originAttrValue]
                      forKey:propertyName];
         } else if ([propTypeName isEqualToString:@"NSString"])
         {
             [dict setObject:originAttrValue forKey:propertyName];
         } else if ([propTypeName isEqualToString:@"NSDate"])
         {
             [dict setObject:[NSDate dateFromString:originAttrValue]
                      forKey:propertyName];
         } else
         {
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
                     DDLogWarn(@"Failed to map attribute %@", propertyName);
                     if (error) *error = localError;
                 } else {
                     // Set the inverse relationship if exist
                     NSString *inverseRelName = [[relDesc inverseRelationship] name];
                     if ([inverseRelName length] > 0) {
                         if (relDesc.inverseRelationship.isToMany) {
                             // To-Many relationship
                             NSString *selectorName = [NSString stringWithFormat:@"add%@Object:",
                                                       [inverseRelName capitalizedString]];
                             SEL addRelSelector = NSSelectorFromString(selectorName);
                             if ([relObj respondsToSelector:addRelSelector]) {
                                 IMP addRelImp = [relObj methodForSelector:addRelSelector];
                                 void (*addRelFunc)(id, SEL, NSManagedObject *) = (void *)addRelImp;
                                 addRelFunc(relObj, addRelSelector, entity);
                             }
                         } else {
                             // To-One relationship
                             [entity setValue:relObj forKey:inverseRelName];
                         }
                     }
                     [dict setObject:relObj forKey:propertyName];
                 }
             }
         }
     }];
    
    return [NSDictionary dictionaryWithDictionary:[dict copy]];
}

@end
