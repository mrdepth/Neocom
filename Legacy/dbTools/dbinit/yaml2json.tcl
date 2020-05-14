package require yaml
set h [::yaml::yaml2huddle -file $argv]
puts [huddle jsondump $h]

