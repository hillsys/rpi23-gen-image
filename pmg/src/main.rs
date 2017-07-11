//Copyright 2017 Paul Hill
//
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

extern crate rand;
use rand::Rng;
use std::env;

struct MachineAddress {
    //The MAC address or prefix that will be printed
    mac: Vec<String>,
    //Determines if a help message should print when no args are passed.
    arg_count: usize,
    //Determines the use of capitalization for hexadecimal output
    case: bool,
    //Bypasses the use of a separator between octets when true
    no_separator: bool,
    //Determines the separator to use
    separator: String,
}

impl MachineAddress {
    //Prints the octets that have been assigned to MachineAddress.mac
    fn print_octets(&self) {
        //Loop through the mac vector
        for i in 0..self.mac.len() {
            //Print the octet according to case set
            if self.case {
                print!("{}",self.mac[i].to_lowercase());
            } else {
                print!("{}",self.mac[i]);
            }


            //Only print if no_separator is false
            if !self.no_separator {
                //Print the separator between each octet skipping the last octet
                if i < self.mac.len() - 1 {
                    print!("{}",self.separator);
                }
            }
        }
    }

    //Prints 00 or FF for each octet that is assignable
    fn print_assignable_octets(&self, is_beginning: bool) {
        //Print the MAC prefix
        &self.print_octets();

        //Print the separator at end of prefix if no_separator = false
        if !self.no_separator {
            print!("{}", self.separator);
        }

        //The range is 6 octets - mac vector length (which represents octets used for prefix)
        let range = 6 - self.mac.len();

        //Loop through the assignable octets
        for i in 0..range {
            //Print assignable octet whether function is flagged for beginning or ending range.
            if is_beginning {
                //Beginning range is 00 as that is the lowest value an octet can be
                print!("00");
            } else {
                //Ending range is FF as that is the highest value an octet can be
                //Select proper casing for the ending octet based on argument
                if self.case {
                    print!("ff");
                } else {
                    print!("FF");
                }
            }
            
            //If no_separator is false then print a separator between octets
            if !self.no_separator {
                //Do not print a separator for the last octet
                if i < range -1 {
                    print!("{}", self.separator);
                }
            }
        }
    }

    //This command combines the print_octets and print_assignable_octets to
    //print out a format to display to user
    fn print(&self) {

        //Print a simple message if ran without any arguments in case the user doesn't know how
        //to access the help file.
        if self.arg_count == 1 {
            println!("No arguments were used.  Type pmg -h or pmg --help for more information.");
            println!("Generating MAC addresses for default settings: -r 1 -s : -c l");
            println!();
        }

        //Describe what type of MAC we are printing
        if self.mac.len() < 6 {
            print!("Private MAC Prefix:    ");
        } else{
            print!("Private MAC Address:   ");
        }
        
        //Print the octets that have been generated
        &self.print_octets();

        //We only need to print the assignable range if we didn't print a unique address
        if self.mac.len() < 6 {
            println!();
            //There are 256 addresses per octet, take 256 to the power of octets not randomly generated
            //There is a limit of 3 assignable octets.  Trying to take 256 to the power of 4 will result
            //in a program crash.  All companies that are assigned MAC addresses are given the first 3
            //octets, which can be looked up to determine what company made the network device.  Limiting
            //the program to only three assignable octets seems reasonable given corporations are not given
            //anything larger.  Though many corporations are assigned several prefixes for their manufacturing needs.
            println!("Assignable Addresses:  {}", (256 as i32).pow((6 - self.mac.len()) as u32));
            //The next lines displays the assignable range the has been generated.
            print!("Assigned Addresses:    ");
            self.print_assignable_octets(true);
            print!(" - ");
            self.print_assignable_octets(false);
        }
    }
}

//See parse_arguments() and Argument.create_posix_search(&self)
//parse_arguments() fills a vector of ParsedArguments based on env::args().collect()
//Argument.create_posix_search(&self) creates a ParsedArgument for searching the ParsedArgument vector
struct ParsedArgument {
    //The argument found when parsing env::args().collect()
    arg: String,
    //The value of the argument if it has one.  Defaults to empty string.
    value: String,
}

//To have the ability to search a vector of ParsedArguments against another ParsedArgument struct
//the ParsedArgument struct has to implement PartialEq trait
impl PartialEq for ParsedArgument {
    fn eq(&self, other: &ParsedArgument) -> bool {
        self.arg == other.arg
    }
}

//This is the return struct for Argument.check_args(&self, args: &Vec<ParsedArgument>) 
//It is used to determine if struct Argument has been called by user, and returns the index
//of the ParsedArgument vector created by parse_arguments()
struct ArgumentCheck {
    is_used: bool,
    parse_index: usize,
}

