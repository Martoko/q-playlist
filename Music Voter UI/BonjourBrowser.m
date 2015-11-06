//
//  BonjourBrowser.m
//  Music Voter UI
//
//  Created by Martoko on 22/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "BonjourBrowser.h"

@interface BonjourBrowser ()

@property (retain) NSNetServiceBrowser* netServiceBrowser;

@end


@implementation BonjourBrowser

- (id)init
{
    self = [super init];
    if (self) {
        _netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        _netServiceBrowser.delegate = self;
        _foundServers = [[NSMutableArray alloc] init];
        [self.netServiceBrowser searchForServicesOfType:@"_musicvote._tcp."
                                               inDomain:@"local."];
    }
    return self;
}

- (void)dealloc
{
    self.netServiceBrowser.delegate = nil;
}

#pragma mark - NSNetServiceBrowser delegate

-(void) netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [self.foundServers addObject:service];
    
    if (moreComing == NO) {
        [self.delegate serverlistChanged];
    }
}

-(void) netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
    [self.foundServers removeObject:service];

    if (moreComing == NO) {
        [self.delegate serverlistChanged];
    }
}

@end
