[[OPE_CREDITACTION.BSHO]]
rem --- Get credit password

	num_files=1
	dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
	open_tables$[1]="ARS_CREDIT", open_opts$[1]="OTA"

	gosub open_tables

	credit_dev=num(open_chans$[1])
	dim credit_rec$:open_tpls$[1]
	dim user_tpl$:"password:c(6*)"
	start_block = 1

	if start_block then
		find record(credit_dev, key=firm_id$+"AR01", dom=*endif) credit_rec$
		user_tpl.password$ = cvs(credit_rec.cred_passwd$, 2)
	endif
	
[[OPE_CREDITACTION.ARAR]]
rem --- Display default status

	credit_action = num(callpoint!.getColumnData("OPE_CREDITACTION.CREDIT_ACTION"))
	gosub display_status
[[OPE_CREDITACTION.<CUSTOM>]]
rem ==========================================================================
display_status: rem --- Display Status by Action
rem                      IN: credit_action
rem ==========================================================================

    switch credit_action 
		case 1
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", "Order will be Held")
			break
		case 2
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", "Customer's Orders will be Held")
			break
		case 3
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", "Order will be Released")
			break
		case 4
			callpoint!.setColumnData("OPE_CREDITACTION.CREDIT_STATUS", "Order will be Deleted")
			break
		case default
	swend

	callpoint!.setStatus("REFRESH")

return
[[OPE_CREDITACTION.ASVA]]
rem --- Make sure everything is entered

	credit_action = num(callpoint!.getColumnData("OPE_CREDITACTION.CREDIT_ACTION"))
	terms$ = callpoint!.getColumnData("OPE_CREDITACTION.AR_TERMS_CODE")
	pswd$ = callpoint!.getColumnData("OPE_CREDITACTION.ENTER_CRED_PSWRD")

	switch credit_action

	rem --- Hold this order

		case 1
			break

	rem --- Hold all future orders

		case 2

			if pswd$ <> user_tpl.password$ then
				msg_id$ = "OP_INVALID_PASSWD"
				gosub disp_message
				callpoint!.setStatus("ABORT")
			endif

			break

	rem --- Release this order

		case 3

			abort = 0

			if terms$ = "" then 
				msg_id$ = "OP_TERM_NOT_ENTERED"
				gosub disp_message
				abort = 1
			else
				callpoint!.setDevObject("new_terms_code", terms$)
			endif

			if pswd$ <> user_tpl.password$ then
				msg_id$ = "OP_INVALID_PASSWD"
				gosub disp_message
				abort = 1
			endif

			if abort then callpoint!.setStatus("ABORT")

			break

	rem --- Delete this order
	rem --- (There is currently no way to do this programmatically so the message just informs the user to do it herself)

		case 4

			rem msg_id$="OP_REALLY_DELETE"
			rem gosub disp_message
			rem if msg_opt$<>"Y" then callpoint!.setStatus("ABORT")

			msg_id$ = "OP_PLS_DELETE_ORD"
			gosub disp_message

			break

		case default

	swend
[[OPE_CREDITACTION.CREDIT_ACTION.AVAL]]
rem --- Send back credit action response

	
	credit_action = num(callpoint!.getUserInput())
	gosub display_status
	callpoint!.setDevObject("credit_action", callpoint!.getUserInput())