//Defines a POSIX and GNU argument.  This can be expanded on, but proper searches would need
//to be created in impl Argument.check_args(&self, args: &Vec<ParsedArgument>) as well
// as parse_arguments()
struct Argument {
    //POSIX syntax utilizes a single dash or hyphen - utilizing a single alphanumeric.
    //Do not enter the dash "-" before the argument.
    posix: String,
    //GNU syntax utilizes double dashes or hyphens -- utilizing full words
    //Do not enter the double dash "--" before the argument.
    gnu: String,
}

impl Argument {
    //Checks to see if ParsedArgument vector contains a value for this argument
    fn check_args(&self, args: &Vec<ParsedArgument>) -> ArgumentCheck {
        //The search mechanism for POSIX and GNU are very different.
        //For GNU we must initialize a default index.  The is_gnu flag is used
        //to bypass POSIX searching.  The posix_search variable is utilized to 
        //prevent self.create_posix_search() from being called more than one.
        let mut gnu_index: usize = 0;
        let mut is_gnu = false;
        let posix_search = self.create_posix_search();

        //Loop ParsedArgument vector
        for i in 0..args.len(){
            //See if any ParsedArgument.arg is partial/full match to current
            //GNU argument.  Note that it will match a single character up to full word.
            //It is important that no two GNU arguments begin with the same letter.
            //Otherwise, we would need to implement a minimum length to qualify a GNU
            //argument under fn parse_arguments().  Example would be two arguments named
            //no-return and no-color.  If the user typed --no instead of full syntax or at least to the 
            //fourth character no-r or no-c, both arguments would be qualified.
            if self.gnu.starts_with(args[i].arg.as_str()) {
                gnu_index = i;
                is_gnu = true;
            }
        }

        //If this is a GNU argument, pass the values
        let output = if is_gnu {
            ArgumentCheck {
                is_used: true,
                parse_index: gnu_index,
            }
        //Otherwise do a POSIX search for the values
        } else if args.contains(&posix_search) {
            ArgumentCheck {
                is_used: true,
                parse_index: args.iter().position(|value| value == &posix_search).unwrap(),
            }
        //If POSIX and GNU searches failed, return that the argument is not used with zero index.
        } else {
            ArgumentCheck {
                is_used: false,
                parse_index: 0,
            }
        };

        output
    }

    //Creates a ParsedArgument based on self posix value for searching
    //against the ParsedArgument vector created by fn parse_arguments()
    fn create_posix_search(&self) -> ParsedArgument{
        ParsedArgument {
            arg: self.posix.to_string(),
            value: "".to_string(),
        }
    }
}

struct ArgumentWithValue <T> {
    //Defines the POSIX and GNU arguments
    arg: Argument,
    //Vector containing all the accepted values expected to be typed in by user
    accepted_values: Vec<String>,
    //The return value based on the accepted values.  Both accepted and return values should
    //contain the same number of elements.  The accepted values are string values as they are used 
    //to verify what was entered by the user, the return values do not have to be the same value, just
    //what is expected to be returned back to the program when the user enters an accepted value.
    //Example:
    //    accepted_values: vec!["1".to_string(), "2".to_string(), "3".to_string()]
    //    return_values: vec![256, 65536, 16777216]
    //    User selects this argument with a value of "1".  The software will then find the index of "1"
    //    from accepted_values and use that index to return 256 since both "1" and 256 have the same index value.
    return_values: Vec<T>,
    //The default value if the argument is not used, or if someone entered a wrong value.  
    default_value: T,
}

impl <T: PartialEq> ArgumentWithValue<T> {
    //Returns the value selected by the user or the default value if the value the user
    //entered is not valid or is missing
    fn get_return_value(&self, args: &Vec<ParsedArgument>) -> &T {
        //check_args provides the index to find the value in the ParsedArgument vector
        let parse_result = &self.arg.check_args(args);
        
        //If what the user inputted is in the accepted values, get the index and return
        //the value from return_values
        let output = if self.accepted_values.contains(&args[parse_result.parse_index].value) {
                let return_index = self.accepted_values.iter()
                    .position(|value| value == &args[parse_result.parse_index].value).unwrap();
                &self.return_values[return_index]
            //Otherwise return default value.  If the user entered a wrong value display 
            //warning if the argument was passed.
            } else {
                if parse_result.is_used {
                    println!();
                    print!("Incorrect parameter usage for POSIX -{}", self.arg.posix);
                    print!(" or GNU --{}.", self.arg.gnu);
                    println!();
                    println!("Acceptable values are:  {:?}.", self.accepted_values);
                    println!("Default value will be used.  Type 'pmg -h' for more information.");
                    println!();
                };

                &self.default_value
            };

        output
    }
}

