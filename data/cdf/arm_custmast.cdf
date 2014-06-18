[[ARM_CUSTMAST.ASHO]]
rem --- Create/embed dashboard to show aged balance

	use ::ado_util.src::util
	use ::dashboard/dashboard.bbj::Dashboard
	use ::dashboard/dashboard.bbj::DashboardCategory
	use ::dashboard/dashboard.bbj::DashboardControl
	use ::dashboard/dashboard.bbj::DashboardWidget
	use ::dashboard/dashboard.bbj::WidgetControl
	use ::dashboard/widget.bbj::Widget
	use ::dashboard/widget.bbj::BBjWidget
	use ::dashboard/widget.bbj::ChartWidget
	use ::dashboard/widget.bbj::PieChartWidget
	use ::dashboard/widget.bbj::BarChartWidget

	ctl_name$="ARM_CUSTPMTS.AVG_DAYS"
	ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
	ctl1!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	ctl_name$="<<DISPLAY>>.DSP_BALANCE"
	ctlContext=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLC"))
	ctlID=num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI"))
	ctl2!=SysGUI!.getWindow(ctlContext).getControl(ctlID)

	childWin!=SysGUI!.getWindow(ctlContext).getControl(0)
	save_ctx=SysGUI!.getContext()
	SysGUI!.setContext(ctlContext)

rem --- Create a dashboard w/ aging pie chart widget to the right of the Future control

	dashboard! = new Dashboard("CustAging",Translate!.getTranslation("AON_AGING","Customer Aging",1))
    
rem --- Create a dashboard category, or tab, that holds the widget

	dashboardCategory! = dashboard!.addDashboardCategory("Aging",Translate!.getTranslation("AON_AGING","Customer Aging",1))

rem --- Create either a pie chart or bar chart - the latter if any of the aging buckets are negative

	rem --- pie
	name$="CUSTAGNG_PIE"
	title$ = Translate!.getTranslation("AON_AGING","Customer Aging",1)
	previewText$=Translate!.getTranslation("AON_CUSTOMER_AGING_PIE","Customer aging chart",1)
	previewImage$=""
	chartTitle$ = ""
	flat = 0
	legend=0
	numSlices=6
	widgetHeight=ctl2!.getY()+ctl2!.getHeight()-ctl1!.getY()
	widgetWidth=widgetHeight+widgetHeight*.5
	
	agingDashboardPieWidget! = dashboardCategory!.addPieChartDashboardWidget(name$,title$,previewText$,previewImage$,chartTitle$,flat,legend,numSlices)
	agingPieWidget! = agingDashboardPieWidget!.getWidget()
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_FUTURE","Future",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_CURRENT","Current",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_30_DAYS","30 Days",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_60_DAYS","60 days",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_90_DAYS","90 days",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_120_DAYS","120 days",1), 0)
	agingPieWidget!.setFontScalingFactor(1.2)

	agingPieWidgetControl! = new WidgetControl(agingDashboardPieWidget!,childWin!,ctl1!.getX()+ctl1!.getWidth()+50,ctl1!.getY(),widgetWidth,widgetHeight,$$)
	agingPieWidgetControl!.setVisible(0)

	rem --- bar
	name$="CUSTAGNG_BAR"
	title$ = Translate!.getTranslation("AON_AGING","Customer Aging",1)
	previewText$=Translate!.getTranslation("AON_CUSTOMER_AGING_PIE","Customer aging chart",1)
	previewImage$=""
	chartTitle$ = ""
	domainTitle$ = ""
	rangeTitle$ = Translate!.getTranslation("AON_BALANCE","Balance",1)
	flat = 0
	orientation=BarChartWidget.getORIENTATION_VERTICAL() 
	legend=1
	agingDashboardBarWidget! = dashboardCategory!.addBarChartDashboardWidget(name$,title$,previewText$,previewImage$,chartTitle$,domainTitle$,rangeTitle$,flat,orientation,legend)
	agingBarWidget! = agingDashboardBarWidget!.getWidget()
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_FUT","Fut",1), "",0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_CUR","Cur",1), "", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_30","30",1),"", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_60","60",1), "", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_90","90",1), "", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_120","120",1), "", 0)

	agingBarWidgetControl! = new WidgetControl(agingDashboardBarWidget!,childWin!,ctl1!.getX()+ctl1!.getWidth()+50,ctl1!.getY(),widgetWidth,widgetHeight,$$)
	agingBarWidgetControl!.setVisible(0)

	callpoint!.setDevObject("dbPieWidget",agingDashboardPieWidget!)
	callpoint!.setDevObject("dbPieWidgetControl",agingPieWidgetControl!)
	callpoint!.setDevObject("dbBarWidget",agingDashboardBarWidget!)
	callpoint!.setDevObject("dbBarWidgetControl",agingBarWidgetControl!)

	SysGUI!.setContext(save_ctx)
