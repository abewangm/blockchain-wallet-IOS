//
//  CertificatePinner.h
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol CertificatePinnerDelegate
- (void)failedToValidateCertificate;
@end

@interface CertificatePinner : NSObject <NSURLSessionDelegate>
@property (nonatomic) id <CertificatePinnerDelegate> delegate;
- (void)pinCertificate;
- (void)respondToChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(nullable void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler;
@end