//The entry point of the application.
fn main() {
    //Get arguments for the program and parse them into usable struct
    let parsed_args = parse_arguments();
    
    //Notifies the program to bypass printing the MAC address and show help menu.
    let show_help = Argument {
            posix: "h".to_string(),
            gnu: "help".to_string(),
        }.check_args(&parsed_args).is_used;

    //Print help menu if argument was used, otherwise print the MAC address
    if show_help {
        println!("{}",print_help());
    } else {
        //This option determines how many octets will needed to be generated.
        //Because the MAC generation has to occur outside the MachineAddress struct,
        //the argument parsing is handled before initializing the MachineAddress struct.
        let octet_range = *ArgumentWithValue::<usize> {
                arg: Argument {
                    posix: "r".to_string(),
                    gnu: "range".to_string(),
                },
                accepted_values: vec!["1".to_string(), "2".to_string(), "3".to_string()],
                return_values: vec![1, 2, 3],
                default_value: 1
            }.get_return_value(&parsed_args);

        //Like octet_range, the unique argument must be parsed before calling the 
        //MachineAddress struct to determine how many octets to generate.
        let unique = Argument {
                posix: "u".to_string(),
                gnu: "unique".to_string(),
            }.check_args(&parsed_args).is_used;
            
        //Handles the printing of the MAC address
        MachineAddress {

            //Generate a MAC address based on the arguments that were parsed
            mac: generate_mac(octet_range, unique),

            //Provide the count of the arguments.  This is so the program knows
            //if any arguments were passed and if it needs to provide a specific message
            //when no arguments have been assigned.
            arg_count: parsed_args.len(),

            //Provide what case the letters are to be displayed in.
            //Default is lower case, which is true.
            case: *ArgumentWithValue::<bool> {
                arg: Argument {
                    posix: "c".to_string(),
                    gnu: "case".to_string(),
                },
                accepted_values: vec!["u".to_string(), "l".to_string(), "lower".to_string(), "upper".to_string()],
                return_values: vec![false, true],
                default_value: true
            }.get_return_value(&parsed_args),

            //Originally this was not part of the design process.  But to 
            //eliminate the creating of another string vector, I had to move
            //the no separator option of empty string from the separator argument.
            //This allows a if statement to check to see if a separator is needed
            //before printing the MAC address.
            no_separator: Argument {
                posix: "n".to_string(),
                gnu: "noSeparator".to_string(),
            }.check_args(&parsed_args).is_used,

            //As noted above, this originally defaulted to empty string.  But to remove
            //the need of a vector string for return values, the empty string had to be removed
            //as there is no character code for empty string.  This allowed the return values
            //to be stored as char values instead of strings.
            separator: ArgumentWithValue::<char> {
                arg: Argument {
                    posix: "s".to_string(),
                    gnu: "separator".to_string(),
                },
                accepted_values: vec![":".to_string(), "-".to_string(), ".".to_string()],
                return_values: vec![':', '.', '>'],
                default_value: ':'
            }.get_return_value(&parsed_args).to_string()
        }.print();

        println!();
    }
}

fn print_help() -> String {
    let output = "Help file for pmg (Private MAC Generator), a random locally administered MAC generator.

NAME
    pmg

SYNTAX POSIX
    pmg [-h] [-u] [-n] [[-r] <integer>] [[-s] <string>] [[-c] <string>]

SYNTAX GNU
    pmg [--help] [--unique] [[--range] <integer>] [[--separator] <string>] [[--case] <string>]
	
USAGE
    POSIX   GNU             NOTES
    -h      --help          Displays help message.
                            Overrides:  All
	
    -u      --unique        Generates a single MAC address.  
                            Overrides: -r/--range.
    in      --noSeparator   Generates a MAC address or prefix without a separator.
                            Overrides: -s/--separator
						
    -r      --range         Generates a MAC prefix for a range of private addresses.
                            Accepted Values:  1 2 3
                            Defaults: 1
                            Notes:  Refers to how many octets to use to generate your
                                    private MAC prefix.
                                    1 (1 octet)  =      255 assignable addresses
                                    2 (2 octets) =    65536 assignable addresses
                                    3 (3 octets) = 16777216 assignable addresses
								
    -s      --separator     The separator used for the MAC address.
                            Accepted Values:  : - .
                            Defaults:  :
						
    -c      --case          The case the hexadecimal letters are shown in.
                            Accepted Values:  l u lower upper
                            Defaults:  l

EXAMPLES
    pmg -u                  Provides a single MAC address: xxxxxxxxxxxx
    pmg -r 2 -c u -s :      Provides a MAC prefix of:  XX:XX:XX:XX
    pmg -s -                Provides a MAC prefix of:  xx-xx-xx-xx-xx					
						
REMARKS
    Providing incorrect values for arguments will result in use of default value for that argument.
    Example:  pmg -r 5 [Result will use default for -r which is 1]	
	
CONTACT INFORMATION
    Paul Hill
    paul@hillsys.org
	
Copyright 2017";

    output.to_string()
}

