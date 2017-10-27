//
//  SharedSessionDelegate.h
//  Blockchain
//
//  Created by kevinwu on 6/12/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CertificatePinner.h"

@interface SharedSessionDelegate : NSObject <NSURLSessionDelegate>
- (id)initWithCertificatePinner:(CertificatePinner *)certificatePinner;
@end
