//
//  SIOutline.h
//
//  Copyright (c) 2009  Martin Kühl <purl.org/net/mkhl>
//

#import <Cocoa/Cocoa.h>
#import "OakStatusBar.h"
#import "OakTextView.h"

@interface SIOutline : NSObject {
  IBOutlet NSTreeController *tree;
  IBOutlet NSOutlineView *view;
  IBOutlet NSWindow *window;
  // TextMate UI Elements
  NSView <OakTextView> *textView;
  NSView <OakStatusBar> *statusBar;
  // The XML representation of the current Document
  NSXMLDocument *xml_;
  // Range of each Scope (identified by XPath)
  NSDictionary *scopeRanges_;
  // Character Offset of each Line
  NSArray *lineOffsets_;
 @private
  // Update in progress; ignore XML and selection changes
  BOOL updating_;
  // "Caches" for the last XML representation and caret position
  uint lastXMLHash_;
  uint lastLineNumber_;
  uint lastColumnNumber_;
  // NSXMLParser State
  NSXMLElement *rootElement_;
  NSXMLElement *currentElement_;
}

- (NSWindow *)window;
- (void)setXml:(NSXMLDocument *)newXml;
- (NSXMLDocument *)xml;
- (void)setScopeRanges:(NSDictionary *)newScopes;
- (NSDictionary *)scopeRanges;
- (void)setLineOffsets:(NSArray *)newLines;
- (NSArray *)lineOffsets;

- (void)update;
- (void)filterXML;
- (void)updateXML;
- (void)updateScopes;
- (void)updateLines;

- (NSArray *)coordinatesForOffset:(uint)offset;
- (void)selectRange:(NSRange)range;

- (NSXMLNode *)nodeForOffset:(uint)offset;
- (NSIndexPath *)indexPathForNode:(NSXMLNode *)node;

@end
