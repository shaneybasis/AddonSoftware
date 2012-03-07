[[SFE_WOCOPY.ASVA]]
rem --- Now populate data from the old WO to the new

	wo_loc$=callpoint!.getDevObject("wo_loc")
	to_wo$=callpoint!.getDevObject("wo_no")
	from_wo$=callpoint!.getColumnData("SFE_WOCOPY.WO_NO")
	adjust$=callpoint!.getDevObject("adjust")
	adjust_divisor=callpoint!.getDevObject("adj_div")
	if adjust_divisor=0 adjust_divisor=num(callpoint!.getDevObject("prod_qty"))
	for files=1 to 3
		if files=1
			woreq_dev=fnget_dev("SFE_WOOPRTN")
			woreq_devout=num(callpoint!.getDevObject("copy_ops"))
			dim woreq$:fnget_tpl$("SFE_WOOPRTN")
		endif
		if files=2
			woreq_dev=fnget_dev("SFE_WOMATL")
			woreq_devout=num(callpoint!.getDevObject("copy_mtl"))
			dim woreq$:fnget_tpl$("SFE_WOMATL")
		endif
		if files=3
			woreq_dev=fnget_dev("SFE_WOSUBCNT")
			woreq_devout=num(callpoint!.getDevObject("copy_sub"))
			dim woreq$:fnget_tpl$("SFE_WOSUBCNT")
		endif
		read(woreq_dev,key=firm_id$+wo_loc$+from_wo$,dom=*next)

		while 1
			read record (woreq_dev,end=*break)woreq$
			if pos(firm_id$+wo_loc$+from_wo$=woreq$)<>1 break
			woreq.wo_no$=to_wo$
			if adjust$="N"
				if files=1
					woreq.runtime_hrs=woreq.total_time/adjust_divisor
					woreq.unit_cost=woreq.tot_std_cost/adjust_divisor
				else
					woreq.units=woreq.total_units/adjust_divisor
					woreq.unit_cost=woreq.total_cost/adjust_divisor
				endif
			else
				if files=1
					woreq.total_time=woreq.total_time*adjust_divisor/adjust_divisor
					woreq.tot_std_cost=adjust_divisor*woreq.unit_cost
				else
					woreq.total_units=woreq.total_units*adjust_divisor/adjust_divisor
					woreq.total_cost=adjust_divisor*woreq.unit_cost
				endif
			endif
			if files=3
				woreq.po_no$=""
				woreq_po_line_no$=""
			endif
			woreq$=field(woreq$)
			write record (woreq_devout) woreq$
		wend
	next files

rem --- Copy Comments

	wocomm_dev=fnget_dev("SFE_WOCOMNT")
	womcomm_devout=num(callpoint!.getDevObject("copy_comm"))
	dim wocomm$:fnget_tpl$("SFE_WOCOMNT")
	read(wocomm_dev,key=firm_id$+wo_loc$+from_wo$,dom=*next)

	while 1
		read record (wocomm_dev,end=*break)wocomm$
		if pos(firm_id$+wo_loc$+from_wo$=wocomm$)<>1 break
		wocomm.wo_no$=to_wo$
		wocomm$=field(wocomm$)
		write record (wocomm_devout) wocomm$
	wend

[[SFE_WOCOPY.BEND]]
rem --- Close copy channel

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_WOMASTR",open_opts$[1]="X[2_]"
	open_tables$[2]="SFE_WOOPRTN",open_opts$[2]="X[2_]"
	open_tables$[3]="SFE_WOMATL",open_opts$[3]="X[2_]"
	open_tables$[4]="SFE_WOSUBCNT",open_opts$[4]="X[2_]"
	open_tables$[5]="SFE_WOCOMNT",open_opts$[5]="X[2_]"
	gosub open_tables
[[SFE_WOCOPY.BSHO]]
rem --- Open tables for use during copy

	num_files=5
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="SFE_WOMASTR",open_opts$[1]="OTA[2_]"
	open_tables$[2]="SFE_WOOPRTN",open_opts$[2]="OTA[2_]"
	open_tables$[3]="SFE_WOMATL",open_opts$[3]="OTA[2_]"
	open_tables$[4]="SFE_WOSUBCNT",open_opts$[4]="OTA[2_]"
	open_tables$[5]="SFE_WOCOMNT",open_opts$[5]="OTA[2_]"
	gosub open_tables

	callpoint!.setDevObject("copy_chan",open_chans$[1])
	callpoint!.setDevObject("copy_ops",open_chans$[2])
	callpoint!.setDevObject("copy_mtl",open_chans$[3])
	callpoint!.setDevObject("copy_sub",open_chans$[4])
	callpoint!.setDevObject("copy_comm",open_chans$[5])
[[SFE_WOCOPY.WO_NO.AVAL]]
rem --- Populate display fields

	wo_dev=num(callpoint!.getDevObject("copy_chan"))
	dim wo_mastr$:fnget_tpl$("SFE_WOMASTR")
	wo_loc$=callpoint!.getDevObject("wo_loc")

	new_wo$=callpoint!.getDevObject("wo_no")

	read record (wo_dev,key=firm_id$+wo_loc$+callpoint!.getUserInput()) wo_mastr$

	callpoint!.setColumnData("<<DISPLAY>>.CLOSED_DATE",wo_mastr.closed_date$,1)
	callpoint!.setColumnData("<<DISPLAY>>.OPENED_DATE",wo_mastr.opened_date$,1)
	if wo_mastr.wo_status$="C"
		old_qty=wo_mastr.qty_cls_todt
	else
		old_qty=wo_mastr.sch_prod_qty
	endif
	callpoint!.setColumnData("<<DISPLAY>>.SCH_PROD_QTY",str(old_qty),1)

rem --- Check to make sure the category is the same

	if callpoint!.getDevObject("category")<>wo_mastr.wo_category$
		dim msg_tokens$[1]
		msg_id$="SF_DIFF_CAT"
		if msg_opt$="N"
			callpoint!.setUserInput("")
			break
		endif
	endif

rem --- Check for quantity difference

	callpoint!.setDevObject("adjust","N")
	callpoint!.setDevObject("adj_div",0)
	if num(callpoint!.getDevObject("prod_qty"))<>old_qty
		dim msg_tokens$[1]
		msg_id$="SF_ADJUST_QTY"
		if msg_opt$="N"
			adjust_divisor=num(callpoint!.getDevObject("prod_qty"))
		else
			adjust_divisor=old_qty
		endif
		callpoint!.setDevObject("adj_div",adjust_divisor)
		callpoint!.setDevObject("adjust",msg_opt$)
	endif
