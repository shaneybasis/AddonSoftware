[[ARC_CASHCODE.ADEL]]
rem --- delete corresponding ars_cc_custsvc, ars_cc_custpmt, if applicable

	ars_cc_custpmt=fnget_dev("ARS_CC_CUSTPMT")
	ars_cc_custsvc=fnget_dev("ARS_CC_CUSTSVC")

	remove(ars_cc_custpmt,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)
	remove(ars_cc_custsvc,key=firm_id$+callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD"),dom=*next)

[[ARC_CASHCODE.AOPT-CSVC]]
rem --- launch params for AR (customer service) credit card payments

	cash_cd$=callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD")

	dim dflt_data$[1,1]
	dflt_data$[0,0]="FIRM_ID"
	dflt_data$[0,1]=firm_id$
	dflt_data$[1,0]="CASH_REC_CD"
	dflt_data$[1,1]=cash_cd$

	key_pfx$=firm_id$+cash_cd$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARS_CC_CUSTSVC",
:		stbl("+USER_ID"),
:		"",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

[[ARC_CASHCODE.AOPT-CUST]]
rem --- launch params for online customer credit card payments

	cash_cd$=callpoint!.getColumnData("ARC_CASHCODE.CASH_REC_CD")

	dim dflt_data$[1,1]
	dflt_data$[0,0]="FIRM_ID"
	dflt_data$[0,1]=firm_id$
	dflt_data$[1,0]="CASH_REC_CD"
	dflt_data$[1,1]=cash_cd$

	key_pfx$=firm_id$+cash_cd$

	call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:		"ARS_CC_CUSTPMT",
:		stbl("+USER_ID"),
:		"",
:		key_pfx$,
:		table_chans$[all],
:		"",
:		dflt_data$[all]

[[ARC_CASHCODE.BSHO]]
rem --- Disable Pos Cash Type if OP not installed
	call stbl("+DIR_PGM")+"adc_application.aon","OP",info$[all]
	if info$[20] = "N"
		ctl_name$="ARC_CASHCODE.TRANS_TYPE"
		ctl_stat$="I"
		gosub disable_fields
	endif

rem --- Disable G/L Accounts if G/L not installed
	call stbl("+DIR_PGM")+"adc_application.aon","GL",info$[all]
	if info$[20] = "N"
		ctl_name$="ARC_CASHCODE.GL_CASH_ACCT"
		ctl_stat$="I"
		gosub disable_fields
		ctl_name$="ARC_CASHCODE.GL_DISC_ACCT"
		ctl_stat$="I"
		gosub disable_fields
	endif

rem --- Open credit card param files for ADEL

	num_files=2
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_CC_CUSTPMT",open_opts$[1]="OTA"
	open_tables$[2]="ARS_CC_CUSTSVC",open_opts$[2]="OTA"
	gosub open_tables

[[ARC_CASHCODE.GL_CASH_ACCT.AVAL]]
gosub gl_inactive

[[ARC_CASHCODE.GL_DISC_ACCT.AVAL]]
gosub gl_inactive

[[ARC_CASHCODE.<CUSTOM>]]
#include [+ADDON_LIB]std_functions.aon
#include [+ADDON_LIB]std_missing_params.aon

gl_inactive:
rem "GL INACTIVE FEATURE"
   glm01_dev=fnget_dev("GLM_ACCT")
   glm01_tpl$=fnget_tpl$("GLM_ACCT")
   dim glm01a$:glm01_tpl$
   glacctinput$=callpoint!.getUserInput()
   glm01a_key$=firm_id$+glacctinput$
   find record (glm01_dev,key=glm01a_key$,err=*return) glm01a$
   if glm01a.acct_inactive$="Y" then
      call stbl("+DIR_PGM")+"adc_getmask.aon","GL_ACCOUNT","","","",m0$,0,gl_size
      msg_id$="GL_ACCT_INACTIVE"
      dim msg_tokens$[2]
      msg_tokens$[1]=fnmask$(glm01a.gl_account$(1,gl_size),m0$)
      msg_tokens$[2]=cvs(glm01a.gl_acct_desc$,2)
      gosub disp_message
      callpoint!.setStatus("ACTIVATE-ABORT")
   endif
return

disable_fields:
rem --- used to disable/enable controls depending on parameter settings
rem --- send in control to toggle (format "ALIAS.CONTROL_NAME"), and D or space to disable/enable
 
wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
wmap$=callpoint!.getAbleMap()
wpos=pos(wctl$=wmap$,8)
wmap$(wpos+6,1)=ctl_stat$
callpoint!.setAbleMap(wmap$)
callpoint!.setStatus("ABLEMAP-REFRESH-ACTIVATE")

return



