//
//  CKCoreDataXMLImporterTests.m
//  CKCoreDataHelper
//
//  Created by Enix Yu on 28/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import "CKCoreDataImporterBase.h"
#import "CKCoreDataXMLImporter.h"

@interface CKCoreDataXMLImporterTests : CKCoreDataImporterBase

@property (nonatomic, strong) CKCoreDataXMLImporter *importer;

@end

@implementation CKCoreDataXMLImporterTests

- (void)setUp {
    [super setUp];
    
    _importer = [[CKCoreDataXMLImporter alloc]
                 initWithCoordinator:self.manager.coordinator
                 entitiesUniqueAttributes:@{@"Product": @"name",
                                            @"Shop": @"name"}];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testXMLImport {
    XCTestExpectation *exp = [self expectationWithDescription:@"Should import success"];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"cn.robotbros.CKCoreDataHelperTests"];
    NSURL *xmlPath = [bundle URLForResource:@"preload_product_withoutrel" withExtension:@"xml"];
    [_importer importDataFrom:xmlPath
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

- (void)testXMLDependencyImport {
    XCTestExpectation *exp1 = [self expectationWithDescription:@"Should import success"];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"cn.robotbros.CKCoreDataHelperTests"];
    
    NSURL *shopXML = [bundle URLForResource:@"preload_shop" withExtension:@"xml"];
    NSURL *productXML = [bundle URLForResource:@"preload_product" withExtension:@"xml"];
    
    [_importer importDataFrom:shopXML
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
    [_importer importDataFrom:productXML
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
