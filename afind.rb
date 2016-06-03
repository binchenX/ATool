#!/usr/bin/env ruby
# Find out which jar the file will compile into 
# And where to compile it.

pwd = `pwd`

if !pwd.chomp.end_with?("frameworks")
    puts "Error: run this program in Android frameworks directory"
    exit
end 

if ARGV.size != 1
    puts "Usage: afind XXXX.java"
    exit
end

debug = false
targetFile = ARGV[0]

target = `find . -name #{targetFile}`

if target.empty?
    puts "Error: Faild to find #{targetFile}"
    exit
end

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
    puts "Error: Failed to find the Android.mk for #{target}"
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
t = `grep -in "LOCAL_MODULE\s*:=" #{targetMk}`
t.split("\n").select { |e| 
    l = e.split(":")[0].to_i
    # find it
    if (l < location)
        module_name = e.split(":=")[1].strip
    end
}

arch="arm64"
artifact = "/system/framework/#{module_name}.jar"
#There possible output
#1. module_name.jar  in framework/
#2. module_name.odex in framework/oat/arch
#3. boot-module_name.art and boot-module_name.oat file in framework/arch/
ANDROID_PRODUCT_OUT=ENV["ANDROID_PRODUCT_OUT"]

if (!ANDROID_PRODUCT_OUT.empty?)
    # check case 2
    r = %x(find #{ANDROID_PRODUCT_OUT}/system/framework -name #{module_name}.odex)
    if !r.empty?
        artifact = "/system/framework/oat/#{arch}/#{module_name}.odex (dexopt is on)"
    else
    #check case 3
        r = %x(find #{ANDROID_PRODUCT_OUT}/system/framework -name boot-#{module_name}.oat)
        if !r.empty?
            artifact = "/system/framework/#{arch}/boot-#{module_name}.oat/.art"
        end
    end
else
    puts "Waring: the output could also be .odex or .oat file. But in order to detect that you
         need to set ANDROID_PRODUCT_OUT environment"
end

puts <<OUTPUTT
Android.mk  : /framework/#{targetMk[2..-1]} 
Jar         : #{artifact}
OUTPUTT
