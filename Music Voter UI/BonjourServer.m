//
//  BonjourServer.m
//  Music Voter UI
//
//  Created by Martoko on 19/10/15.
//  Copyright © 2015 Mathias & Magnus. All rights reserved.
//

#import "BonjourServer.h"

@interface BonjourServer ()

@property NSNetService* netService;

@end

@implementation BonjourServer

- (instancetype)init
{
    NSString* name = [UIDevice currentDevice].name;
    return [self initWithName:name];
}

- (id)initWithName: (NSString*)name
{
    self = [super init];
    
    if (self) {
        _published = false;
        _netService = [[NSNetService alloc] initWithDomain:@"local" type:@"_musicvote._tcp." name:name];
        _netService.includesPeerToPeer = true;
        [_netService setDelegate:self];
    }
    
    return self;
}

- (void)dealloc
{
    [self.netService setDelegate:nil];
    [self.netService stop];
}

- (void) publish {
    [self.netService publishWithOptions:NSNetServiceListenForConnections];
}

-(NSString*) getName {
    return self.netService.name;
}


#pragma mark - NSNetServiceDelegate functions
- (void)netServiceWillPublish:(NSNetService *)sender {
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    self.published = true;
    [self.delegate bonjourServerDidPublish];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
}

- (void)netServiceDidStop:(NSNetService *)sender {
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    // The comment below was in the apple example code
    // I trust that it is still relevant
    /* Due to a bug <rdar://problem/15626440>, this method is called on some unspecified queue rather than the queue associated with the net service (which in this case is the main queue).  Work around this by bouncing to the main queue.*/
    __unsafe_unretained BonjourServer * weakSelf = self;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        Connection *newClient = [[Connection alloc] initWithInputStream:inputStream AndOutputStream:outputStream];
        
        [weakSelf.delegate connectionEstablished:newClient];
    }];
}

@end
