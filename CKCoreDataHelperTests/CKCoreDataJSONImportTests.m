//
//  CKCoreDataJSONImportTests.m
//  CKCoreDataHelper
//
//  Created by Enix Yu on 2/3/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CKCoreDataImporterBase.h"

#import "CKCoreDataManager.h"
#import "CKCoreDataJSONImporter.h"

@interface CKCoreDataJSONImportTests : CKCoreDataImporterBase

@property (nonatomic, strong) CKCoreDataJSONImporter *importer;

@end

@implementation CKCoreDataJSONImportTests

- (void)setUp {
    [super setUp];
    
    _importer = [[CKCoreDataJSONImporter alloc]
                 initWithCoordinator:self.manager.coordinator
                 entitiesUniqueAttributes:@{@"Product": @"name",
                                            @"Shop": @"name"}];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testJSONImport {
    XCTestExpectation *exp = [self expectationWithDescription:@"Should import success"];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"cn.robotbros.CKCoreDataHelperTests"];
    NSURL *path = [bundle URLForResource:@"preload_product_withoutrel" withExtension:@"json"];

    [_importer importDataFrom:path
                    forEntity:@"Product"
                   completion:^(BOOL success, NSError * _Nullable error) {
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       [exp fulfill];
                   }];
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertTrue(NO, @"Import timeout");
        }
    }];
    
    [self assertProductsLoaded];
}

- (void)testJSONDependencyImport {
    XCTestExpectation *exp1 = [self expectationWithDescription:@"Should import success"];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"cn.robotbros.CKCoreDataHelperTests"];
    
    NSURL *shop = [bundle URLForResource:@"preload_shop" withExtension:@"json"];
    NSURL *product = [bundle URLForResource:@"preload_product" withExtension:@"json"];
    
    [_importer importDataFrom:shop
                    forEntity:@"Shop"
                   completion:^(BOOL success, NSError * _Nullable error) {
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       [exp1 fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertTrue(NO, @"Import timeout");
        }
    }];
    
    [self assertShopsLoaded];
    
    XCTestExpectation *exp2 = [self expectationWithDescription:@"Should import success"];
    [_importer importDataFrom:product
                    forEntity:@"Product"
                   completion:^(BOOL success, NSError * _Nullable error) {
                       XCTAssertTrue(success);
                       XCTAssertNil(error);
                       [exp2 fulfill];
                   }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:^(NSError * _Nullable error) {
        if (error) {
            XCTAssertTrue(NO, @"Import timeout");
        }
    }];
    
    [self assertProductsLoaded];
    [self assertRelationshipExist];
}

@end