[[ARM_CUSTMAST.ADIS]]
rem --- retrieve dashboard pie or bar chart widget and refresh for current customer/balances
rem --- pie if all balances >=0, bar if any negatives, hide if all bals are 0

	bal_fut=num(callpoint!.getColumnData("ARM_CUSTDET.AGING_FUTURE"))
	bal_cur=num(callpoint!.getColumnData("ARM_CUSTDET.AGING_CUR"))
	bal_30=num(callpoint!.getColumnData("ARM_CUSTDET.AGING_30"))
	bal_60=num(callpoint!.getColumnData("ARM_CUSTDET.AGING_60"))
	bal_90=num(callpoint!.getColumnData("ARM_CUSTDET.AGING_90"))
	bal_120=num(callpoint!.getColumnData("ARM_CUSTDET.AGING_120"))

	if !bal_fut and !bal_cur and !bal_30 and !bal_60 and !bal_90 and !bal_120

		agingPieWidgetControl!=callpoint!.getDevObject("dbPieWidgetControl")
		agingPieWidgetControl!.setVisible(0)
		agingBarWidgetControl!=callpoint!.getDevObject("dbBarWidgetControl")
		agingBarWidgetControl!.setVisible(0)

	else

		if bal_fut<0 or bal_cur<0 or bal_30<0 or bal_60<0 or bal_90<0 or bal_120<0

			agingDashboardBarWidget!=callpoint!.getDevObject("dbBarWidget")
			agingBarWidget! = agingDashboardBarWidget!.getWidget()
			agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_FUT","Fut",1), "",bal_fut)
			agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_CUR","Cur",1), "", bal_cur)
			agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_30","30",1),"", bal_30)
			agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_60","60",1), "", bal_60)
			agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_90","90",1), "", bal_90)
			agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_120","120",1), "", bal_120)
			agingBarWidget!.refresh()

			agingPieWidgetControl!=callpoint!.getDevObject("dbPieWidgetControl")
			agingPieWidgetControl!.setVisible(0)
			agingBarWidgetControl!=callpoint!.getDevObject("dbBarWidgetControl")
			agingBarWidgetControl!.setVisible(1)

		else

			agingDashboardPieWidget!=callpoint!.getDevObject("dbPieWidget")
			agingPieWidget! = agingDashboardPieWidget!.getWidget()
			agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_FUTURE","Future",1), bal_fut)
			agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_CURRENT","Current",1), bal_cur)
			agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_30_DAYS","30 Days",1), bal_30 )
			agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_60_DAYS","60 days",1), bal_60)
			agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_90_DAYS","90 days",1), bal_90)
			agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_120_DAYS","120 days",1), bal_120)
			agingPieWidget!.refresh()

			agingPieWidgetControl!=callpoint!.getDevObject("dbPieWidgetControl")
			agingPieWidgetControl!.setVisible(1)
			agingBarWidgetControl!=callpoint!.getDevObject("dbBarWidgetControl")
			agingBarWidgetControl!.setVisible(0)

		endif
	
	endif



	
