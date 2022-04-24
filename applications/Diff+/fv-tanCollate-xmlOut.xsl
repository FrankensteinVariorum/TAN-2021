<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:ebb="http://newtfire.org"
    exclude-result-prefixes="xs math"
    version="3.0">
    
 
    <xsl:include href="../../functions/TAN-function-library.xsl"/>
    
    <!--ebb: Try building up from just tan:collate(). Not sure how to handle the normalization replacements. -->
    <xsl:variable name="sourceFilePaths" as="xs:anyURI*" select="uri-collection('fv-collation-chunk27') => sort()"/>
    <xsl:variable name="incoming-to-TAN" as="document-node()*" select="tan:open-file($sourceFilePaths)"/>
    
    <xsl:variable name="input-strings" as="xs:string*">
        <xsl:for-each select="$incoming-to-TAN">
            <xsl:value-of select="string(current())"/>
        </xsl:for-each> 
    </xsl:variable>  
    
   <xsl:function name="ebb:normalize" as="xs:string*">
       <xsl:param name="stringToNormalize" as="xs:string*"/>
           <xsl:variable name="angleBracket" as="xs:string*" select="replace($stringToNormalize, '(&lt;.+?&gt;\s*)&amp;gt;', '$1')"/>
           <xsl:message>normalizing away extra right angle brackets</xsl:message>
       <xsl:variable name="amp-to-and" as="xs:string*" select="replace($angleBracket, '&amp;amp;', 'and')"/>
       <xsl:message>ampersand batch replacement</xsl:message>
       <xsl:variable name="xmlTag" as="xs:string*" select="replace($amp-to-and, '&lt;/?xml&gt;', '')"/>
       <xsl:message>xml tag replacement</xsl:message>
       <xsl:variable name="pTags" as="xs:string*" select="replace($xmlTag, '(&lt;p)\s+.+?(/&gt;)', '$1$2')"/>
       <xsl:message>paragraph tag replacements (all but S-GA)</xsl:message>
       <xsl:variable name="SGA-pTags" as="xs:string*" select="replace($pTags, '&lt;milestone.+?unit=&quot;tei:p&quot;.+?/&gt;', '&lt;p/&gt; &lt;p/&gt;')"/>
       <xsl:message>milestone-paragraph-SGA batch replacemens</xsl:message>
       <xsl:variable name="other-SGA-milestones" as="xs:string*" select="replace($SGA-pTags, '&lt;milestone.+?/&gt;', '')"/>
       <xsl:message>SGA milestone non-p batch replacement</xsl:message>
       <xsl:variable name="SGA-lb" as="xs:string*" select="replace($other-SGA-milestones, '&lt;lb.+?/&gt;', '')"/>
       <xsl:message>SGA lb batch replacement</xsl:message>
       <xsl:variable name="SGA-surface" as="xs:string*" select="replace($SGA-lb, '&lt;surface.+?/&gt;', '')"/>
       <xsl:message>surface-SGA batch replacement</xsl:message>
       <xsl:variable name="SGA-zone" as="xs:string*" select="replace($SGA-surface, '&lt;zone.+?/&gt;', '')"/>
       <xsl:message>zone-SGA batch replacement</xsl:message>

   </xsl:function>
    
    <xsl:variable name="normalizedForm" as="xs:string*">
        <xsl:for-each select="$input-strings">
          
          <xsl:value-of select="ebb:normalize(current())"/>
           
        </xsl:for-each>
    </xsl:variable>
    
    <xsl:variable name="collation" as="element()" select="tan:collate($normalizedForm, (for $i in $sourceFilePaths return tan:cfn($i)))"/>
    
    <xsl:output indent="yes"/>
    
    <xsl:template match="/">
        <diagnostics>
            <filepaths count="{count($sourceFilePaths)}"><xsl:value-of select="$sourceFilePaths"/></filepaths>
            <strings count="{count($normalizedForm)}"><xsl:value-of select="for $i in $normalizedForm return tan:ellipses($i, string-length($i))"/></strings>
            <xsl:copy-of select="$collation"/>
        </diagnostics>
    </xsl:template>
    
    
</xsl:stylesheet>