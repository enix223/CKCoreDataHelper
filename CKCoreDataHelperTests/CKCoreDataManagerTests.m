//
//  CKCoreDataManagerTests.m
//  CKCoreDataHelper
//
//  Created by Enix Yu on 1/3/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CKCoreDataManager.h"

//// Entities
#import "Shop.h"
#import "Product.h"
#import "Shop+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"

static NSString * const kStoreFileName = @"test.sqlite";

@interface CKCoreDataManagerTests : XCTestCase

@property (nonatomic, strong) CKCoreDataManager *manager;

@end

@implementation CKCoreDataManagerTests

- (void)setUp
{
    [super setUp];
    
    _manager = [CKCoreDataManager sharedInstanced];
    [_manager setupCoreDataWithStoreFileName:kStoreFileName lightWeightMigration:NO error:nil];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testStoreCreate
{
    // create
    NSString *storeFileName = @"temp.sqlite";
    CKCoreDataManager *manager = [CKCoreDataManager sharedInstanced];
    NSError *error;
    BOOL flag = [manager setupCoreDataWithStoreFileName:storeFileName
                                   lightWeightMigration:YES
                                                  error:&error];
    XCTAssertTrue(flag);
    XCTAssertNil(error);
}

- (void)testItemEntity
{
    Product *p = [NSEntityDescription insertNewObjectForEntityForName:@"Product"
                                               inManagedObjectContext:_manager.context];
    p.name = @"Cloth";
    p.price = [NSDecimalNumber decimalNumberWithString:@"12"];
    
    NSError *error = nil;
    BOOL flag = [_manager saveContextWithError:&error];
    
    XCTAssertTrue(flag);
    XCTAssertNil(error);
}

- (void)testMigrationNeeded
{
    BOOL flag = [_manager isMigrationNeededForStore:_manager.storeURL];
    XCTAssertFalse(flag);
}

@end