[[ARM_CUSTMAST.AOPT-HCPY]]
rem --- Go run the Hard Copy form

	callpoint!.setDevObject("cust_id",callpoint!.getColumnData("ARM_CUSTMAST.CUSTOMER_ID"))
	cust$=callpoint!.getColumnData("ARM_CUSTMAST.CUSTOMER_ID")

	dim dflt_data$[2,1]
	dflt_data$[1,0]="CUSTOMER_ID_1"
	dflt_data$[1,1]=cust$
	dflt_data$[2,0]="CUSTOMER_ID_2"
	dflt_data$[2,1]=cust$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARR_DETAIL",
:		stbl("+USER_ID"),
:		"MNT",
:		"",
:		table_chans$[all],
:		"",
:		dflt_data$[all]
[[ARM_CUSTMAST.AOPT-STMT]]
rem On Demand Statement

cp_cust_id$=callpoint!.getColumnData("ARM_CUSTMAST.CUSTOMER_ID")
user_id$=stbl("+USER_ID")
key_pfx$=cp_cust_id$

dim dflt_data$[2,1]
dflt_data$[1,0]="CUSTOMER_ID"
dflt_data$[1,1]=cp_cust_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "ARR_STMT_DEMAND",
:                       user_id$,
:                   	"",
:                       key_pfx$,
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]
[[ARM_CUSTMAST.BDEL]]
rem  --- Check for Open AR Invoices
	delete_msg$=""
	cust$=callpoint!.getColumnData("ARM_CUSTMAST.CUSTOMER_ID")
	read(user_tpl.art01_dev,key=firm_id$+"  "+cust$,dom=*next)
	art01_key$=key(user_tpl.art01_dev,end=check_op_ord)
	if pos(firm_id$+"  "+cust$=art01_key$)<>1 goto check_op_ord
	delete_msg$=Translate!.getTranslation("AON_OPEN_INVOICES_EXIST_-_CUSTOMER_DELETION_NOT_ALLOWED")
	goto done_checking	
check_op_ord:
	if user_tpl.op_installed$<>"Y" goto done_checking
	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="OPE_INVHDR",open_opts$[1]="OTA"
	open_tables$[2]="OPT_INVHDR",open_opts$[2]="OTA"
	gosub open_tables
	ope01_dev=num(open_chans$[1])
	opt01_dev=num(open_chans$[2])
	read (ope01_dev,key=firm_id$+"  "+cust$,dom=*next)
	ope01_key$=key(ope01_dev,end=check_op_inv)
	if pos(firm_id$+"  "+cust$=ope01_key$)<>1 goto check_op_inv
	delete_msg$=Translate!.getTranslation("AON_OPEN_ORDERS_EXIST_-_CUSTOMER_DELETION_NOT_ALLOWED")
	goto done_checking	
check_op_inv:
	read (opt01_dev,key=firm_id$+"  "+cust$,dom=*next)
	opt01_key$=key(opt01_dev,end=done_checking)              
	if pos(firm_id$+"  "+cust$=opt01_key$)<>1 goto done_checking
	delete_msg$=Translate!.getTranslation("AON_HISTORICAL_INVOICES_EXIST_-_CUSTOMER_DELETION_NOT_ALLOWED")
done_checking:
	if delete_msg$<>""
		callpoint!.setMessage("NO_DELETE:"+delete_msg$)
		callpoint!.setStatus("ABORT")
	endif
[[ARM_CUSTMAST.CUSTOMER_NAME.AVAL]]
rem --- Set Alternate Sequence for new customers
	if user_tpl.new_cust$="Y"
		callpoint!.setColumnData("ARM_CUSTMAST.ALT_SEQUENCE",callpoint!.getUserInput())
		callpoint!.setStatus("REFRESH")
	endif
