//
//  LatexParser.h
//  LatexImporter
//
//  Created by Matthias Wiesmann on 22.08.05.
//  Copyright 2005 Matthias Wiesmann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/** This class is a latex parser. 
  * Once initialised the method convertLatex should be called. 
  * Once this is done, the different fields will be filled.
  * Parsing is done using three sets:
  * - copy_commands copy the parameter from the latex input to the output, example: emph 
  * - substitute_commands replace the command by some static string, example: greek letter sequences
  * - custom_commands execute a method with the input as parameter, example: title, author
  * TODO:
  * - handle incomplete (included) latex documents what would be reasonable policy? 
  */ 

@interface LatexParser : NSObject {
    /** the actual encoding used */ 
    NSStringEncoding encoding ; 
    /** Set of commands whose content must be copied */
    NSMutableSet           *copy_commands ; 
    /** Table of commands that need to be susbtitute */
    NSMutableDictionary     *substitute_commands ; 
    /** Talbe of custom command handlers */
    NSMutableDictionary     *custom_commands ; 
    /** Is copying enabled */ 
    BOOL copy_text ; 
    /** Verbose logging */
    BOOL verbose ; 
    
    /** Set of citations */ 
    NSMutableSet            *citations ; 
    
    /** Title of the document */
    NSString         *title ; 
    /** Authors of the document */
    NSString         *authors ; 
    /** Plain text version of document */
    NSString         *full_text ; 
}

- (id) init ; 
- (id) initWithLatexData: (NSData *) data ; 
- (id) initWithLatexData: (NSData *) data commands: (NSDictionary*) commands ; 
- (id) initWithLatexData: (NSData *) data commandName: (NSString *) name commandType: (NSString *) type ;  

- (void) loadLatexData: (const char*) data length: (int) length ; 
- (void) loadLatexData: (NSData *) data ; 
- (void) loadLatexCommands: (NSDictionary *) dictionary ; 

- (void) addHandler: (SEL) selector forCommand: (NSString *) command  ; 

- (NSString *) convertLatex: (const char*) text_data length: (unsigned int) length ;  
- (NSString *) getTitle ; 
- (NSString *) getAuthors ; 
- (NSString *) getFullText ; 
- (NSArray *) getCitations ; 
- (void) setTitle: (id) title ; 
- (void) setAuthors: (id) title ; 


@end
