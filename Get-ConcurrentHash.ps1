function Get-ConcurrentHash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ParameterSetName="Path")]
        [string[]]$Path,

        [Parameter(Mandatory=$true, ParameterSetName="LiteralPath")]
        [Alias("PSPath")]
        [string[]]$LiteralPath,

        [Parameter(Mandatory=$true)]
        [string]$OutputCSV,

        [Parameter(Mandatory=$false)]
        [ValidateSet("SHA1", "SHA256", "SHA384", "SHA512", "MD5")]
        [string]$Algorithm = "MD5"
    )

    # resolve the input paths
    $resolvedPaths = if ($PSCmdlet.MyInvocation.BoundParameters["LiteralPath"]) {
        $LiteralPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }
    } else {
        $Path | ForEach-Object { (Resolve-Path $_).Path }
    }

    # C# code for FileHasher
    $code = @"
    using System;
    using System.Collections.Generic;
    using System.IO;
    using System.Security.Cryptography;
    using System.Text;
    using System.Threading;
    using System.Threading.Tasks;

    public class FileHasher {
        private string _path;
        private string _outputFile;
        private int _maxConcurrency;
        private string _algorithm;
        private SemaphoreSlim _semaphore;

        public FileHasher(string path, string outputFile, int maxConcurrency, string algorithm) {
            _path = path;
            _outputFile = outputFile;
            _maxConcurrency = maxConcurrency;
            _algorithm = algorithm;
            _semaphore = new SemaphoreSlim(maxConcurrency, maxConcurrency);
        }

        public void ProcessFiles() {
            List<Task> tasks = new List<Task>();
            string[] files = Directory.GetFiles(_path, "*.*", SearchOption.AllDirectories);

            using (StreamWriter writer = new StreamWriter(_outputFile, false, Encoding.UTF8)) {
                writer.WriteLine("Algorithm,Hash,Path");

                foreach (string file in files) {
                    tasks.Add(Task.Run(() => ProcessFile(file, writer)));
                }

                Task.WaitAll(tasks.ToArray());
            }
        }

        private void ProcessFile(string file, StreamWriter writer) {
            _semaphore.Wait();

            try {
                using (FileStream stream = File.OpenRead(file)) {
                    HashAlgorithm hashAlgorithm;
                    switch (_algorithm) {
                        case "SHA1": hashAlgorithm = SHA1.Create(); break;
                        case "SHA256": hashAlgorithm = SHA256.Create(); break;
                        case "SHA384": hashAlgorithm = SHA384.Create(); break;
                        case "SHA512": hashAlgorithm = SHA512.Create(); break;
                        default: hashAlgorithm = MD5.Create(); break;
                    }

                    byte[] hash = hashAlgorithm.ComputeHash(stream);
                    string hashString = BitConverter.ToString(hash).Replace("-", "");

                    lock (writer) {
                        string escapedFile = "\"" + file.Replace("\"", "\"\"") + "\"";
                        writer.WriteLine(_algorithm + "," + hashString + "," + escapedFile);
                    }
                }
            } finally {
                _semaphore.Release();
            }
        }
    }
"@

    # compile the C# code
    Add-Type -TypeDefinition $code

    # process each resolved path
    foreach ($resolvedPath in $resolvedPaths) {
        # create the FileHasher instance and process the files
        $fileHasher = New-Object FileHasher $resolvedPath, $OutputCSV, 8, $Algorithm
        $fileHasher.ProcessFiles()
    }
}