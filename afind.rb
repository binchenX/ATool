#!/usr/bin/env ruby
# Find out which jar the file will compile into 
# And where to compile it.

pwd = `pwd`

if pwd.chomp.end_with?("framework")
    puts "run this program in framework directory"
    exit
end 

if ARGV.size != 1
    puts "usage: mfind XXXX.java"
    exit
end

debug = false
targetFile = ARGV[0]
puts "Finding where to build #{targetFile}"

target = `find . -name #{targetFile}`
allMk = `find ./base -name Android.mk`

puts allMk if debug
#Android.mk that are in the parent directory of target file
possibleMk = allMk.split("\n").select { |p| 
    t = p.split("/").clone
    t.pop
    m = t.join("/")
    target.include?(m)
}

puts possibleMk if debug

#find only the one with BUILD_JAVA_LIBRARY
possibleMk = possibleMk.select { |p|
    t = `grep -in BUILD_JAVA_LIBRARY #{p} `
    !t.empty?
}

puts possibleMk if debug

if (possibleMk.size == 0)
    puts "failed to find the Android.mk for #{target}"
    exit
end

#use the lowest parent
targetMk = possibleMk.sort.last

moduleName = []
#location of the build_java_liarary
#the target name must before this location
r = `grep -in BUILD_JAVA_LIBRARY #{targetMk}`
location = r.split(":")[0].to_i

module_name=""
t = `grep -in LOCAL_MODULE #{targetMk}`
t.split("\n").select { |e|  
    l = e.split(":")[0].to_i
    # find it
    if (l < location)
        module_name = e.split(":=")[1].strip
    end
}

puts <<OUTPUTT
Do mm in      : /framework/#{targetMk} 
The output jar: /system/framework/#{module_name}.jar"
OUTPUTT
