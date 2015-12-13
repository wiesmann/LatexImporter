//
//  LatexParser.m
//  LatexImporter
//
//  Created by Matthias Wiesmann on 22.08.05.
//  Copyright 2005 Matthias Wiesmann. All rights reserved.
//

#import "LatexParser.h"

const int initial_command_set = 256 ; 
const int command_buffer_size = 256 ; 
const char command_end[] = "}" ;
const char title_command[] = "\\title{" ;
const char authors_command[] = "\\author{" ;
const char full_text_start[] = "\\begin{document}" ;
const char full_text_end[]   = "\\end{document}" ;

/** Checks if a character is considered as punctuation by Latex 
  */

int islatexpunct(char c) {
    switch (c) {
	case '.':
	case ',':
	case ';':
	case ':':
	case '?': 
	case '!':
	case '(':
	case ')':
	    return 1 ; 
	default:
	    return 0 ; 
    } /* switch */ 
}

@implementation LatexParser

/** Initialisation method 
  * This method links in some basic functionality 
  * - creates some basic substitution commands for escaped characters
  * - creates some handlers for the commands with meta-data: title, author and cite. 
  */ 

- (id) init {
    self = [super init] ; 
    encoding =  NSISOLatin1StringEncoding ; 
    copy_text = TRUE ; 
    verbose = FALSE ; 
    copy_commands = [NSMutableSet setWithCapacity: initial_command_set] ; 
    [copy_commands retain] ; 
    substitute_commands = [NSMutableDictionary dictionaryWithCapacity: initial_command_set] ;
    [substitute_commands retain] ; 
    [substitute_commands setObject: @"$" forKey: @"$"] ; // Replace \$ by $ 
    [substitute_commands setObject: @"[" forKey: @"["] ; // Replace \[ by [
    [substitute_commands setObject: @"]" forKey: @"]"] ; // Replace \] by ]
    custom_commands = [NSMutableDictionary dictionaryWithCapacity: 4] ;
    [custom_commands retain] ; 
    [self addHandler: @selector(setTitle:) forCommand: @"title"] ; 
    [self addHandler: @selector(setAuthors:) forCommand: @"author"] ; 
    [self addHandler: @selector(parsePackages:) forCommand: @"usepackage"] ; 
    [self addHandler: @selector(parseCitation:) forCommand: @"cite"] ; 
    citations = [NSMutableSet setWithCapacity: 100] ; 
    [citations retain] ; 
    return self ; 
} // init

- (void) dealloc {
    [title release] ; 
    [authors release] ; 
    [full_text release] ; 
    [copy_commands release] ; 
    [substitute_commands release] ; 
    [custom_commands release] ; 
    [citations release] ; 
    [super dealloc] ;
} 

/** Adds a method to handle a give command
  */

- (void) addHandler: (SEL) selector forCommand: (NSString *) command {
    NSValue * theValue = [NSValue valueWithBytes:&selector objCType:@encode(SEL)];
    [custom_commands setObject: theValue forKey: command] ; 
} // addHandler 

/** Parses package instruction, mostly used to figure out encoding 
  */

- (void) parsePackages: (id) names {
    NSString * text = [names description] ;
    NSRange utf8pos = [text rangeOfString: @"utf8"] ; 
    if (utf8pos.location!=NSNotFound) {
	encoding = NSUTF8StringEncoding ; 
    } // utf8 encoding
} // parsePackages

/** Parses citation command, citations keys are stored into an array
  */

- (void) parseCitation: (id) names {
    NSString *text = [names description] ; 
    NSArray *citation_array = [text componentsSeparatedByString: @","] ; 
    [citations addObjectsFromArray: citation_array] ; 
} // parseCitation


/** ignore a sequence of character until we meet a sepcific mark 
  */

- (void) ignoreSequence: (const char**) ptr end: (const char*) end_ptr mark: (char) mark {
    do {
	(*ptr)++ ; 
    } while((**ptr)!=mark && ((*ptr) < end_ptr)) ;
}