[[ARM_CUSTMAST.AREA]]
rem --- Set New Customer flag
	user_tpl.new_cust$="N"
[[ARM_CUSTMAST.BREC]]
rem --- Set New Customer flag
	user_tpl.new_cust$="Y"
[[ARM_CUSTMAST.CUSTOMER_ID.AVAL]]
rem --- Validate Customer Number
	if num(callpoint!.getUserInput(),err=*next)=0 callpoint!.setStatus("ABORT")
[[ARM_CUSTMAST.AOPT-IDTL]]
rem Invoice Dtl Inquiry
cp_cust_id$=callpoint!.getColumnData("ARM_CUSTMAST.CUSTOMER_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="CUSTOMER_ID"
dflt_data$[1,1]=cp_cust_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                       "ARR_INVDETAIL",
:                       user_id$,
:                   	"",
:                       "",
:                       table_chans$[all],
:                       "",
:                       dflt_data$[all]
[[ARM_CUSTMAST.AOPT-ORIV]]
rem Order/Invoice History Inq
rem --- assume this should only run if OP installed...
	if user_tpl.op_installed$="Y"
		cp_cust_id$=callpoint!.getColumnData("ARM_CUSTMAST.CUSTOMER_ID")
		user_id$=stbl("+USER_ID")
		dim dflt_data$[2,1]
		dflt_data$[1,0]="CUSTOMER_ID"
		dflt_data$[1,1]=cp_cust_id$
		call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:                           "ARR_ORDINVHIST",
:                           user_id$,
:                   	    "",
:                           "",
:                           table_chans$[all],
:                           "",
:                           dflt_data$[all]
	else
		msg_id$="AD_NO_OP"
		dim msg_tokens$[1]
		msg_opt$=""
		gosub disp_message
	endif
	callpoint!.setStatus("ACTIVATE")
[[ARM_CUSTMAST.AREC]]
rem --- notes about defaults, other init:
rem --- if cm$ installed, and ars01c.hold_new$ is "Y", then default arm02a.cred_hold$ to "Y"
rem --- default arm02a.slspsn_code$,ar_terms_code$,disc_code$,ar_dist_code$,territory$,tax_code$
rem --- and inv_hist_flg$ per defaults in ops10d
dim ars10d$:user_tpl.cust_dflt_tpl$
ars10d$=user_tpl.cust_dflt_rec$
callpoint!.setColumnData("ARM_CUSTDET.AR_TERMS_CODE",ars10d.ar_terms_code$)
callpoint!.setColumnUndoData("ARM_CUSTDET.AR_TERMS_CODE",ars10d.ar_terms_code$)
callpoint!.setColumnData("ARM_CUSTDET.AR_DIST_CODE",ars10d.ar_dist_code$)
callpoint!.setColumnUndoData("ARM_CUSTDET.AR_DIST_CODE",ars10d.ar_dist_code$)
callpoint!.setColumnData("ARM_CUSTDET.SLSPSN_CODE",ars10d.slspsn_code$)
callpoint!.setColumnUndoData("ARM_CUSTDET.SLSPSN_CODE",ars10d.slspsn_code$)
callpoint!.setColumnData("ARM_CUSTDET.DISC_CODE",ars10d.disc_code$)
callpoint!.setColumnUndoData("ARM_CUSTDET.DISC_CODE",ars10d.disc_code$)
callpoint!.setColumnData("ARM_CUSTDET.TERRITORY",ars10d.territory$)
callpoint!.setColumnUndoData("ARM_CUSTDET.TERRITORY",ars10d.territory$)
callpoint!.setColumnData("ARM_CUSTDET.TAX_CODE",ars10d.tax_code$)
callpoint!.setColumnUndoData("ARM_CUSTDET.TAX_CODE",ars10d.tax_code$)
callpoint!.setColumnData("ARM_CUSTDET.INV_HIST_FLG","Y")
callpoint!.setColumnUndoData("ARM_CUSTDET.INV_HIST_FLG","Y")
callpoint!.setColumnData("ARM_CUSTMAST.OPENED_DATE",date(0:"%Yd%Mz%Dz"))
callpoint!.setColumnData("ARM_CUSTMAST.RETAIN_CUST","Y")
if user_tpl.cm_installed$="Y" and user_tpl.dflt_cred_hold$="Y" 
	callpoint!.setColumnData("ARM_CUSTDET.CRED_HOLD","Y")
	callpoint!.setColumnUndoData("ARM_CUSTDET.CRED_HOLD","Y")
endif

rem --- clear out the contents of the widgets

	agingDashboardPieWidget!=callpoint!.getDevObject("dbPieWidget")
	agingPieWidget! = agingDashboardPieWidget!.getWidget()
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_FUTURE","Future",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_CURRENT","Current",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_30_DAYS","30 Days",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_60_DAYS","60 days",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_90_DAYS","90 days",1), 0)
	agingPieWidget!.setDataSetValue(Translate!.getTranslation("AON_120_DAYS","120 days",1), 0)
	agingPieWidget!.refresh()

	agingDashboardBarWidget!=callpoint!.getDevObject("dbBarWidget")
	agingBarWidget! = agingDashboardBarWidget!.getWidget()
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_FUT","Fut",1), "",0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_CUR","Cur",1), "", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_30","30",1),"", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_60","60",1), "", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_90","90",1), "", 0)
	agingBarWidget!.setDataSetValue(Translate!.getTranslation("AON_120","120",1), "", 0)
	agingBarWidget!.refresh()

	agingPieWidgetControl!=callpoint!.getDevObject("dbPieWidgetControl")
	agingPieWidgetControl!.setVisible(0)
	agingBarWidgetControl!=callpoint!.getDevObject("dbBarWidgetControl")
	agingBarWidgetControl!.setVisible(0)
