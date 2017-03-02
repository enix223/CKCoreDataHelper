# CKCoreDataHelper
An implementation of Core Data Helper origin from Textbook: 《Learning Core Data for iOS》.

## Installation:

### Pod

```ruby
pod 'CKCoreDataHelper'
```

## Usage:

### Core Data Setup

```objc
// Your database file name
NSString *storeFileName = @"test.sqlite";

// Initialized a core data manager
CKCoreDataManager *manager = [CKCoreDataManager sharedInstanced];

// Setup core data manager with given store file
NSError *error;
BOOL flag = [manager setupCoreDataWithStoreFileName:storeFileName // Store file name
                               lightWeightMigration:YES           // enable lightweight data migration
                                              error:&error];      // get the error if init failed
```

### Import data

There are two importer you can use to import data into persistent store. One for XML format, another for JSON format.

#### XML

```objc
NSURL *productXML = [bundle URLForResource:@"preload_product" withExtension:@"xml"];
    
[_importer importDataFrom:shopXML                                         // XML URL Path
                forEntity:@"Shop"                                         // The name for the Entity you need to import to
               completion:^(BOOL success, NSError * _Nullable error) {    // A callback when import finished.
                   XCTAssertTrue(success);
                   XCTAssertNil(error);
               }];
```

### JSON
```objc
NSURL *path = [bundle URLForResource:@"preload_product_withoutrel" withExtension:@"json"];

[_importer importDataFrom:path
                forEntity:@"Product"
               completion:^(BOOL success, NSError * _Nullable error) {
                   XCTAssertTrue(success);
                   XCTAssertNil(error);
               }];
```
