[[ADM_VENDRPT_CTL.FAX_YN.AVAL]]
if callpoint!.getColumnData("ADM_VENDRPT_CTL.FAX_YN")="Y"
	APM_EMAILFAX_dev=fnget_dev("APM_EMAILFAX")
	APM01_dev=fnget_dev("APM_VENDMAST")
	dim APM_EMAILFAX$:fnget_tpl$("APM_EMAILFAX")
	dim APM01a$:fnget_tpl$("APM_VENDMAST")

	readrecord (APM_EMAILFAX_dev,key=firm_id$+callpoint!.getColumnData("ADM_VENDRPT_CTL.VENDOR_ID"),dom=*next)APM_EMAILFAX$
	readrecord (APM01_dev,key=firm_id$+callpoint!.getColumnData("ADM_VENDRPT_CTL.VENDOR_ID"),dom=*next)APM01a$	

	if cvs(callpoint!.getColumnData("ADM_VENDRPT_CTL.FAX_NOS"),3)=""
		callpoint!.setColumnData("ADM_VENDRPT_CTL.FAX_NOS",APM_EMAILFAX.fax_nos$)	
	endif
	if cvs(callpoint!.getColumnData("ADM_VENDRPT_CTL.VENDOR_NAME"),3)=""
		callpoint!.setColumnData("ADM_VENDRPT_CTL.VENDOR_NAME",APM01a.vendor_name$)
	endif
	if cvs(callpoint!.getColumnData("ADM_VENDRPT_CTL.FAX_TO"),3)=""
		callpoint!.setColumnData("ADM_VENDRPT_CTL.FAX_TO",APM_EMAILFAX.fax_to$)
	endif
endif

callpoint!.setStatus("REFRESH")
[[ADM_VENDRPT_CTL.EMAIL_YN.AVAL]]
if callpoint!.getColumnData("ADM_VENDRPT_CTL.EMAIL_YN")="Y"
	APM_EMAILFAX_dev=fnget_dev("APM_EMAILFAX")
	APM01_dev=fnget_dev("APM_VENDMAST")
	dim APM_EMAILFAX$:fnget_tpl$("APM_EMAILFAX")
	dim APM01a$:fnget_tpl$("APM_VENDMAST")

	readrecord (APM_EMAILFAX_dev,key=firm_id$+callpoint!.getColumnData("ADM_VENDRPT_CTL.VENDOR_ID"),dom=*next)APM_EMAILFAX$
	readrecord (APM01_dev,key=firm_id$+callpoint!.getColumnData("ADM_VENDRPT_CTL.VENDOR_ID"),dom=*next)APM01a$	

	if cvs(callpoint!.getColumnData("ADM_VENDRPT_CTL.EMAIL_TO"),3)=""
		callpoint!.setColumnData("ADM_VENDRPT_CTL.EMAIL_TO",APM_EMAILFAX.email_to$)	
	endif
	if cvs(callpoint!.getColumnData("ADM_VENDRPT_CTL.EMAIL_CC"),3)=""
		callpoint!.setColumnData("ADM_VENDRPT_CTL.EMAIL_CC",APM_EMAILFAX.email_cc$)
	endif
endif

callpoint!.setStatus("REFRESH")
[[ADM_VENDRPT_CTL.BSHO]]
rem -- open apm_emailfax to get defaults

num_files=1
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="APM_EMAILFAX",open_opts$[1]="OTA"
gosub open_tables
