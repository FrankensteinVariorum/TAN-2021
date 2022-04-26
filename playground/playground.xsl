<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   version="3.0">
   
   <xsl:include href="../functions/TAN-function-library.xsl"/>
   
   <xsl:variable name="filepaths" as="xs:anyURI*" select="uri-collection('somefiles') => sort()"/>
   <xsl:variable name="input-docs" as="document-node()*" select="tan:open-file($filepaths)"/>
   <xsl:variable name="input-strings" as="xs:string*" select="
         for $i in $input-docs
         return
            string($i)"/>
   <xsl:variable name="input-strings-norm" as="xs:string*" select="
         for $i in $input-strings
         return
            normalize-space($i)"/>
   <xsl:variable name="collation" as="element()" select="
         tan:collate($input-strings-norm, (for $i in $filepaths
         return
            tan:cfn($i)), true(), false(), true(), true())"/>
   
   <!--<xsl:param name="tan:snap-to-word" as="xs:boolean" select="true()"/>-->
   
   <xsl:output indent="yes"/>
   <xsl:template match="/">
      <diagnostics>
         <!--<filepaths count="{count($filepaths)}"><xsl:value-of select="$filepaths"/></filepaths>-->
         <!--<strings count="{count($input-strings)}"><xsl:value-of select="for $i in $input-strings return tan:ellipses($i, 10)"/></strings>-->
         <xsl:copy-of select="$collation"/>
      </diagnostics>
   </xsl:template>
   
</xsl:stylesheet>