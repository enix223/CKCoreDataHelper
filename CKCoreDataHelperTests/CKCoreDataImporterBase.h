//
//  CKCoreDataImporterBase.h
//  CKCoreDataHelper
//
//  Created by Enix Yu on 2/3/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CKCoreDataManager.h"

//// Entities
#import "Shop.h"
#import "Product.h"
#import "Shop+CoreDataProperties.h"
#import "Product+CoreDataProperties.h"

@interface CKCoreDataImporterBase : XCTestCase

@property (nonatomic, strong) CKCoreDataManager *manager;

- (void)assertProductsLoaded;

- (void)assertShopsLoaded;

- (void)assertRelationshipExist;

@end
