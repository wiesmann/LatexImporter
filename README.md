# Latex Spotlight Importer

This project contains an spotlight component which indexes Laτεχ source files. It has the following features:

* Does not require any Latex installation.
* Extracts the title and the authors.
* Tries to guess the encoding from the inputenc package.
* Indexes the list of publications keys.
* Full text indexing. The latex code is converted to plain text and indexed.
* Command substitution. Certainc commands are substituted for a unicode string for instance \delta becomes δ. This can be customized using a standard property list.
* Command copying. The parameter of certain commands is simply copied, for instance the content of the \textsf command is simply copied. Again, this can be customized.

To use the importer:

* Open the project and build it.
* Copy the `LatexImporter.mdimporter` file to `~/Library/Spotlight/`
* Normally, the importer is activated automatically, if not, you can type `/usr/bin/mdimport -r ~/Library/Spotlight/LatexImporter.mdimporter` to force the activation.
* To see what the plugin actually indexes for a given tex document, type in the following command `mdimport -d bla.tex` where blah is the tex document. You will get all the log messages and the values that have been extracted.
* The project also defines a command-line tool `LatexImporterTester` which can be used to see what gets indexed without involving the Spotlight infrastructure. 

 

