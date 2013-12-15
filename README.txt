idml2xml: An XSLT 2 / XProc based tool for converting IDML to
Hub XML (https://github.com/gimsieke/Hub).

It will typically be used in conversion pipelines that use other
modules, such as https://subversion.le-tex.de/common/evolve-hub/
or https://subversion.le-tex.de/common/epubtools/

XProc invocation:

/path/to/calabash.sh file:/path/to/idml2xml/xpl/idml2hub.xpl idmlfile=/path/to/idml2xml/sample/testdokument.idml debug=yes

If you use cygwin and bash, you can use, for example,
file:/$(cygpath -ma xpl/idml2hub.xpl) for the XProc URI and
idmlfile=$(cygpath -ma sample/testdokument.idml) for the IDML file name.

You need a calabash version with the letex:unzip extension. 
A runnable calabash with .sh and .bat invocation for Unix-like systems, Cygwin
and Windows is available from https://subversion.le-tex.de/common/calabash/

It depends on some external XProc / XSLT libraries. A ready-to-run standalone
pipeline (https://subversion.le-tex.de/idmltools/trunk/idml2xml_frontend/) is
in preparation.

(C) 2011--2013, le-tex publising services GmbH.  All rights reserved.
Published under Simplified BSD License:

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

   1. Redistributions of source code must retain the above copyright 
      notice, this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY LE-TEX PUBLISING SERVICES ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL LE-TEX PUBLISING SERVICES OR CONTRIBUTORS 
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



