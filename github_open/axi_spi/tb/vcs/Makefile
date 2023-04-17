NOVAS_HOME=$(VERDI_HOME)
DEBUSSY_PLI=-P $(NOVAS_HOME)/share/PLI/VCS/linux64/novas.tab $(NOVAS_HOME)/share/PLI/VCS/linux64/pli.a

SIM_PATH = /home/ICer/ic_prjs/axi_spi_if/sim_axi/vcs

VLOGAN_OPTS = -work xil_defaultlib -full64 +v2k -l $(SIM_PATH)/com.log +define+SIMULATION_EN
VHDLAN_OPTS = -work xil_defaultlib -full64 


.PHONY:analysis elabroate simulate verdi
all:analysis elaborate simulate verdi

change: analysis elaborate simulate
analysis:
	vlogan $(VLOGAN_OPTS) -f file.f

elaborate:
	vcs \
	-full64 \
	-debug_pp \
	-timescale=1ns/1ps \
	-licqueue \
	-l elaborate.log \
	xil_defaultlib.axi_spi_test_transfer \
	xil_defaultlib.glbl \
	$(DEBUSSY_PLI) \
	-o $(SIM_PATH)/simv

simulate:
	$(SIM_PATH)/simv -l $(SIM_PATH)/sim.log +notimingcheck +nospecify

verdi:
	verdi \
	-f file.f \
	-ssf sim_axi.fsdb
 
clean:
	rm -rf ./64 ./csrc ./verdiLog ./*.log ./sim_axi.fsdb ./ucli.key ./inter.vpd ./novas* ./DVEfiles ./simv ./simv.daidir
