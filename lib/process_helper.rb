require "process_helper/version"
require "open3"

module ProcessHelper
  def process(cmd, options = {})
    cmd = cmd.to_s
    fail 'command must not be empty' if cmd.empty?
    options = options.dup
    options_processing(options)
    Open3.popen2e(cmd) do |stdin, stdout_and_stderr, wait_thr|
      output = ''
      while line = stdout_and_stderr.gets
        output += line
      end
      puts output unless options[:puts_output] == false

      handle_exit_status(cmd, options, output, wait_thr)
      output
    end
  end

  private

  def handle_exit_status(cmd, options, output, wait_thr)
    expected_exit_status = options[:expected_exit_status] || 0
    exit_status = wait_thr.value
    return if exit_status.exitstatus == expected_exit_status

    if expected_exit_status == 0
      result_msg = 'failed'
      exit_status_msg = ''
    else
      result_msg = 'succeeded but was expected to fail'
      exit_status_msg = " (expected #{expected_exit_status})"
    end

    exception_message = "Command #{result_msg}, #{exit_status}#{exit_status_msg}. " \
    "Command: `#{cmd}`."
    puts output if options[:puts_output_only_on_exception] == true if options[:puts_output] == false
    fail exception_message
  end

  def options_processing(options)
    if options[:puts_output] && options[:puts_output_only_on_exception]
      fail "'puts_output' and 'puts_output_only_on_exception' options cannot both be true"
    end
  end
end
