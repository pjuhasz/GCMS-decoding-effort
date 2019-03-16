# static list of file names and run ids, they must be in sync
array files[16] = [\
	"DR005388_F00001.PHYS.decoded",\
	"DR005388_F00002.PHYS.decoded",\
	"DR005388_F00003.PHYS.decoded",\
	"DR005388_F00004.PHYS.decoded",\
	"DR005388_F00005.PHYS.decoded",\
	"DR005388_F00006.PHYS.decoded",\
	"DR005388_F00007.PHYS.decoded",\
	"DR005388_F00008.PHYS.decoded",\
	"DR005388_F00009.PHYS.decoded",\
	"DR005388_F00010.PHYS.decoded",\
	"DR005631_F00001.PHYS.decoded",\
	"DR005631_F00002.PHYS.decoded",\
	"DR005631_F00003.PHYS.decoded",\
	"DR005631_F00004.PHYS.decoded",\
	"DR005631_F00005.PHYS.decoded",\
	"DR005631_F00006.PHYS.decoded"\
]
array runids[16] = [10007, 10032, 10033, 10034, 10035, 10036, 10037, 10038, 10039, 10041,\
	10008, 10015, 10018, 10023, 10024, 10025]

select = "fn = files[fi]; runid = runids[fi]"
