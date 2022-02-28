## TL13 Compiler

A command line application used to compile TL13 code into C.

The following errors have been implemented:

* Wrong variable type (int or bool)

* Uninitialized variable

* Undefined variable

* Divide by zero

## Installation and Setup Instructions

Clone this repository. You will need `make`, `bison`, `flex`, and `gcc` installed on your machine.  

Installation for Ubuntu:

`sudo apt-get install make bison flex gcc`  

To Run the Application:  

* Navigate to the cloned repository and run `make all`.

* Then to run the compiler type `./tl13_compiler < fibonacci.tl`
