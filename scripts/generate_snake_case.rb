# Generates a snake case function wrapper file from amx-lib-volume.axi.

class String
  def to_snake_case
    self.gsub(/([A-Z0-9])/, '_\1').downcase
  end
end


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


license = File.open('../license.txt').read

if license.empty?
  puts 'COULD NOT READ LICENSE FILE'
  exit
end

str = File.open('../amx-lib-volume.axi').read
matches = []

while str =~ fn_exp
  matches << $~
  str = $'
end

File.open('../amx-lib-volume-sc.axi', 'w') do |f|
  f.puts '(***********************************************************'
  f.puts '    AMX VOLUME CONTROL LIBRARY'
  f.puts "    #{File.open('../amx-lib-volume.axi').read.lines[2].strip}" # Version
  f.puts '    '
  f.puts '    Website: https://sourceforge.net/projects/amx-lib-volume/'
  f.puts '    '
  f.puts '    This is a snake case wrapper for the volume control'
  f.puts '    library functions. For more information, see:'
  f.puts '    '
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
