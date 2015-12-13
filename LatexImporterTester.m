/*
 *  LatexImporterTester.c
 *  LatexImporter
 *
 *  Created by Matthias Wiesmann on 23.08.05.
 *  Copyright 2005 Matthias Wiesmann. All rights reserved.
 *
 */

#include <sysexits.h>

#include "LatexImporterTester.h"

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#import <Cocoa/Cocoa.h>

#import "LatexParser.h"


/** This is a small program that does try to run the text extraction code on a file 
  * For actually trying out the spotlight plugin, see 
  * http://developer.apple.com/documentation/Carbon/Conceptual/MDImporters/Concepts/Troubleshooting.html
  */ 


int main(int argc, char **argv) {
    if (argc<3) {
	fprintf(stderr,"Usage: %s <latex file> <command file>\n",argv[0]);
	exit(EX_USAGE); 
    } else {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *file_manager = [NSFileManager defaultManager] ; 
	NSString *path = [[NSString alloc] initWithCString: argv[1] encoding: NSUTF8StringEncoding] ;
	if (! [file_manager fileExistsAtPath:  path]) {
	    fprintf(stderr,"Could not find data file \"%s\", exiting\n",argv[1]) ; 
	    exit(EX_NOINPUT); 
	} else {
	    NSLog(@"Loading data file %@",path); 
	}
	NSData *tex_data = [NSData dataWithContentsOfFile: path] ; 
	NSString * command_path = [[NSString alloc] initWithCString: argv[2] encoding: NSUTF8StringEncoding] ; 
	if (! [file_manager fileExistsAtPath: command_path]) {
	    fprintf(stderr,"Could not find command file %s exiting\n",argv[2]) ; 
	    exit(EX_NOINPUT); 
	} else {
	    NSLog(@"Loading command file %@",command_path); 
	}
	NSDictionary *commands = [NSDictionary dictionaryWithContentsOfFile: command_path] ; 
	if (tex_data) {
	    [tex_data retain] ;
	    LatexParser *p = [[LatexParser alloc] initWithLatexData: tex_data commands: commands ] ;
	    NSString *title = [p getTitle] ; 
	    if (title) {
		NSLog(@"title: %@\n",title) ;  
	    } 
	    NSString *authors = [p getAuthors] ; 
	    if (authors) {
		NSLog(@"authors: %@\n",authors) ; 
	    }
	    NSString *full_text = [p getFullText] ; 
	    if (full_text) {
		NSLog(@"full text:\n----\n%@",full_text) ; 
	    }
	    NSArray *citations = [p getCitations] ; 
	    if (citations) {
		NSLog(@"citations: %@\n",[citations description]) ; 
	    }
	    
	    [p release] ;
	} /* path */
    [pool release];
    }
return 0 ; 
}