/** Parse space.
  * We colapse all spaces. 
  */

- (void) parseSpace: (const char**) ptr end: (const char *) end_ptr buffer: (NSMutableString *) buffer {
    unsigned int cr = 0 ; 
    do {
	if (**ptr=='\n') { cr++ ; } 
	(*ptr)++ ; 
    } while(**ptr && isspace(**ptr) && ((*ptr) < end_ptr)) ;
    if (![buffer hasSuffix: @" "]) {
	[buffer appendString: @" "]  ;
    }
} 

/** Handles a command 
  * Commands are looked up in three structures
  * Copy commands, mean that the parameters are simplied copied into the output stream 
  * Replace commands, mean that a value is substituted for the command 
  * Custom commands, the appropriate selector is called with as single parameter the parameter 
  */

- (void) executeCommand: (NSString *) command parameter: (NSString *) parameter buffer: (NSMutableString *) buffer {
    if ([command isEqual: @""] || [command isEqual: @" "]) {
	[buffer appendString: parameter] ; 	
	return ; 
    }
    if ([copy_commands member: command]) {
	[buffer appendString: parameter]  ;
    } else {
	NSObject *replace = (NSObject *) [substitute_commands objectForKey: command] ; 
	if (replace!=nil) {
	    [buffer appendString: [replace description]] ; 
	} else {
	    NSValue *value = (NSValue *) [custom_commands objectForKey: command] ; 
	    if (value!=nil) {
		SEL selector ; 
		[value getValue: &selector] ;
		if ([self respondsToSelector: selector]) {
		    [self performSelector:selector withObject: parameter] ;
		} else {
		    NSLog(@"does not understand selector") ; 
		} // not valid selector 
	    } else {
		if (verbose) { NSLog(@"discarding \"\\%@(%@)\"",command,parameter) ; }
	    } // not match in tables 
	} // not replace command 
    } // no copy command
} // executeCommand

/** Parse an expression until a end mark is met */

- (NSString *) parseExpression: (const char**) ptr end: (const char*) end_ptr startMark: (char) start_mark endMark: (char) end_mark {
    unsigned int counter = 1 ; 
    (*ptr)++ ; 
    const char* block_ptr = *ptr ; 
    do {
	if (*block_ptr==start_mark) { counter++ ; }
	if (*block_ptr==end_mark) { counter-- ; }
	block_ptr++ ; 
    } while(counter>0  && (block_ptr < end_ptr)) ; 
    const unsigned block_len = (block_ptr - *ptr) ;
    NSString *block = [self convertLatex: *ptr length: block_len-1] ; 
    *ptr = block_ptr ;
    return block ; 
} // parseExpression

/** Parses a block, i.e a latex sequence delimited by {}
  */

- (NSString *) parseBlock: (const char**) ptr end: (const char *) end_ptr {
    return [self parseExpression: ptr end: end_ptr startMark: '{' endMark: '}'] ; 
} // parseBlock

/** Parses the parameter block, i.e a latex sequence delimited by []  */ 

- (NSString *) parseParameter: (const char**) ptr end: (const char*) end_ptr {
    return [self parseExpression: ptr end: end_ptr startMark: '[' endMark: ']'] ; 
} // parseParameter

/** parses a command
  */

