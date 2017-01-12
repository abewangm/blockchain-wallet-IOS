//
//  CertificatePinner.m
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//
#import <openssl/x509.h>
#import "CertificatePinner.h"
#import "SessionManager.h"

@implementation CertificatePinner

- (void)pinCertificate
{
    NSURLSession *session = [SessionManager sharedSession];
    NSURL *url = [NSURL URLWithString:DEFAULT_WALLET_SERVER];
    session.sessionDescription = url.host;
    NSURLSessionDataTask *task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // response management code
    }];
    [task resume];
}

-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    
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
    
    NSString *pathToCert = [[NSBundle mainBundle] pathForResource:CERTIFICATE_SERVER_NAME ofType:CERTIFICATE_FILE_TYPE_DER];
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
