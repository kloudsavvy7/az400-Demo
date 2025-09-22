#.Synopsis
#   Generates a self-signed SSL certificate and binds it to the Web Application.
#

param(
	# The Web site name as shown in IIS
	$WebAppName = "Microsoft Azure DR Appliance Configuration Manager",

	# Used as the CN for the SSL certificate
	$Subject = "${Env:ComputerName}"
)

# Note: Using the current defaults for New-SelfSignedCertificate (2048 bit RSA keys with SHA256) --
# if they change them, it'll be to stronger options, so let's accept the defaults for now.
$Cert = New-SelfSignedCertificate -Subject "CN=$Subject" -CertStoreLocation cert:\LocalMachine\My `
	-NotAfter ((Get-Date).AddYears(1)) -FriendlyName "Microsoft Azure DR Appliance Config Manager Cert"  `
    -DNSName "$Subject"

# Get the cert thumbprint.
$CertThumbprint = $Cert.Thumbprint

# Get the web binding of the site
$binding = Get-WebBinding -Name $WebAppName -Protocol "https"

# Set the SSL binding
$binding.AddSslCertificate($Cert.GetCertHashString(), "my")

# Install certificate in Trusted Root.
$getCert = (get-item cert:\LocalMachine\MY\$CertThumbprint)
$store = (get-item cert:\LocalMachine\Root)
$store.Open("ReadWrite")
$store.Add($getCert)
$store.Close()