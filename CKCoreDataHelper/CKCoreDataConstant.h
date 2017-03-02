//
//  CKCoreDataConstant.h
//  CKCoreDataHelper
//
//  Created by Enix Yu on 28/2/2017.
//  Copyright © 2017 RobotBros. All rights reserved.
//

#ifndef CKCoreDataConstant_h
#define CKCoreDataConstant_h

/**
 * CKCoreDataHelper is going to use CocoaLumberjack lib as logger,
 * But it is not a must. So we are going to define the logging function
 * if CococaLumberjack is not imported in your app.
 */
#ifndef DDLogError
#define DDLogError(frmt, ...)  NSLog(frmt, ##__VA_ARGS__)
#endif

#ifndef DDLogInfo
#define DDLogInfo(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#endif

#ifndef DDLogWarn
#define DDLogWarn(frmt, ...) NSLog(frmt, ##__VA_ARGS__)
#endif

#endif /* CKCoreDataConstant_h */
