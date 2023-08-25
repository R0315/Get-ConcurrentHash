Computes the hash values for files in the specified directory using a concurrent approach.
#### DESCRIPTION
`Get-ConcurrentHash` calculates the hash for all the files at the provided folder path using the specified hashing algorithm. The results are written to a specified CSV file. It supports various hash algorithms and allows for concurrent processing to improve performance.
#### PARAMETERS
- **`-Path`** (String[])
  Specifies the paths to the files or directories. Wildcards are supported.
  This parameter is mandatory if the `LiteralPath` parameter is not provided.
  Example: `-Path "C:\Documents\*"`
- **`-LiteralPath`** (Alias: PSPath) (String[])
  Specifies the path without wildcard expansion.
  This parameter is mandatory if the `Path` parameter is not provided.
  Example: `-LiteralPath "C:\Documents"`
- **`-OutputCSV`** (String)
  Specifies the output CSV file path where the result will be written.
  This parameter is mandatory.
  Example: `-OutputCSV "C:\output.csv"`
- **`-Algorithm`** (String)
  Specifies the hashing algorithm to be used. Supported values are "SHA1", "SHA256", "SHA384", "SHA512", "MD5".
  This parameter is optional, and the default value is "MD5".
  Example: `-Algorithm "SHA256"`
#### EXAMPLE
```powershell
Get-ConcurrentHash -LiteralPath "C:\Documents" -OutputCSV "C:\output.csv" -Algorithm "SHA256"
```

Calculates the SHA256 hash for all files in the "C:\Documents" directory and its subdirectories and writes the result to "C:\output.csv".
#### NOTES
The cmdlet supports concurrent processing of files to improve performance.
