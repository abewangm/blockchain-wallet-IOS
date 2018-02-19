//
//  SharedSessionDelegate.m
//  Blockchain
//
//  Created by kevinwu on 6/12/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SharedSessionDelegate.h"

@interface SharedSessionDelegate ()
@property (nonatomic) CertificatePinner *certificatePinner;
@end

@implementation SharedSessionDelegate

- (id)initWithCertificatePinner:(CertificatePinner *)certificatePinner
{
    if (self = [super init]) {
        self.certificatePinner = certificatePinner;
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    DLog(@"Shared session received challenge with host: %@", challenge.protectionSpace.host);

    if ([challenge.protectionSpace.host isEqualToString:URL_API_COINIFY] ||
        [challenge.protectionSpace.host isEqualToString:URL_API_SFOX] ||
        [challenge.protectionSpace.host isEqualToString:URL_API_ISIGNTHIS] ||
        [challenge.protectionSpace.host isEqualToString:URL_QUOTES_SFOX] ||
        [challenge.protectionSpace.host isEqualToString:URL_KYC_SFOX] ||
        [challenge.protectionSpace.host isEqualToString:URL_SHAPESHIFT] ||
        !self.certificatePinner) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    } else {
        [self.certificatePinner didReceiveChallenge:challenge completionHandler:completionHandler];
    }
}

@end
