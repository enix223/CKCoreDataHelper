//
//  CKCoreDataImporterBase.m
//  CKCoreDataHelper
//
//  Created by Enix Yu on 2/3/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import "CKCoreDataImporterBase.h"
#import "CKCoreDataManager.h"
#import "CKCoreDataXMLImporter.h"

//// Entities
#import "Shop.h"
#import "Product.h"
#import "Shop+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"

static NSString * const kStoreFileName = @"test.sqlite";

@implementation CKCoreDataImporterBase

- (void)setUp {
    [super setUp];
    
    // Setup CoreData
    _manager = [CKCoreDataManager sharedInstanced];
    
    // Clear the data
    [_manager destroyStoreForStoreFile:kStoreFileName withError:nil];
    
    [_manager setupCoreDataWithStoreFileName:kStoreFileName
                        lightWeightMigration:YES
                                       error:nil];
}

- (void)tearDown {
    [super tearDown];
}

- (void)assertProductsLoaded {
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Product"];
    NSError *error = nil;
    NSArray *results = [self.manager.context executeFetchRequest:req error:&error];
    XCTAssertNil(error);
    XCTAssertEqual([results count], 3);
}

- (void)assertShopsLoaded {
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Shop"];
    NSError *error = nil;
    NSArray *results = [self.manager.context executeFetchRequest:req error:&error];
    XCTAssertNil(error);
    XCTAssertEqual([results count], 3);
}

- (void)assertRelationshipExist {
    NSFetchRequest *req = [NSFetchRequest fetchRequestWithEntityName:@"Product"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"name = %@", @"Cloth"];
    req.predicate = pred;
    req.fetchLimit = 1;
    NSError *error = nil;
    NSArray *results = [self.manager.context executeFetchRequest:req error:&error];
    Product *product = [results firstObject];
    XCTAssertNotNil(product.shop);
    
    req = [NSFetchRequest fetchRequestWithEntityName:@"Shop"];
    pred = [NSPredicate predicateWithFormat:@"name = %@", @"Walmart"];
    req.predicate = pred;
    req.fetchLimit = 1;
    results = [self.manager.context executeFetchRequest:req error:&error];
    Shop *shop = [results firstObject];
    XCTAssertNotNil(shop.products);
    
    XCTAssertTrue([product.shop.name isEqualToString:shop.name],
                  @"Product Shop name %@ not equal to shop name %@",
                  product.shop.name, shop.name);
}

@end
