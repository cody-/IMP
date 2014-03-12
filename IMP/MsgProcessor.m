//
//  MsgProcessor.m
//  IMP
//
//  Created by cody on 3/6/14.
//  Copyright (c) 2014 cody. All rights reserved.
//

#import "MsgProcessor.h"
#import <Adium/AIContentControllerProtocol.h>
#import <Adium/AIContentObject.h>
#import <Adium/AIListObject.h>

@interface MsgProcessor()
{
    NSString* scriptDir_;
    NSArray* scripts_;
    dispatch_source_t dispatchSource_;
}

- (void)willReceiveContent:(NSNotification *)notification;
- (NSArray*)loadScriptsFrom:(NSString*)dir;
- (void)startScriptsDirMonitor;
- (void)stopScriptsDirMonitor;
- (NSString*)runScript:(NSString*)script withMsg:(NSString*)msg;

@end

@implementation MsgProcessor
///
- (void)installPlugin
{
    NSString* appSupportDir = [[[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil] path];
    scriptDir_ = [NSString stringWithFormat:@"%@/Adium IMP/scripts", appSupportDir];
    [[NSFileManager defaultManager] createDirectoryAtPath:scriptDir_ withIntermediateDirectories:YES attributes:nil error:nil];

    scripts_ = [self loadScriptsFrom:scriptDir_];
    [self startScriptsDirMonitor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willReceiveContent:) name:Content_WillReceiveContent object:nil];
}

///
- (void)uninstallPlugin
{
    [self stopScriptsDirMonitor];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

///
- (void)willReceiveContent:(NSNotification *)notification
{
    AIContentObject* contentObject = [[notification userInfo] objectForKey:@"Object"];
    NSString* from = contentObject.source.UID;
    NSString* msg = contentObject.messageString;

    if([scripts_ containsObject:from]) {
        NSString* script = [NSString stringWithFormat:@"%@/%@", scriptDir_, from];
        NSString* newMsg = [self runScript:script withMsg:msg];
        contentObject.message = [[NSAttributedString alloc] initWithString:newMsg];
    }
}

///
NSString* readPipe(NSPipe* pipe) {
    return [[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile] encoding: NSUTF8StringEncoding];
}

///
NSString* Quote(NSString* str) {
    return [NSString stringWithFormat:@"\"%@\"", [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]];
}

///
- (NSString*)runScript:(NSString*)script withMsg:(NSString*)msg
{
    NSPipe* outPipe = [NSPipe pipe];
    NSPipe* errPipe = [NSPipe pipe];

    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments:@[@"--login", @"-c", [NSString stringWithFormat: @"%@ %@", Quote(script), Quote(msg)]]];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];
    [task launch];
    [task waitUntilExit];

    NSString* output = readPipe(outPipe);
    NSString* error = readPipe(errPipe);

    return error.length == 0
        ? output
        : [NSString stringWithFormat:@"%@\nMessage:\n%@", error, msg];
}

///
- (NSArray*)loadScriptsFrom:(NSString*)dir
{
    NSMutableArray* scripts = [[NSMutableArray alloc] init];
    NSDirectoryEnumerator* dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:dir];
    for(NSString* file in dirEnum) {
        NSString* script = [NSString stringWithFormat:@"%@/%@", scriptDir_, file];
        if([[NSFileManager defaultManager] isExecutableFileAtPath:script]) {
            [scripts addObject:file];
        } else {
            NSLog(@"IMP: %@ not executable - ignore", file);
        }
    }

    return scripts;
}

///
- (void)startScriptsDirMonitor
{
    int fd = open([scriptDir_ fileSystemRepresentation], O_EVTONLY);
    dispatch_queue_t queue = dispatch_queue_create("Adium IMP scripts dir monitor queue", 0);

    // watch the file descriptor for writes
    dispatchSource_ = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE, queue);

    // call the passed block if the source is modified
    dispatch_source_set_event_handler(dispatchSource_, ^{
        scripts_ = [self loadScriptsFrom:scriptDir_];
    });

    // close the file descriptor when the dispatch source is cancelled
    dispatch_source_set_cancel_handler(dispatchSource_, ^{
        close(fd);
    });

    // at this point the dispatch source is paused, so start watching
    dispatch_resume(dispatchSource_);
}

///
- (void)stopScriptsDirMonitor
{
    dispatch_source_cancel(dispatchSource_);
    dispatchSource_ = nil;
}

@end
