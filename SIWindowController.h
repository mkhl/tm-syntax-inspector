//
//  SIWindowController.h
//
//  Copyright (c) 2009  Martin Kühl <purl.org/net/mkhl>
//

#import <Cocoa/Cocoa.h>
#import "TMPluginController.h"

@class SIOutline;

@interface SIWindowController : NSWindowController {
  NSMenuItem *menuItem;
  SIOutline *outline;
}

- (id)initWithPlugInController:(id <TMPlugInController>)controller;

- (NSMenuItem *)createMenuItem;
- (void)installMenuItem;
- (void)uninstallMenuItem;

@end