[[ARM_CUSTMAST.BSHO]]
rem --- Open/Lock files
	dir_pgm$=stbl("+DIR_PGM")
	sys_pgm$=stbl("+DIR_SYP")
	num_files=7

	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
	open_tables$[2]="ARS_PARAMS",open_opts$[2]="OTA"
	open_tables$[3]="ARS_CUSTDFLT",open_opts$[3]="OTA"
	open_tables$[4]="ARS_CREDIT",open_opts$[4]="OTA"
	open_tables$[5]="ARM_CUSTDET",open_opts$[5]="OTA"
	open_tables$[6]="ART_INVHDR",open_opts$[6]="OTA"
	open_tables$[7]="ART_INVDET",open_opts$[7]="OTA"
	gosub open_tables

	gls01_dev=num(open_chans$[1])
	ars01_dev=num(open_chans$[2])
	ars10_dev=num(open_chans$[3])
	ars01c_dev=num(open_chans$[4])
	arm02_dev=num(open_chans$[5])

rem --- Dimension miscellaneous string templates

	dim gls01a$:open_tpls$[1],ars01a$:open_tpls$[2],ars10d$:open_tpls$[3],ars01c$:open_tpls$[4]
	dim arm02_tpl$:open_tpls$[5]

rem --- Retrieve parameter data
	dim info$[20]
	ars01a_key$=firm_id$+"AR00"
	find record (ars01_dev,key=ars01a_key$,err=std_missing_params) ars01a$ 
	ars01c_key$=firm_id$+"AR01"
	find record (ars01c_dev,key=ars01c_key$,err=std_missing_params) ars01c$                
	cm$=ars01c.sys_install$
	dflt_cred_hold$=ars01c.hold_new$
	gls01a_key$=firm_id$+"GL00"
	find record (gls01_dev,key=gls01a_key$,err=std_missing_params) gls01a$ 
	find record (ars10_dev,key=firm_id$+"D",err=std_missing_params) ars10d$
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	gl$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	op$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","IV",info$[all]
	iv$=info$[20]
	call stbl("+DIR_PGM")+"adc_application.aon","SA",info$[all]
	sa$=info$[20]
	dim user_tpl$:"app:c(2),gl_installed:c(1),op_installed:c(1),sa_installed:c(1),iv_installed:c(1),"+
