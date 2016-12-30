[![Travis-CI Build Status](https://travis-ci.org/thewoolleyman/process_helper.svg?branch=master)](https://travis-ci.org/thewoolleyman/process_helper) | [![Code Climate](https://codeclimate.com/github/thewoolleyman/process_helper/badges/gpa.svg)](https://codeclimate.com/github/thewoolleyman/process_helper) | [![Test Coverage](https://codeclimate.com/github/thewoolleyman/process_helper/badges/coverage.svg)](https://codeclimate.com/github/thewoolleyman/process_helper) | [Pivotal Tracker Project](https://www.pivotaltracker.com/n/projects/1117814)

# process_helper

Makes it easy to spawn Ruby sub-processes with guaranteed exit status handling, passing of lines to STDIN, and capturing of STDOUT and STDERR streams.

## Goals

* Always raise an exception on unexpected exit status (i.e. return code or `$!`)
* Combine and interleave STDOUT and STDERR streams into STDOUT (using [Open3.popen2e](http://ruby-doc.org/stdlib-2.1.5/libdoc/open3/rdoc/Open3.html#method-c-popen2e)),
  so you don't have to worry about how to capture the output of both streams.
* Provide useful options for suppressing output and including output when an exception
  is raised due to an unexpected exit status
* Provide real-time streaming of combined STDOUT/STDERR streams in addition to returning full combined output as a string returned from the method and/or in the exception.  
* Support passing multi-line input to the STDIN stream via arrays of strings.
* Allow override of the expected exit status(es) (zero is expected by default)
* Provide short forms of all options for terse, concise usage.

## Non-Goals

* Any explicit support for process forks, multiple threads, or anything other
  than a single direct child process.
* Any support for separate handling of STDOUT and STDERR streams

## Why Yet Another Ruby Process Wrapper Library?

There's many other libraries to make it easier to work with processes in Ruby (see the Resources section).  However, `process_helper` was created because none of them made it *easy* to run processes while meeting **all** of these requirements (redundant details are repeated above in Goals section):

* Combine STDOUT/STDERR output streams ***interleaved chronologically as emitted***
* Stream STDOUT/STDERR real-time ***while process is still running***, in addition to returning full output as a string and/or in an exception
* Guarantee an exception is ***always raised*** on an unexpected exit status (and allow specification of ***multiple nonzero values*** as expected exit statuses)
* Can be used ***very concisely***.  I.e. All behavior can be invoked via a single mixed-in module with single public method call using terse options with sensible defaults, no need to use IO streams directly or have any blocks or local variables declared.


## Table of Contents

* [Goals](#goals)
* [Non-Goals](#non-goals)
* [Why Yet Another Ruby Process Wrapper Library](#why-yet-another-ruby-process-wrapper-library)
* [Installation](#installation)
* [Usage](#usage)
* [Options](#options)
  * [`:expected_exit_status` (short form `:exp_st`)](#expected_exit_status-short-form-exp_st)
  * [`:include_output_in_exception` (short form `:out_ex`)](#include_output_in_exception-short-form-out_ex)
  * [`:puts_output` (short form `:out`)](#puts_output-short-form-out)
  * [`:timeout` (short form `:kill`)](#timeout-short-form-kill)
* [Warnings if failure output will be suppressed based on options](#warnings-if-failure-output-will-be-suppressed-based-on-options)  
* [Version](#version)
* [Contributing](#contributing)
* [(Un)License](#unlicense)
* [Resources](#resources)

## Installation

Add this line to your application's Gemfile:

    gem 'process_helper'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install process_helper
    
Or, if you want to avoid a Gem/RubyGems dependency, you can copy the `process_helper.rb` file from the `lib` folder directly into your project and require it:

    # from a ruby file:
    require_relative 'process_helper'
    
    # from IRB:
    require './process_helper'

    # or put the directory containing it on the load path:
    $LOAD_PATH.unshift('.')
    require 'process_helper'

## Usage

`ProcessHelper` is a Ruby module you can include in any Ruby code,
and then call `#process` to run a command, like this:

```
require 'process_helper'
include ProcessHelper
process('echo "Hello"')
```

By default, ProcessHelper will combine any STDERR and STDOUT, and output it to STDOUT,
and also return it as the result of the `#process` method.

## Options

### `:expected_exit_status` (short form `:exp_st`)

Expected Integer exit status, or array of expected Integer exit statuses.
Default value is `[0]`.

An exception will be raised by the `ProcessHelper#process` method if the
actual exit status of the processed command is not (one of) the
expected exit status(es).

Here's an example of expecting a nonzero failure exit status which matches the actual exit status
(the actual exit status of a failed `ls` command will be 1 on OSX, 2 on Linux):

```
# The following will NOT raise an exception:
process('ls /does_not_exist', expected_exit_status: [1,2])
```

...but it **WILL** still print the output (in this case STDERR output from the failed `ls`
command) to STDOUT:

```
ls: /does_not_exist: No such file or directory
```

Here's a second example of expecting a nonzero failure exit status but the command succeeds:

```
# The following WILL raise an exception:
process('printf FAIL', expected_exit_status: 1)
```

Here's the output of the above example:

```
FAIL
ProcessHelper::UnexpectedExitStatusError: Command succeeded but was expected to fail, pid 62974 exit 0 (expected [1]). Command: `printf FAIL`. Command Output: "FAIL"
```

### `:include_output_in_exception` (short form `:out_ex`)

Boolean flag indicating whether output should be included in the message of the Exception (error)
which will be raised by the `ProcessHelper#process` method if the command fails (has an unexpected exit status).

Here's an example of a failing command:

```
process('ls /does_not_exist', include_output_in_exception: true)
```

Here's the exception generated by the above example.  Notice the "Command Output"
with the *"...No such file or directory"* STDERR output of the failed command:

```
ProcessHelper::UnexpectedExitStatusError: Command failed, pid 64947 exit 1. Command: `ls /does_not_exist`. Command Output: "ls: /does_not_exist: No such file or directory
"
```

### `:puts_output` (short form `:out`)

Valid values are `:always`, `:error`, and `:never`.  Default value is `:always`.

* `:always` will always print output to STDOUT
* `:error` will only print output to STDOUT if command has an
  error - i.e. non-zero or unexpected exit status
* `:never` will never print output to STDOUT

### `:timeout` (short form `:kill`)

***WARNING! This option is beta and will be changed in a future release!***

Valid value is a float, e.g. `1.5`.  Default value is nil/undefined.

* Currently controls how long `process_helper` will wait to read from
  a blocked IO stream before timing out (via [IO.select](http://ruby-doc.org/core-2.2.0/IO.html#method-c-select)).  For example, invoking `cat` with no arguments, which by default will continue accepting input until killed.
* If undefined (default), there will be no timeout, and `process_helper` will hang if a process hangs while waiting to read from IO.

***The following changes are planned for this option:***

* Add validation of value (enforced to be a float).
* Add ability for the timeout value to also kill long running processes which are ***not*** in blocked waiting on an IO stream read (i.e. kill process regardless of any IO state, not just via [IO.selects](http://ruby-doc.org/core-2.2.0/IO.html#method-c-select) timeout support).
* Have both types of timeouts raise different and unique exception classes.
* Possibly have different option names to allow different timeout values for the two types of timeouts.

See [https://www.pivotaltracker.com/story/show/93303096](https://www.pivotaltracker.com/story/show/93303096) for more details.



## Warnings if failure output will be suppressed based on options

ProcessHelper will give you a warning if you pass a combination of options that would
prevent **ANY** output from being printed or included in the Exception message if
a command were to fail.

For example, in this case there is no output, and the expected exit status includes
the actual failure status which is returned, so the warning is printed, and the only
place the output will be seen is in the return value of the `ProcessHelper#process` method:

```
> process('ls /does_not_exist', expected_exit_status: [1,2], puts_output: :never, include_output_in_exception: false)
WARNING: Check your ProcessHelper options - :puts_output is :never, and :include_output_in_exception is false, so all error output will be suppressed if process fails.
 => "ls: /does_not_exist: No such file or directory\n"
 ```

## Version

You can see the version of ProcessHelper in the `ProcessHelper::VERSION` constant:

```
ProcessHelper::VERSION
=> "0.0.1"
```

## Contributing

1. Fork it ( https://github.com/thewoolleyman/process_helper/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. If you are awesome, use `git rebase --interactive` to ensure
   you have a single atomic commit on your branch.
6. Create a new Pull Request

## (Un)License

`process_helper` is (un)licensed under the [unlicense](http://unlicense.org/).  So, feel free to copy it into your project (it's usable as a single required file and module), use it, abuse it, do what you will, no attribution required. :)

## Resources

Other Ruby Process tools/libraries

* [open4](https://github.com/ahoward/open4) - a solid and useful library - the main thing I missed in it was easily combining real-time streaming interleaved STDOUT/STDERR streams
* [open4 on ruby toolbox](https://www.ruby-toolbox.com/projects/open4) - see if there's some useful higher-level gem that depends on it and gives you functionality you may need
* A great series of blog posts by Devver:
  * [https://devver.wordpress.com/2009/06/30/a-dozen-or-so-ways-to-start-sub-processes-in-ruby-part-1/](https://devver.wordpress.com/2009/06/30/a-dozen-or-so-ways-to-start-sub-processes-in-ruby-part-1/)
  * [https://devver.wordpress.com/2009/07/13/a-dozen-or-so-ways-to-start-sub-processes-in-ruby-part-2/](https://devver.wordpress.com/2009/07/13/a-dozen-or-so-ways-to-start-sub-processes-in-ruby-part-2/)
  * [https://devver.wordpress.com/2009/10/12/ruby-subprocesses-part_3/](https://devver.wordpress.com/2009/10/12/ruby-subprocesses-part_3/)



