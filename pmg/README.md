# pmg
## Private MAC Generator.  Randomly create locally administered MAC addresses.

### SYNTAX POSIX
    pmg [-h] [-u] [-n] [[-r] <integer>] [[-s] <string>] [[-c] <string>]

### SYNTAX GNU
    pmg [--help] [--unique] [[--range] <integer>] [[--separator] <string>] [[--case] <string>]
	
### USAGE
POSIX | GNU | NOTES | Overrides | Accepted Values | Default
----- | --- | ----- | --------- | --------------- | -------
-h | --help | Displays help message. | All	| None | None
-u | --unique | Generates a single MAC address. | -r/--range. | None | None
-n | --noSeparator | Generates a MAC address or prefix without a separator. | -s/--separator | None | None					
-r | --range | Generates a MAC prefix for a range of private addresses. | None | 1, 2, 3 | 1						
-s | --separator | The separator used for the MAC address. | None | :, -, . | :		
-c | --case | The case the hexadecimal letters are shown in. | None | l, u, lower, upper | l, lower

### Range Notes
    Range refers to how many octets to use to generate your private MAC prefix.
Octets | Assignable Addresses
------ | --------------------
1 | 255
2 | 65536
3 | 16777216	

### EXAMPLES
    pmg -u                  Provides a single MAC address: xxxxxxxxxxxx
    pmg -r 2 -c u -s :      Provides a MAC prefix of:  XX:XX:XX:XX
    pmg -s -                Provides a MAC prefix of:  xx-xx-xx-xx-xx
											
### REMARKS
    Providing incorrect values for arguments will result in use of default value for that argument.
    Example:  pmg -r 5 [Result will use default for -r which is 1]	
	
### CONTACT INFORMATION
    Paul Hill
    paul@hillsys.org
	
### Copyright 2017
