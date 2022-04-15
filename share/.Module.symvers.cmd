cmd_/home/xiaoy/share/Module.symvers := sed 's/\.ko$$/\.o/' /home/xiaoy/share/modules.order | scripts/mod/modpost    -o /home/xiaoy/share/Module.symvers -e -i Module.symvers   -T -
