/*
 *  OakTextView.h
 *
 */

@protocol OakTextView <NSTextInput>
- (id)xmlRepresentation;
- (void)goToLineNumber:(id)fp8;
- (void)goToColumnNumber:(id)fp8;
- (void)selectToLine:(id)fp8 andColumn:(id)fp12;
@end;
