NOTES
=====

## zavd - Zoner AntiVirus daemon

### SYNOPSIS
`zavd ACTION [OPTIONS]`

### DESCRIPTION
Zavd is the Zoner AntiVirus daemon. It runs in the background, starts its modules and waits for scan requests from clients (or specific modules, like on-acces, mail or web scanner).

### ACTIONS
-s, --start  
start ZAVd and all its modules  
-x, --stop  
stop ZAVd and all its modules  
-r, --restart  
stop and then start ZAVd  
-v, --version  
retrieve ZAVd and scanner versions  
-u, --update  
update scanner from ZAV servers  
-t, --status  
test if ZAVd is running and print statistics  
-p, --ping  
only test if ZAVd is running  
-o, --short  
print short-term statistics  
-e, --reset  
print and reset short-term statistics  

### OPTIONS
-n, --no-daemon  
do not daemonize (for debugging)  
-c, --config-dir=DIR  
path to ZAVd configuration files  

### RETURN CODES
```
0 - success
1 - error
2 - ZAVd is already running (only for -s)
3 - ZAVd is not running (for -t, -o and -p)
4 - ZAVd is not running and has been badly terminated
5 - ZAVd is running, but shared memory is corrupted
```

## zavcli - Zoner AntiVirus command-line interface

### DESCRIPTION
Zavcli is a command-line client for Zoner AntiVirus daemon (ZAVd). All PATHs are scanned for viruses and results are printed to standard output.

### BASIC OPTIONS
-v, --version  
display zavcli version information and exit  
-V, --version-zavd  
display ZAVd version information and exit  
-h, --help  
display this help and exit  
-n, --no-recurse  
do not traverse directories  

### SCAN OPTIONS
These options override default values set for ZAVd in its configuration file:  
--(no-)scan-full  
continue to scan current file after an infection found  
--(no-)scan-heuristics  
perform heuristic analysis (can detect a previously unknown virus)  
--(no-)scan-emulation  
run PE emulator to check binaries  
--(no-)scan-archives  
decompress archives and check their content  
--(no-)scan-packers  
decompress files compressed by runtime-packers (e.g. UPX)  
--(no-)scan-gdl  
use Generic Detection Language to check files  
--(no-)scan-phishing  
enable heuristic phishing detection  
--(no-)scan-deep  
scan the whole file (not only the first few MB)  
--scan-maxsize=SIZE  
unpack only SIZE bytes from an archive  
--scan-maxfiles=NUM  
unpack up to NUM files from an archive  
--scan-recursion=NUM  
stop after reaching NUM level of nested archives (i.e. archive in archive in ...)  
--scan-timeout=TIME  
stop scanning afer TIME seconds and return partial results (will be limited by global ZAVd configuration)  
--scan-level=LEVEL  
how thorough the scanner should be: fastest, normal, advanced or brute  
--scan-dev  
do not omit /dev directory (not recommended)  
--scan-proc  
do not omit /proc directory (not recommended)  
--scan-sys  
do not omit /sys directory (not recommended)  

### PERFORMANCE OPTIONS
-t, --threads=NUM  
run zavcli in NUM threads (faster, if ZAVd runs more scanner instances)  
-w, --timeout=TIME  
disconnect from ZAVd after TIME seconds (default: 300)  

### OUTPUT OPTIONS
-q, --quiet  
be quiet (only error messages are printed)  
-s, --stats  
print overall statistics after scanning is done (number of clean files, infected files, errors, etc.)  
-i, --scan-info  
print scan time and filesize for every scanned file (e.g. " 0.000.123 12345 /tmp/file")  
--tree  
instead of only printing found virus names, print also infected sub-files (useful for archives)  
--color  
use colorized terminal output  
--show=RESTYPES  
show only RESTYPES scan results, hide the rest  
--no-show=RESTYPES  
suppress RESTYPES scan results, show the rest  
Possible RESTYPES:  
clean - files without any infection  
infected - malware pattern found  
probinfected - probably infected files (a known but uncertain pattern detected)  
suspicious - suspicious files (mostly executables and phishing files)  
nonstandard - files that are not really suspicious, but somehow different from normal files  
unknown - files with an unknown type of infection, caused by old ZAVd/ZAVCli with newer ZAVCore  
scanerror - files causing an error during scanning  
timeout - files where a user-defined timeout has been reached during scanning  
all - all of the above  
FILTERING OPTIONS  
--no-symlinks  
do not follow symbolic links  
--no-mounts  
do not follow mountpoints (do not change the device, specified by the PATH argument)  
--maxsize=SIZE  
do not scan files larger than SIZE (default: unlimited), you can append units: 'B', 'k', 'M' or 'G'  
--minsize=SIZE  
do not scan files smaller than SIZE (default: 0), you can append units: 'B', 'k', 'M' or 'G'  

### ADVANCED OPTIONS
-c, --config-dir=DIR  
path to ZAVd configuration files, used to adjust maximum number of threads and to find ZAVd socket, by default zavcli tries '/etc/zav' and '~/.zav'  
-z, --zavd-socket=FILE  
path to ZAVd socket, which is needed to scan files; use this option instead of -c when calling zavcli externally, this way no configuration file is parsed (faster)  
--conn-retries=N  
when ZAVd cannot be reached, retry N times (default: 1)  
--conn-interval=TIME  
when ZAVd cannot be reached, try again after TIME seconds (default: 1)  
--remove=RESTYPES  
remove files having RESTYPES results after scanning (use with caution)  
--copy=OPTS  
copy files after scanning, OPTS are of the form RESTYPE=DIR  

### RETURN CODES

These return codes apply either to a single file (if only one file specified) or represent the most important result from all files that have been scanned during execution (if more files/directories specified).

```
0: - clean - all files clean, no errors
1: - error - zavcli encountered an error (glibc call or syscall)
2: - scanerror - ZAVd returned an error
11: - infected - file has been infected by a known virus
12: - probably infected - file has been infected by a virus, but the detection is not doubtless
13: - suspicious - file looks supicious (virus-like behaviour of a binary, phishing attempts, possible exploits)
14: - nonstandard - file has some non-standard attributes, but is not really suspicious (only few symptoms)
15: - unknown - file has been infected by an unknown type of infection (caused by obsolete ZAVd version)
16: - timeout - the scanning has timed out
```
