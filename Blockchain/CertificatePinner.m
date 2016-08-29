//
//  CertificatePinner.m
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//
#import <openssl/x509.h>
#import "CertificatePinner.h"
@interface CertificatePinner()
@property (nonatomic) NSURLSession *session;
@end
@implementation CertificatePinner

- (void)pinCertificate
{
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    self.session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:[NSURL URLWithString:DEFAULT_WALLET_SERVER] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // response management code
    }];
    [task resume];
    [self.session finishTasksAndInvalidate];
}

-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_ENABLE_CERTIFICATE_PINNING]) {
        // Get remote certificate
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        
        // Set SSL policies for domain name check
        NSMutableArray *policies = [NSMutableArray array];
        [policies addObject:(__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)challenge.protectionSpace.host)];
        SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
        
        // Evaluate server certificate
        SecTrustResultType result;
        SecTrustEvaluate(serverTrust, &result);
        BOOL certificateIsValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
        
        // Get local and remote cert data
        NSData *remoteCertificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
        NSString *resource;
        if ([session.sessionDescription isEqualToString:HOST_NAME_MERCHANT]) {
            resource = @"merchant-directory-info";
        } else if ([session.sessionDescription isEqualToString:HOST_NAME_API]) {
            resource = @"api-info";
        } else {
            resource = @"blockchain";
        }
        
        NSString *pathToCert = [[NSBundle mainBundle] pathForResource:resource ofType:@"der"];
        NSData *localCertificate = [NSData dataWithContentsOfFile:pathToCert];
        
        // The pinnning check
        
        NSString *remoteKeyString = [self getPublicKeyStringFromData:remoteCertificateData];
        NSString *localKeyString = [self getPublicKeyStringFromData:localCertificate];
        
        if ([remoteKeyString isEqualToString: localKeyString] && certificateIsValid) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            [self.delegate failedToValidateCertificate];
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, NULL);
        }
    } else {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    }
}

- (NSString *)getPublicKeyStringFromData:(NSData *)data
{
    const unsigned char *certificateDataBytes = (const unsigned char *)[data bytes];
    X509 *certificateX509 = d2i_X509(NULL, &certificateDataBytes, [data length]);
    ASN1_BIT_STRING *pubKey2 = X509_get0_pubkey_bitstr(certificateX509);
    
    NSString *publicKeyString = [[NSString alloc] init];
    
    for (int i = 0; i < pubKey2->length; i++)
    {
        NSString *aString = [NSString stringWithFormat:@"%02x", pubKey2->data[i]];
        publicKeyString = [publicKeyString stringByAppendingString:aString];
    }
    
    X509_free(certificateX509);
    
    return publicKeyString;
}

@end
