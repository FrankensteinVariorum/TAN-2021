<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:tan="tag:textalign.net,2015:ns"
    exclude-result-prefixes="xs math"
    version="3.0">
    
   <xsl:include href="../../functions/TAN-function-library.xsl"/>
    <xsl:import href="Diff+.xsl"/>
    
    
    <!-- STEP ONE: PICK YOUR DIRECTORIES AND FILES -->
    
    <!-- What directories of interest hold the target files? The following parameters are provided as examples,
      and for convenince, in case you want to have several commonly used directories handy. See below for
      the main parameter to pick via variable name the directory or directories you want. -->
    <xsl:param name="directory-1-uri" select="'fv-source-fewTinyChunks11'" as="xs:string?"/>

    
    <!-- What pattern must each filename match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, only those whose names match this pattern will be included. A null 
        or empty string means ignore this parameter. -->
    <xsl:param name="tan:input-filenames-must-match-regex" as="xs:string?" select="'^.+?_C\d+[a-z]?.xml$'"/>
    
    <!-- What pattern must each filename NOT match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, any whose names match this pattern will be excluded. A null 
        or empty string means ignore this parameter. -->
    <xsl:param name="tan:input-filenames-must-not-match-regex" as="xs:string?" select="''"/>
    
    <!-- Each diff or collation is performed against a group of files, and there may be one or more
        groups. How shall groups be created? Options:
        1. Detected language (default). Group by detected @xml:lang value; if not present in a particular
        file, assume it belongs to the predefined default language (see parameter $default-language).
        2. Filename only. Group by the filename of the files, perhaps after replacements (see parameter
        $filename-adjustments-before-grouping below).
        3. Filename and language, a synthesis of the previous two options.
    -->
    <xsl:param name="file-group-option" as="xs:integer" select="2"/>
    
    <!-- What changes if any should be made to a filename before attempting to group it with other files? The
      desired changes must be expressed as batch replacements. A batch replacement consists of a sequence
      of elements, each one with attributes @pattern and @replacement and perhaps attributes @flags and
      @message. For examples of batch replacements, see ../../parameters/params-application-language.xsl.
      Note, in most systems filenames are fundamentally not case-sensitive, but have mixed case.
      Therefore in this parameter an attribute flags="i" is normally desirable.
 -->
    <xsl:param name="filename-adjustments-before-grouping" as="element()*">
        <replace pattern="^.+?(_C)" replacement="$1" message="stripping filename starter string"/>
        <replace pattern="\.\w+$" replacement="" flags="i" message="stripping filename extension"/>
        <!-- The next example removes an ISO-style date-time stamp from the filename. -->
        <!--<replace pattern="\d{{8}}" replacement="" flags="i" message="stripping date-time stamp from filename"/>-->
        <!-- The next example ignores filename extensions. -->
        <!--<replace pattern="\.\w+$" replacement="" flags="i" message="stripping filename extension"/>-->
    </xsl:param>
    
    
    
    <!-- <xsl:sequence select="tan:collate()"/> ebb: The function takes xs:string* as input, so I don't think I can deliver it files until they run through a conversion process. I may need the file
    setup parameters from Diff+ so I can be collating markup as planned. -->
    
    
    
 <!-- 2022-07-16 ebb: Parameters I'd like to be delivering to tan:collate() functions.  -->   
    
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
    <xsl:param name="xml-handling-option" as="xs:integer" select="3"/>
    
    <!-- Collation/diff handling -->
    
    <!-- Should tan:collate() be allowed to re-sort the strings to take advantage of optimal matches? True
      produces better results, but could take longer than false. -->
    <xsl:param name="preoptimize-string-order" as="xs:boolean" select="true()"/> 
    
    <!-- STEP TWO: REFINE INPUT FILES -->
    <!-- What language should be assumed for any input text that does not have a language associated with it?
      Please use a standard 3-letter ISO code, e.g., eng for English, grc for ancient Greek, deu for
      German, etc. -->
    <xsl:param name="default-language" as="xs:string?" select="'en'"/>
    
    <!-- Should non-TAN input be space-normalized before processing? Note, all TAN files will be space
        normalized before processing. -->  
    <xsl:param name="space-normalize-non-tan-input" as="xs:boolean" select="true()"/>
    

    
    
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
    <xsl:param name="tan:ignore-case-differences" as="xs:boolean?" select="true()"/>
    
    <!-- Should punctuation be ignored? -->
    <xsl:param name="tan:ignore-punctuation-differences" as="xs:boolean" select="false()"/>
    
    <xsl:param name="additional-batch-replacements" as="element()*">
        <!--ebb: normalizations to batch process for collation. NOTE: We want to do these to preserve some markup \\
            in the output for post-processing to reconstruct the edition files. 
            Remember, these will be processed in order, so watch out for conflicts. -->
        <replace pattern="(&lt;.+?&gt;\s*)&amp;gt;" replacement="$1" message="normalizing away extra right angle brackets"/>
        <replace pattern="&amp;amp;" replacement="and" message="ampersand batch replacement"/>
        <replace pattern="&lt;/?xml&gt;" replacement="" message="xml tag replacement"/>
        <replace pattern="(&lt;p)\s+.+?(/&gt;)" replacement="$1$2" message="p-tag batch replacement"/>
        <replace pattern="(&lt;)(metamark).*?(&gt;).+?\1/\2\3" replacement="" message="metamark batch replacement"/><!--ebb: metamark contains a text node, and we don't want its contents processed in the collation, so this captures the entire element. -->
        <replace pattern="(&lt;/?)m(del).*?(&gt;)" replacement="$1$2$3" message="mdel-SGA batch replacement"/>  <!--ebb: mdel contains a text node, so this catches both start and end tag.
        We want mdel to be processed as <del>...</del>-->
        <replace pattern="&lt;/?damage.*?&gt;" replacement="" message="damage-SGA batch replacement"/> <!--ebb: damage contains a text node, so this catches both start and end tag. -->
        <replace pattern="&lt;/?unclear.*?&gt;" replacement="" message="unclear-SGA batch replacement"/> <!--ebb: unclear contains a text node, so this catches both start and end tag. -->
        <replace pattern="&lt;/?retrace.*?&gt;" replacement="" message="retrace-SGA batch replacement"/> <!--ebb: retrace contains a text node, so this catches both start and end tag. -->
        <replace pattern="&lt;/?shi.*?&gt;" replacement="" message="shi-SGA batch replacement"/> <!--ebb: shi (superscript/subscript) contains a text node, so this catches both start and end tag. -->
        <replace pattern="(&lt;del)\s+.+?(/&gt;)" replacement="$1$2" message="del-tag batch replacement"/>
        <replace pattern="&lt;hi.+?/&gt;" replacement="" message="hi batch replacement"/>
        <replace pattern="&lt;pb.+?/&gt;" replacement="" message="pb batch replacement"/>
        <replace pattern="&lt;add.+?&gt;" replacement="" message="add batch replacement"/>
        <replace pattern="&lt;w.+?/&gt;" replacement="" message="w-SGA batch replacement"/>
        <replace pattern="(&lt;del)Span.+?spanTo=&quot;#(.+?)&quot;.*?(/&gt;)(.+?)&lt;anchor.+?xml:id=&quot;\2&quot;.*?&gt;" replacement="$1$3$4$1$3" message="delSpan-to-anchor-SGA batch replacement"/>
        
        <!-- delSpan to anchor issue: matching on quotation marks. -->
        <!-- ebb: This works, but that also means that quotes are read as &quot;    
        <replace pattern="&quot;" replacement="__" message="TEST replacing quotes"/>-->
        
        <!--   <replace pattern="(&lt;del)Span.+?(/&gt;)(.+?)&lt;anchor.+?&gt;" replacement="$1$2$3$1$2" message="delSpan-SGA batch replacement"/>
   Replace <anchor> AFTER you do the delSpan to anchor replacement. 
   -->
        <replace pattern="&lt;anchor.+?/&gt;" replacement="" message="anchor-SGA batch replacement"/>
        
        <!--
              <replace pattern="(&lt;del)Span.+?spanTo=&quot;#(.+?)&quot;.*?(/&gt;)(.+?)&lt;anchor.+?xml:id=&quot;$2&quot;.*?&gt;" replacement="$1$3$4$1$3" message="delSpan-to-anchor-SGA batch replacement"/>
            2022-04-23 ebb: Here I am trying to have tanDiff read a delSpan to anchor pattern and replace it with a simple del marker.  
          Is it better to do this during pre-processing, while preserving some marker that this was a delSpan-to-anchor in the source SGA file? Or does that make post-processing more complicated?
        -->
        <!-- REPLACEMENT PATTERNS THAT USED TO BE ELEMENTS SENT FOR DELETION IN THE TAN DIFF TEMPLATE -->     
        <replace pattern="&lt;milestone.+?unit=&quot;tei:p&quot;.+?/&gt;" replacement="&lt;p/&gt; &lt;p/&gt;" message="milestone-paragraph-SGA batch replacement"/>  
        <replace pattern="&lt;milestone.+?/&gt;" replacement="" message="milestone non-p batch replacement"/>  
        <replace pattern="&lt;lb.+?/&gt;" replacement="" message="lb batch replacement"/>  
        <replace pattern="&lt;surface.+?/&gt;" replacement="" message="surface-SGA batch replacement"/> 
        <replace pattern="&lt;zone.+?/&gt;" replacement="" message="zone-SGA batch replacement"/> 
        <replace pattern="&lt;mod.+?/&gt;" replacement="" message="mod-SGA batch replacement"/> 
        <replace pattern="&lt;restore.+?/&gt;" replacement="" message="restore-SGA batch replacement"/> 
        <replace pattern="&lt;graphic.+?/&gt;" replacement="" message="graphic-SGA batch replacement"/> 
        
        <replace pattern="&lt;head.+?/&gt;" replacement="" message="head batch replacement"/> 
        <!--ebb: Not sure if I need a replace pattern for <header>? I think we're only using <head>, and only in non-SGA files for Chapter headings, etc. -->
        <replace pattern="&lt;comment.+?&gt;" replacement="" message="comment batch replacement"/> 
    </xsl:param>
    
    <!-- STEP FIVE: ADJUST OUTPUT -->
    <!-- In what directory should the output be saved? -->
    <xsl:param name="output-directory-uri" as="xs:string" select="'fv-collation-fewTinyChunks11'"/>
    
    <xsl:param name="output-base-filename" as="xs:string?" select="'collation-C11b'"/>
    <!-- What suffix, if any, should be appended to output filenames? -->
    <xsl:param name="output-filename-suffix" as="xs:string?" select="'-compared'"/>
    
    
    
    
</xsl:stylesheet>