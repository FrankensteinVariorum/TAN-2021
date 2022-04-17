<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="3.0">
    
   <xsl:import href="Diff+.xsl"/>
    <!-- STEP ONE: PICK YOUR DIRECTORIES AND FILES -->   
    <!-- What directory or directories has the main input files? Any relative path will be calculated
      against the location of this application file. Multiple directories may be supplied. Too many files?
      Results can be filtered below. -->
    <xsl:param name="tan:main-input-relative-uri-directories" as="xs:string*" select="'fv-source-chunk11'"/>
    
    
    <!-- What pattern must each filename match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, only those whose names match this pattern will be included. A null 
        or empty string means ignore this parameter. -->
    <xsl:param name="tan:input-filenames-must-match-regex" as="xs:string" select="'\.xml$'"/>
    
    <!-- Each diff or collation is performed against a group of files, and there may be one or more
        groups. How shall groups be created? Options:
        1. Detected language (default). Group by detected @xml:lang value; if not present in a particular
        file, assume it belongs to the predefined default language (see parameter $default-language).
        2. Filename only. Group by the filename of the files, perhaps after replacements (see parameter
        $filename-adjustments-before-grouping below).
        3. Filename and language, a synthesis of the previous two options.
    -->
   <xsl:param name="file-group-option" as="xs:integer" select="1"/>
    
    <!-- What changes if any should be made to a filename before attempting to group it with other files? The
      desired changes must be expressed as batch replacements. A batch replacement consists of a sequence
      of elements, each one with attributes @pattern and @replacement and perhaps attributes @flags and
      @message. For examples of batch replacements, see ../../parameters/params-application-language.xsl.
      Note, in most systems filenames are fundamentally not case-sensitive, but have mixed case.
      Therefore in this parameter an attribute flags="i" is normally desirable.
 -->  
    <xsl:param name="filename-adjustments-before-grouping" as="element()*">
        <replace pattern="^\w+?-" replacement="" flags="i" message="stripping filename starter string"/>
        <!-- The next example removes an ISO-style date-time stamp from the filename. -->
        <!--<replace pattern="\d{{8}}" replacement="" flags="i" message="stripping date-time stamp from filename"/>-->
        <!-- The next example ignores filename extensions. -->
        <!--<replace pattern="\.\w+$" replacement="" flags="i" message="stripping filename extension"/>-->
    </xsl:param>
    
    <!-- STEP TWO: REFINE INPUT FILES -->
    <!-- What language should be assumed for any input text that does not have a language associated with it?
      Please use a standard 3-letter ISO code, e.g., eng for English, grc for ancient Greek, deu for
      German, etc. -->
    <xsl:param name="default-language" as="xs:string?" select="'eng'"/>
  
    <!-- Should non-TAN input be space-normalized before processing? Note, all TAN files will be space
        normalized before processing. -->  
    <xsl:param name="space-normalize-non-tan-input" as="xs:boolean" select="true()"/>
    
    <!-- How do you wish to handle input files that are XML? Options:
        1. (default) Compare only the text values of the XML files. If a TAN or TAN-TEI file,
        only the normalized body text will be compared. For all other XML structures, the entire
        text will be taken into account.
        2. Treat the XML file as plain text. Choose this option if you are interested
        in comparing XML structures to each other. Each XML file will be serialized as a string and 
        compared.
        3. Load an XML file, convert to plain text later. Choose this option if you want to normalize
        your XML input, and perhaps adjust them, before they are compared later as strings. To do that
        adjustment, it is recommended you add templates to the mode prepare-input, keeping in mind that
        an important template is applied by Diff+ to the root element, to prepare it for grouping.
    -->
    <xsl:param name="xml-handling-option" as="xs:integer" select="2"/>
    
    
    <!-- STEP THREE: NORMALIZE INPUT STRINGS -->
    
    <!-- Adjustments to diff/collate input strings -->
    <!-- Additional settings at:
        ../../parameters/params-application-diff.xsl 
        ../../parameters/params-application-language.xsl 
    -->
    
    <!-- You can make normalizations to the string before it goes through the comparison. The XML
      output will show the normalized results, and statistics will be based on it. But when building the
      HTML output, this application will try to reinject the original text into the adjusted difference.
      This is oftentimes an imperfect process, because any restoration must broker between differences
      across versions. In general, the first version will predominate. -->
    
    <!-- Should <div> @ns be injected into the text? Normally you do not want to do this, but it can be
      helpful when you want to indentify differences in reference systems. -->
    <xsl:param name="inject-attr-n" as="xs:boolean" select="false()"/>
    
    <!-- Should differences in case be ignored? -->
    <xsl:param name="tan:ignore-case-differences" as="xs:boolean?" select="false()"/>
    
    <!-- Should punctuation be ignored? -->
    <xsl:param name="tan:ignore-punctuation-differences" as="xs:boolean" select="false()"/>
    
    <xsl:param name="additional-batch-replacements" as="element()*">
        <!--ebb: normalizations to batch process for collation. Remember, these will be processed
            in order, so watch out for conflicts. -->
      <!-- <replace pattern="(&amp;)(and)" replacement="$2$1" message="ampersand batch replacement"/>
       
       <replace pattern="(&lt;xml.+?&gt;)()" replacement="$2$1" message="xml batch replacement"/>
        <replace pattern="(&lt;lb/&gt;)()" replacement="$2$1" message="lb-SGA batch replacement"/>
        <replace pattern="(&lt;p\s+.+?/&gt;)(&lt;p/&gt;)" replacement="$2$1" message="p-tag batch replacement"/>
        <replace pattern="(&lt;metamark&gt;.+?/&lt;/metamark&gt;)()" replacement="$2$1" message="metamark batch replacement"/>
        <replace pattern="(&lt;hi.+?/&gt;)()" replacement="$2$1" message="hi batch replacement"/>
        <replace pattern="(&lt;pb.+?/&gt;)()" replacement="$2$1" message="pb batch replacement"/>
        <replace pattern="(&lt;surface.+?&gt;)()" replacement="$2$1" message="surface-SGA batch replacement"/>
        <replace pattern="(&lt;zone.+?&gt;)()" replacement="$2$1" message="zone-SGA batch replacement"/>
        <replace pattern="(&lt;w.+?/&gt;)()" replacement="$2$1" message="w-SGA batch replacement"/>
        <replace pattern="(&lt;mod.+?/&gt;)()" replacement="$2$1" message="mod-SGA batch replacement"/>
        <replace pattern="(&lt;anchor.+?/&gt;)()" replacement="$2$1" message="anchor-SGA batch replacement"/>
        <replace pattern="(&lt;damage.+?&gt;)()" replacement="$2$1" message="damage-SGA batch replacement"/>
        <replace pattern="(&lt;restore.+?&gt;)()" replacement="$2$1" message="restore-SGA batch replacement"/>
        <replace pattern="(&lt;comment.+?&gt;)()" replacement="$2$1" message="comment-SGA batch replacement"/>
        <replace pattern="(&lt;include.+?&gt;)()" replacement="$2$1" message="include-SGA batch replacement"/>
        <replace pattern="(&lt;add.+?&gt;)()" replacement="$2$1" message="add batch replacement"/>
        <replace pattern="(&lt;delSpan.+?&gt;)()" replacement="$2$1" message="delSpan-SGA batch replacement"/>
        <replace pattern="(&lt;mdel.+?&gt;)()" replacement="$2$1" message="mdel-SGA batch replacement"/>
        <replace pattern="(&lt;graphic.+?&gt;)()" replacement="$2$1" message="graphic-SGA batch replacement"/>
        <replace pattern="(&lt;unclear.+?&gt;)()" replacement="$2$1" message="unclear-SGA batch replacement"/>
        <replace pattern="(&lt;retrace.+?&gt;)()" replacement="$2$1" message="retrace-SGA batch replacement"/>
        <replace pattern="(&lt;head\s+.+?&gt;)()" replacement="$2$1" message="head batch replacement"/>
        <replace pattern="(&lt;header.+?&gt;)()" replacement="$2$1" message="header batch replacement"/>-->
       

     <!--   ['sourceDoc', 'xml', 'pb', 'comment', 'w', 'mod', 'anchor', 'include', 'delSpan', 'addSpan', 'add', 'handShift', 'damage', 'restore', 'zone', 'surface', 'graphic', 'unclear', 'retrace', 'hi', 'head', 'header']
     
     ebb: Left out handShift this time from the replacement/normalization...
     -->
    
    
    </xsl:param>
    
    
    <!-- STEP FOUR: ADJUST THE DIFF/COLLATION PROCESS -->
    <!-- Additional settings at ../../parameters/params-application-diff.xsl. -->
    
    <!-- Collation/diff handling -->
    
    <!-- Should tan:collate() be allowed to re-sort the strings to take advantage of optimal matches? True
      produces better results, but could take longer than false. -->
    <xsl:param name="preoptimize-string-order" as="xs:boolean" select="true()"/> 
    
    
    <!-- STEP FIVE: ADJUST OUTPUT -->
    <!-- In what directory should the output be saved? -->
    <xsl:param name="output-directory-uri" as="xs:string" select="'fv-collation-chunk11'"/>
    
    <!-- What suffix, if any, should be appended to output filenames? -->
    <xsl:param name="output-filename-suffix" as="xs:string?" select="'-compared'"/>
    
    
    <!-- Statistics -->
    
    <!-- See ../../parameters/params-application-diff.xsl -->
    
    
    
    <!-- HTML output -->
    
    <!-- Important settings also at ../../parameters/params-application-html-output.xsl -->
    
    <!-- TAN Diff+'s HTML output relies upon a small core of javascript and css assets, currently in the TAN 
        package in the folders output/css and output/js, with the assumption that multiple files in the parent 
        directory will point to those libraries. But you may want another configuration. -->
    
    <!-- Where are the javascript assets? If this parameter is blank, the default directory will be the
        subdirectory js off $output-directory-uri. -->
    <xsl:param name="output-javascript-library-directory-uri" as="xs:string?"/>
    
    <!-- Where are the CSS assets? If this parameter is blank, the default directory will be the
        subdirectory css off $output-directory-uri. -->
    <xsl:param name="output-css-library-directory-uri" as="xs:string?"/>
    
    <!-- In the HTML output, should an attempt be made to convert resultant diffs back to their pre-adjustment 
        forms or not? -->
    <xsl:param name="replace-diff-results-with-pre-alteration-forms" as="xs:boolean" select="true()"/>
    
    <!-- THE APPLICATION -->
    
    <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
  <!--<xsl:include href="incl/Diff+%20core.xsl"/>-->
    <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
    <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>
    
</xsl:stylesheet>
