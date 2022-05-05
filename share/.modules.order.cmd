cmd_/home/xiaoy/share/modules.order := {   echo /home/xiaoy/share/hello.ko; :; } | awk '!x[$$0]++' - > /home/xiaoy/share/modules.order
