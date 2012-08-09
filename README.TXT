***********************************************************
*****************                        ******************
**************        Project Copier         **************
**************           Ver 0.11            **************
*****************                        ******************
***********************************************************
       Utility for copying projects (FPC only)
	   
This application searches for all units used by the listed
projects in the source folder and copies those files to the
target folder, replicating the folder structure.

This is useful if you share source files between different
open source projects and only wish to copy to a repository
the files corresponding to one project.

Currently it only supports Freepascal code. I intend to 
add Python too in the near futures, with a loose 
definition of "near".

***********************************************************
******                   DISCLAIMER                  ******

This software is provided "as is", with no explicit or 
implied warranties. None whatsoever. I mean it. I would 
even write all this in caps if only it didn't look so ugly.

            Use this software at your own risk. 

***********************************************************
******                   Copyright                   ******

This software is public domain. You have the right to copy, 
distribute, reuse, modify, improve and debug it. Especially
this last one.

***********************************************************
******                   Compiling                   ******

Using the Lazarus IDE:

1-  Install Lazarus and FPC, which are available here:
	http://www.lazarus.freepascal.org/

2-  Open the project file projectcopy/projectcopy.lpi

3-  Press F9
		
***********************************************************
******                   Installing                  ******

TBA...

***********************************************************

Source code available at:
https://github.com/lkrippahl/projectcopy

Ludwig Krippahl, 2011