- (void) parseCommand: (const char**) ptr end: (const char *) end_ptr buffer: (NSMutableString *) buffer { 
    const char* command_ptr = (*ptr) ; 
    NSMutableString *parameter = [[NSMutableString alloc] init] ; 
    do { 
	command_ptr++ ; 
	char c = *command_ptr ; 
	if ('\0'==c) break ; 
	if (isspace(c)) break ; 
	if (! isalnum(c) && ! islatexpunct(c)) break ; 
    } while(command_ptr < end_ptr); 
    const unsigned command_len = (command_ptr - *ptr) ; 
    NSString *command = [[NSString alloc] initWithBytes: (*ptr)+1 length: command_len-1 encoding: encoding] ;
    while(*command_ptr=='[') {
	[parameter appendString: [self parseParameter: &command_ptr end: end_ptr]] ; 
    }
    while(*command_ptr=='{') {
	if ([parameter length]>0) { [parameter appendString: @", "] ; }
	[parameter appendString: [self parseBlock: &command_ptr end: end_ptr]] ; 
    }
    [self executeCommand: command parameter: parameter buffer: buffer] ; 
    [command release] ; 
    [parameter release] ; 
    *ptr = command_ptr ; 
} // parseCommand

/** Copy bytes into the text buffer
  * This method copies a range of latex text and converts it. 
  * Conversion stops when the data is not a normal string, i.e 
  * - an alphanumerical character
  * - high byte data (i.e some encoding specific stuff).
  * - latex punctuation 
  */

- (void) copyText: (const char**) ptr end: (const char*) end_ptr buffer: (NSMutableString *) buffer {
    if (copy_text) {
	const char* s = *ptr ; 
	do {
	    ++s ; 
	} while((isalnum(*s) || islatexpunct(*s) || (*s) <0) && (s < end_ptr)) ; 
	const unsigned s_len = (s - *ptr) ; 
	NSString *tmp = [[NSString alloc] initWithBytes: *ptr length: s_len encoding: encoding] ; 
	if (tmp==nil) {
	    tmp = [[NSString alloc] initWithBytes: *ptr length: s_len] ; 
	    if (verbose) { NSLog(@"could not parse %@ in encoding",tmp) ; }
	} 
	[buffer appendString: tmp]  ;
	[tmp release] ; 
	*ptr = s ; 
    } // if
} // copyText

/** Main function dispatches on the different parsing functions 
  */

- (NSString *) convertLatex: (const char*) text_data length: (unsigned int) length {
    NSMutableString *buffer = [NSMutableString stringWithCapacity: length] ; 
    NSAssert1(nil!=buffer,@"Could not allocate conversion buffer of size %d", length) ; 
    NSMutableString *command = [NSMutableString stringWithCapacity: command_buffer_size] ; 
    NSAssert1(nil!=command,@"Could not allocate command buffer of size %d",command_buffer_size) ; 
    [command setString: @""] ; 
    const char* ptr = text_data ; 
    const char* end_ptr = &(text_data[length]) ; 
    while(*ptr && ptr < end_ptr) {
	const char c = *ptr ; 
	switch(c) {
	    case '&': // We assume this is a tab in a table 
		ptr++ ; 
		// [buffer appendString: @"\t"] ; 
		break ; 
	    case '%': // Comment, we ignore until the end of the line 
		[self ignoreSequence: &ptr end: end_ptr mark: '\n'] ;
		break ;
	    case '\\': // Backslash, this is a command 
		[self parseCommand: &ptr end: end_ptr buffer: buffer] ; 
		break ; 
	    case '$': 
	    case '^':
	    case '_': // Those characters are simply ignored 
		ptr++ ; 
		break ; 
	    case '{': // Start of a block 
		[buffer appendString: [self parseBlock: &ptr end: end_ptr]] ;
		break ; 
	    case '[': // We assume we had a command 
		[self parseParameter:&ptr end: end_ptr] ; 
		break ;
	    case ' ': // All space characters are handled by parseSpace 
	    case '\n':
	    case '\t':
	    case '~':
		[self parseSpace: &ptr end: end_ptr buffer: buffer]; 
		break ; 
	    default: // We simply copy the text 
		[self copyText: &ptr end: end_ptr buffer: buffer] ; 
		break ; 
	} /* switch */ 
    } /* while */
    return buffer ; 
} // convertLatex

/** General function, extracts a sub region from a text based on start and end maker
  */

