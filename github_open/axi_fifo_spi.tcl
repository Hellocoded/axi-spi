#**************W/R CONTROL**************
set data_list ""
set num 1

proc ReadReg { address } {
global data_list
global num
create_hw_axi_txn read_txn [get_hw_axis hw_axi_1] -address $address -type read
run_hw_axi  read_txn
set read_value [lindex [report_hw_axi_txn  read_txn] 1];#返回接收大到的值
append data_list [format %3i $num] 
append data_list [format %3s r]
append data_list [format %10s $address]
append data_list [format "%10s\n" $read_value]
delete_hw_axi_txn read_txn
incr num
set tmp 0x
append tmp $read_value
return $tmp
}

proc WriteReg { address data } {
global data_list
global num
create_hw_axi_txn write_txn [get_hw_axis hw_axi_1] -address $address -data $data -type write
run_hw_axi  write_txn
set write_value [lindex [report_hw_axi_txn  write_txn] 1];
append data_list [format %3i $num] 
append data_list [format %3s w]
append data_list [format %10s $address]
append data_list [format "%10s\n" $write_value]
delete_hw_axi_txn write_txn
incr num
}

proc Write_Cmd{ cmd ByteCount} {
global rx_reg_data
#global rx_adc_data
global i = 500
WriteReg 0x4000000C cmd

if($ByteCount == 1) {WriteReg 0x40000004 0x00002002}
elseif($ByteCount == 2){WriteReg 0x40000004 0x00002022}
elseif($ByteCount == 4){WriteReg 0x40000004 0x00002042}

while{[ReadReg 0x40000008]} {
} 

set rx_adc_data [ReadReg 0x40000008]

 return $rx_adc_data
}

WriteReg 0x40000000 0x00000102

Write_Cmd 0x00000011 1

Write_Cmd 0x00000040 1

Write_Cmd 0x00000000 1

Write_Cmd 0x000000FF 1

Write_Cmd 0x00000020 1

Write_Cmd 0x00000000 1

Write_Cmd 0x00000000 1

Write_Cmd 0x00000010 1
global i
global adc_data
for {set i 0} {$i <= 160003} {incr i} {
adc_data = [Write_Cmd 0x00000000 4]
puts "value of adc data: $adc_data"
}


#**************USER**************
# WriteReg 40000000 12345678
 
# if {[ReadReg 00000000] == 0x00005678} {
#   puts "**************\n\
#   write success!\n\
#   **************\n"
# } else {
#   puts "**************\n\
#   write success!\n\
#   **************\n"
# }

#**************IO CONTROL**************
set currentTime [clock seconds]
set ctime "The time is: \
[clock format $currentTime -format %D] \
[clock format $currentTime -format  %H:%M:%S] \n"
#需编辑自定义文件路径
set file_name "D:/project/axi_spi_rev2/data.txt" 
set fp [open $file_name a+] 
puts $fp $ctime
puts $fp $adc_data                   
close $fp
set fp [open $file_name r]
set file_data [read $fp]
puts $file_data
close $fp
