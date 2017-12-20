#Insert cmd line help
#Connect to SPO 
Connect-SPOService 

#Add CDN location(s)

Foreach ($cdn in $cdns) {
	Add-SPOTenantCdnOrigin -CDNType $cdnType -OriginUrl $originUrl
}
