<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:util="http://dtd.nlm.nih.gov/xsl/util" xmlns:doc="http://www.dcarlisle.demon.co.uk/xsldoc" xmlns:ie5="http://www.w3.org/TR/WD-xsl" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:fns="http://www.w3.org/2002/Math/preference" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:pref="http://www.w3.org/2002/Math/preference" pref:renderer="mathplayer" exclude-result-prefixes="util xsl">
	<xsl:template match="*" mode="make-front">
		<!-- FIXME nao tem article-categories no XML -->
		<xsl:apply-templates select=".//article-categories"/>
		<xsl:apply-templates select=".//title-group" mode="front"/>
		
		<p>
			<xsl:apply-templates select=".//contrib-group/contrib" mode="format"/>
		</p>
		<xsl:apply-templates select=".//aff" mode="format"/>
		<xsl:apply-templates select=".//author-notes" mode="front"/>
		<xsl:apply-templates select=".//abstract" mode="format"/>
		<hr/>
	</xsl:template>
	<xsl:template match="contrib-group/contrib" mode="format">
		<xsl:choose>
			<xsl:when test="@xlink:href">
				<a>
					<xsl:call-template name="make-href"/>
					<xsl:call-template name="make-id"/>
					<xsl:apply-templates select="name | collab" mode="front"/>
				</a>
			</xsl:when>
			<xsl:otherwise>
				<span class="capture-id">
					<xsl:call-template name="make-id"/>
					<xsl:apply-templates select="name | collab" mode="front"/>
				</span>
			</xsl:otherwise>
		</xsl:choose>
		<!-- the name element handles any contrib/xref and contrib/degrees -->
		<xsl:apply-templates select="*[not(self::name)
                                       and not(self::collab)
                                       and not(self::xref)
                                       and not(self::degrees)]" mode="front"/>
		<xsl:call-template name="nl-1"/>
		<xsl:call-template name="nl-1"/>
		<xsl:if test="position()!=last()">; </xsl:if>
	</xsl:template>
</xsl:stylesheet>