- (NSString *) extractRegionFrom: (const char*) text length: (unsigned int) length startsWith: (const char*) start endsWith: (const char*) end {
    const char *start_pos = strnstr(text,start,length) ; 
    if (start_pos) {
	unsigned int offset = strlen(start); 
	start_pos+=offset ; 
	const char* end_pos = strnstr(start_pos,end,length-offset) ; 
	if (end_pos) {
	    unsigned int region_len = (unsigned int) (end_pos - start_pos) ; 
	    return [self convertLatex: start_pos length: region_len] ; 
	} /* found the end */
    } /* found begining */
    return nil ; 
}

/** Returns the title of the document */

- (NSString *) getTitle {
    return title ; 
} 

/** Returns the authors of the document */

- (NSString *) getAuthors {
    return authors ; 
}

/** Returns the full plain text */ 

- (NSString *) getFullText {
    return full_text ; 
}

/** Returns the array of citation keys */

- (NSArray *) getCitations {
    return [citations allObjects] ; 
} // getCitations

/** Sets the title of the publication parameter can be anything, it will be converted to string */

- (void) setTitle: (id) new_title {
    if (title!=nil) {
	[title release] ;
    } 
    title = [[new_title description] retain] ; 
} // setTitle

/** Sets the authors of the publication parameter can be anything, it will be converted to string */

- (void) setAuthors: (id) new_authors {
    if (authors!=nil) {
	[authors release] ; 
    }
    authors = [[new_authors description] retain]; 
}

/** Init with Latex data and no command dictionary */ 

- (id) initWithLatexData: (NSData *) data {
    self = [self init] ; 
    [self loadLatexData: data] ;
    return self ; 
} 

/** Init with Latex data and command dictionnary */ 

- (id) initWithLatexData: (NSData *) data commands: (NSDictionary*) dictionary {
    self = [self init] ;
    [self loadLatexCommands: dictionary] ; 
    [self loadLatexData: data] ; 
    return self ; 
} 

/** Init with Latex data and the name and type of the command resource file */ 

- (id) initWithLatexData: (NSData *) data commandName: (NSString *) name commandType: (NSString *)  type {
    self = [self init] ;
    NSBundle *this_bundle = [NSBundle bundleForClass:[self class]];
    if (verbose) { NSLog(@"found bundle %@",this_bundle); }
    NSString *command_path = [this_bundle pathForResource: @"commands" ofType: @"plist"] ;
    if (verbose) { NSLog(@"loading commands from %@",command_path); }
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile: command_path] ; 
    [self loadLatexCommands: dictionary] ; 
    [self loadLatexData: data] ; 
    return self ;
} // 

- (void) loadLatexData: (const char*) data length: (int) length {
    full_text =[[self convertLatex: data length: length] retain] ; 
} // loadLatexData

/** Loads the Latex Data into the parser 
  * Currently this method can only handle a complete Latex file
  * The method allocates everything in memory, probably not the most efficient way. 
  */ 

- (void) loadLatexData: (NSData *) data {
    NSAssert(data!=nil,@"Null data loaded") ; 
    unsigned int scan_range = [data length] ;  
    char *text = (char *) malloc(scan_range) ; 
    [data getBytes: text length: scan_range] ; 
    [self loadLatexData: text length: scan_range] ; 
    free(text) ;    
} // loadData 

/** Loads the different Latex command definitions from a dictionary 
  */ 

- (void) loadLatexCommands: (NSDictionary *) dictionary {
    NSAssert(dictionary!=nil,@"Null dictionary"); 
    NSArray * more_copy_commands = (NSArray *) [dictionary valueForKey: @"copy_commands"] ;  
    [copy_commands addObjectsFromArray:  more_copy_commands] ; 
    NSDictionary * more_substitute_commands = (NSDictionary *) [dictionary valueForKey: @"substitute_commands"] ;
    [substitute_commands addEntriesFromDictionary: more_substitute_commands] ;     
} 

@end
