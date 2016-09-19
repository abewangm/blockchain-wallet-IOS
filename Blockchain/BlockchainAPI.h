//
//  BlockchainAPI.h
//  Blockchain
//
//  Created by Ben Reeves on 19/07/2014.
//  Copyright (c) 2014 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BlockchainAPI : NSObject

+(NSDictionary*)resolveAlias:(NSString*)alias;

@end