//Parses the env::args().collect() into a format to search against for the struct Argument.
fn parse_arguments() -> Vec<ParsedArgument> {
    //Get the arguments used
    let args: Vec<String> = env::args().collect();

    //The first argument is always the path.  Setup a mutable vector to push
    //other arguments to.
    let mut output = vec![ParsedArgument{
            arg: "path".to_string(),
            value: args[0].to_string(),
        }];

    //If there is more than 1 argument
    if args.len() > 1 {
        //Loop through all the arguments.
        for i in 0..args.len() {
            //This variable is used to see if we need to break POSIX arguments apart.
            let mut is_posix = false;
            //Set the current argument
            let mut current_arg = args[i].to_string();
            //Look ahead to next argument and capture it incase it is a value.
            let next_arg = if args.len() > i + 1 {
                args[i + 1].to_string()
            //If at end of arguments, return empty string.
            } else {
                "".to_string()
            };

            //We must first search for GNU arguments.  The reasoning is both GNU and POSIX
            //being with "-".  If we begin with POSIX searches, GNU arguments would also be
            //qualified, but would not match any Argument struct posix variable.
            let mut output_arg = if current_arg.starts_with("--") {
                //If it is a GNU argument, remove the dashes
                current_arg.split_off(2)
            //If not GNU check to see if it is POSIX
            } else if current_arg.starts_with("-") {
                is_posix = true;
                //If it is POSIX remove the dash
                current_arg.split_off(1)
            //This current_arg is not an arg at all.  The double dash is just a place holder for filtering.
            } else {
                "--".to_string()
            };

            //If the output_arg has a double dash, ignore this process.  It isn't a valid argument.
            if output_arg != "--" {
                //If not POSIX or if it is POSIX and has a length of 1
                //Look at next argument and see if it an actually argument or a value
                if !is_posix || output_arg.len() == 1 {
                    if args.len() >= i + 1 {
                        //If it doesn't begin with a dash (qualifies both GNU and POSIX arguments) it must a value
                        let arg_value = if !next_arg.starts_with("-") {
                            next_arg
                        //Otherwise this argument was not supplied a value
                        } else {
                            "".to_string()
                        };

                        //Add the argument and value to the vector
                        output.push(ParsedArgument{
                            arg: output_arg,
                            value: arg_value,
                        });
                    }
                //It is POSIX arguments chained together.  For this program, '-un' would be an example
                //which would represent generate a unique MAC address without separators
                } else {
                    //We are getting the length of the argument string
                    let range = output_arg.len();
                    //Cycle through the range of the string
                    for _ in 0..range {
                        //Add the argument to the vector by removing one character from the output_arg string
                        //These will not have values so default value to empty string.  POSIX arguments with values
                        //must be used individually and not in a combined manner.
                        output.push(ParsedArgument{
                            arg: output_arg.remove(0).to_string(),
                            value: "".to_string(),
                            });
                    };
                };
            };
        };
    };

    output
}

//Returns a random hexadecimal number
fn generate_hexadecimal() -> String {
    //Vector containing the hexadecimal digits
    let hex_values = vec!['1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'];

    //Randomize the the index.
    let index = rand::thread_rng().gen_range(0,15);

    //Return the randomly generated hexadecimal as a string
    hex_values[index].to_string()
}

//Generate a MAC address based on requested size or unique address.
fn generate_mac(range: usize, unique: bool) -> Vec<String> {
    //Vector containing the private hexadecimal digits
    let hex_values = vec!['2', '6', 'A', 'E'];

    //Randomize the the index.
    let index = rand::thread_rng().gen_range(0,4);

    //The first hexadecimal value an be between 0-f for a locally administered address.
    //The second hexadecimal value must be randomly generated from the values in the 
    //hex_values vector.  Return the two values as a string.
    //See https://en.wikipedia.org/wiki/MAC_address for details
    let first_octet = generate_hexadecimal() + &hex_values[index].to_string();

    //Assign the first octet to the vector
    let mut output = vec![first_octet];

    //Generate the index range for remaining 5 octets
    //If unique generate all 5 octets
    let index = if unique {
        5
    //Otherwise only generate the octets as requested
    } else {
        5 - range
    };

    //Insert the octets into the vector
    for _ in 0..index {
        output.push(generate_octet());
    }
    
    output
}

//Generates an octet for a MAC address by running generate_hexadecimal twice
fn generate_octet() -> String {
    generate_hexadecimal() + &generate_hexadecimal()
}