:		"cm_installed:c(1),dflt_cred_hold:c(1),cust_dflt_tpl:c(1024),cust_dflt_rec:c(1024),new_cust:c(1),"+
:		"art01_dev:n(5)"
	user_tpl.app$="AR"
	user_tpl.gl_installed$=gl$
	user_tpl.op_installed$=op$
	user_tpl.iv_installed$=iv$
	user_tpl.sa_installed$=sa$
	user_tpl.cm_installed$=cm$
	user_tpl.dflt_cred_hold$=dflt_cred_hold$
	user_tpl.cust_dflt_tpl$=fattr(ars10d$)
	user_tpl.cust_dflt_rec$=ars10d$
	user_tpl.art01_dev=num(open_chans$[6])
	dim dctl$[17]
	if user_tpl.cm_installed$="Y"
 		dctl$[1]="ARM_CUSTDET.CREDIT_LIMIT"              
	endif
	if user_tpl.sa_installed$<>"Y" or user_tpl.op_installed$<>"Y"
 		dctl$[2]="ARM_CUSTDET.SA_FLAG"
	endif
	if ars01a.inv_hist_flg$="N"
		dctl$[3]="ARM_CUSTDET.INV_HIST_FLG"
	endif
	if user_tpl.op_installed$<>"Y"
		dctl$[3]="ARM_CUSTDET.INV_HIST_FLG"
		dctl$[4]="ARM_CUSTDET.TAX_CODE"
		dctl$[5]="ARM_CUSTDET.FRT_TERMS"
		dctl$[6]="ARM_CUSTDET.MESSAGE_CODE"
		dctl$[7]="ARM_CUSTDET.DISC_CODE"
		dctl$[8]="ARM_CUSTDET.PRICING_CODE"
	endif
	dctl$[9]="<<DISPLAY>>.DSP_BALANCE"
	dctl$[10]="<<DISPLAY>>.DSP_MTD_PROFIT"
	dctl$[11]="<<DISPLAY>>.DSP_YTD_PROFIT"
	dctl$[12]="<<DISPLAY>>.DSP_PRI_PROFIT"
	dctl$[13]="<<DISPLAY>>.DSP_NXT_PROFIT"
	dctl$[14]="<<DISPLAY>>.DSP_MTD_PROF_PCT"
	dctl$[15]="<<DISPLAY>>.DSP_YTD_PROF_PCT"
	dctl$[16]="<<DISPLAY>>.DSP_PRI_PROF_PCT"
	dctl$[17]="<<DISPLAY>>.DSP_NXT_PROF_PCT"
	gosub disable_ctls
rem --- Disable Option for Jobs if OP not installed or Job flag not set
	if op$<>"Y" or ars01a.job_nos$<>"Y"
		enable_str$=""
		disable_str$="OPM_CUSTJOBS"
		call stbl("+DIR_SYP")+"bam_enable_pop.bbj",Form!,enable_str$,disable_str$
	endif
[[ARM_CUSTMAST.<CUSTOM>]]
disable_ctls:rem --- disable selected control
    for dctl=1 to 17
        dctl$=dctl$[dctl]
        if dctl$<>""
            wctl$=str(num(callpoint!.getTableColumnAttribute(dctl$,"CTLI")):"00000")
	 wmap$=callpoint!.getAbleMap()
            wpos=pos(wctl$=wmap$,8)
            wmap$(wpos+6,1)="I"
	 callpoint!.setAbleMap(wmap$)
            callpoint!.setStatus("ABLEMAP")
        endif
    next dctl
    return
#include std_missing_params.src

