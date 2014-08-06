# Generates a snake case function wrapper file from amx-lib-volume.axi.

require 'rake'
require 'rake/tasklib'


class String
  def to_snake_case
    self.gsub(/([A-Z0-9])/, '_\1').downcase
  end
end

module AMXLibVolume
  module Rake
    
    # Copy .src file and append .zip.
    class GenerateSnakeCase < ::Rake::TaskLib
      
      attr_accessor :name
      
      def initialize name = :generate_snake_case
        @name = name
        yield self if block_given?
        define
      end
      
      
      protected
      
      def define
        desc "Generates a snake case function wrapper file from amx-lib-volume.axi."
        
        task(name) do
          original_file   = 'amx-lib-volume.axi'
          snake_case_file = 'amx-lib-volume-sc.axi'
          
          fn_exp = /
          (?#
            Pull out comment\\description above the function, enclosed in slash\\star syntax.
            Does not have to exist.
          )
          ^(?<desc>[\t ]*\/\*(?:[^\*]|\*[^\/])*\*\/)?\s*

          (?# Find the function definition. )
          define_function\s+

          (?# Capture function's return type, if it exists.)
          (?<rtn>\w+(?<width>\[\d+\])?)??\s*

          (?# Capture the function name. )
          (?<name>\w+)

          (?#
            Capture the function parameters.
            Run this through another regex to get the type\\name pairs.
          )
          \(\s*(?<params>.*?)\s*\)\s*

          (?# Capture the function's source code. )
          {[\r\n]*(?<code>(?:.|\r|\n)*?)?[\r\n]*}
          /x

          param_exp = /\s*(?:(?<type>\w+)\s+(?<name>\w+)(?:\[(?<width>\d*)\])?),?\s*/


          license = File.open('license.txt').read

          if license.empty?
            puts 'COULD NOT READ LICENSE FILE'
            exit
          end
          
          puts "Generating #{File.basename snake_case_file}..."

          str = File.open(original_file).read
          matches = []

          while str =~ fn_exp
            matches << $~
            str = $'
          end

          File.open(snake_case_file, 'w') do |f|
            f.puts '(***********************************************************'
            f.puts '    AMX VOLUME CONTROL LIBRARY'
            f.puts "    #{File.open(original_file).read.lines[2].strip}" # Version
            f.puts '    '
            f.puts '    Website: https://github.com/amclain/amx-lib-volume'
            f.puts '    '
            f.puts '    This is a snake case wrapper for the volume control'
            f.puts '    library functions. To use this file, make sure to include'
            f.puts '    amx-lib-volume.axi in the workspace.'
            f.puts '    '
            f.puts '    For more information, see:'
            f.puts '        amx-lib-volume.axi'
            f.puts '    '
            f.puts '*************************************************************'
            f.puts license
            f.puts '************************************************************)'
            f.puts ''
            f.puts "#include 'amx-lib-volume'"
            f.puts ''
            f.puts '#if_not_defined AMX_LIB_VOLUME_SC'
            f.puts '#define AMX_LIB_VOLUME_SC 1'
            f.puts '(***********************************************************)'
            f.puts ''
            
            matches.each do |match|
              rtn = match[:rtn] ? match[:rtn] + ' ' : nil
              
              # Retrieve params.
              params = []
              str = match[:params]
              while str =~ param_exp
                params << $~
                str = $'
              end
              
              param_str   = params.map { |param|
                s  = "#{param[:type]} #{param[:name]}"
                s += "[#{param[:width]}]" if param[:width]
                s
              }.join(', ')
              
              calling_str = params.map { |param| param[:name] }.join(', ')
              
              f.puts match[:desc] if match[:desc]
              f.puts "define_function #{rtn}#{match[:name].to_snake_case}(#{param_str})"
              f.puts "{"
              f.puts "    #{'return ' if rtn}#{match[:name]}(#{calling_str});"
              f.puts "}"
              f.puts "" if match != matches.last
            end
            
            f.puts ''
            f.puts '(***********************************************************)'
            f.puts '#end_if'
          end
          
          puts 'Done.'
          puts ''
        end
      end
      
    end
    
  end
end
