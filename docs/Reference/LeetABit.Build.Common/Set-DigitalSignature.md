# Set-DigitalSignature

Sets an Authenticode signature for a specified item.

```Set-DigitalSignature [-Path] <String[]> [-CertificatePath] <String> [[-TimestampServer] <String>] [-WhatIf] [-Confirm]```

```Set-DigitalSignature [-Path] <String[]> [-Certificate] <X509Certificate2> [[-TimestampServer] <String>] [-WhatIf] [-Confirm]```

## Description

The Set-DigitalSignature cmdlet adds an Authenticode signature to any file that supports Subject Interface Package (SIP). If there is a signature in the file when this cmdlet runs, that signature is removed.

## Examples

### Example 1:

```PS> Set-DigitalSignature -ArtifactPath "C:\artifact.dll" -Certificate $cert```

Digitally signs the specified file using specified code sign certificate.

### Example 2:

```PS> Set-DigitalSignature -ArtifactPath "C:\artifact.dll" -CertificatePath "cert:\LocalMachine\My\$CertFingerprint" -TimestampServer "http://timeserver.example.com"```

Digitally signs the specified file using certificate located under specified path in the store and adds timestamp to the signature.

## Parameters

### ```-Path```

*Path to the file that shall be signed.*

<table>
  <tr><td>Type:</td><td>String[]</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>1</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByValue, ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-CertificatePath```

*PowerShell Certificate Store path to the Code Sign certificate.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Certificate```

*Code Sign certificate to be used.*

<table>
  <tr><td>Type:</td><td>X509Certificate2</td></tr>
  <tr><td>Required:</td><td>true</td></tr>
  <tr><td>Position:</td><td>2</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-TimestampServer```

*Code Sign Timestamp Server to be used.*

<table>
  <tr><td>Type:</td><td>String</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>3</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>true (ByPropertyName)</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-WhatIf```

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

### ```-Confirm```

<table>
  <tr><td>Type:</td><td>SwitchParameter</td></tr>
  <tr><td>Required:</td><td>false</td></tr>
  <tr><td>Position:</td><td>Named</td></tr>
  <tr><td>Default value:</td><td></td></tr>
  <tr><td>Accept pipeline input:</td><td>false</td></tr>
  <tr><td>Accept wildcard characters:</td><td>false</td></tr>
</table>

## Input

None

## Output

```[System.Management.Automation.Signature]```
