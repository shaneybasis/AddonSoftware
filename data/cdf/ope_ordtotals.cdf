[[OPE_ORDTOTALS.ARAR]]
print "OPE_ORDTOTALS:ARAR"; rem debug

rem --- Get order header record and totals

	use ::ado_order.src::OrderHelper

	gosub get_ordhdr_rec
	ordHelp!.totalSalesDisk()

rem --- Get upper level sales tax
	
	gosub get_sales_tax

rem --- Get Amount mask

	call stbl("+DIR_PGM")+"adc_getmask.aon","","IV","A","",amount_mask$,0,mask_len

rem --- Get previous and current discounts

	file_name$ = "OPC_DISCCODE"
	disccode_dev = fnget_dev(file_name$)
	dim disccode_rec$:fnget_tpl$(file_name$)

	find record (disccode_dev, key=firm_id$+ordhdr_rec.disc_code$, dom=*next) disccode_rec$
	new_disc_per = disccode_rec.disc_percent

	find record (disccode_dev, key=firm_id$+user_tpl.prev_disc_code$, dom=*next) disccode_rec$
	old_disc_per = disccode_rec.disc_percent

	print "---Prev Sales Total:", user_tpl.prev_sales_total; rem debug

	if user_tpl.prev_sales_total <> 0 then
		calc_prev_disc_per = 100 * ordhdr_rec.discount_amt / user_tpl.prev_sales_total
	else
		calc_prev_disc_per = 0
	endif

rem --- Change discount?

	msg_opt$ = ""

rem --- A discount code or amount has been previously entered and the discount amt doesn't match the old discount percentage

	if (user_tpl.prev_disc_code$ <> "" or ordhdr_rec.discount_amt <> 0) and 
:		(user_tpl.prev_sales_total = 0 or ordhdr_rec.discount_amt <> old_disc_per * user_tpl.prev_sales_total / 100)
:	then 
		rem saved_new_disc = new_disc_per

		if user_tpl.prev_sales_total <> 0 then 
			disc_per_in = calc_prev_disc_per
		else
			disc_per_in = old_disc_per
		endif

		if ordHelp!.getExtPrice() <> user_tpl.prev_sales_total	or 
:			ordhdr_rec.disc_code$ <> user_tpl.prev_disc_code$		or
:			disc_per_in * ordHelp!.getExtPrice() / 100 <> ordhdr_rec.discount_amt
:		then
			gosub tax_calc
			rem gosub display_fields

		rem --- Replace discounts?

			new_disc_amt = saved_new_disc * ordHelp!.getExtPrice() / 100

			msg_id$ = "OP_REPLACE_DISC"
			dim msg_tokens$[4]
			msg_tokens$[1] = cvs( str(disc_per_in:"##0.00-"), 3) + "%"
			msg_tokens$[2] = cvs( str(ordhdr_rec.discount_amt:amount_mask$), 3)
			msg_tokens$[3] = cvs( str(new_disc_per:"##0.00-"), 3) + "%"
			msg_tokens$[4] = cvs( str(new_disc_amt:amount_mask$), 3)
			gosub disp_message

			if msg_opt$ = "N" then new_disc_per = disc_per_in
			
		endif
	endif

	if msg_opt$ <> "N" then ordhdr_rec.discount_amt = new_disc_per * ordHelp!.getExtPrice() / 100
	print "---New discount percent  :", new_disc_per; rem debug
	print "---Total Sales (ExtPrice):", ordHelp!.getExtPrice(); rem debug
	print "---Total Discount Amount :", ordhdr_rec.discount_amt; rem debug
	callpoint!.setColumnData("OPE_ORDTOTALS.DISCOUNT_AMT", ordhdr_rec.discount_amt$)
	user_tpl.prev_sales_total = ordHelp!.getExtPrice()

rem --- Show Discount, Tax & Cash Receipt

	user_tpl.prev_disc_code$ = ordhdr_rec.disc_code$
	gosub tax_calc
	rem gosub display_fields

rem --- Save freight and discount

	callpoint!.setDevObject("freight_amt",  callpoint!.getColumnData("OPE_ORDTOTALS.FREIGHT_AMT"))
	callpoint!.setDevObject("discount_amt", callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT"))
[[OPE_ORDTOTALS.ASVA]]
print "OPE_ORDTOTALS:ASVA"; rem debug

rem --- Send back the entered values

rem (Doesn't get here if you click the close button "x")

	callpoint!.setDevObject("freight_amt",  callpoint!.getColumnData("OPE_ORDTOTALS.FREIGHT_AMT"))
	callpoint!.setDevObject("discount_amt", callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT"))
	
	print "OPE_ORDTOTALS:END"; rem debug
[[OPE_ORDTOTALS.FREIGHT_AMT.AVAL]]
rem --- Save freight and recalculate tax

	gosub get_ordhdr_rec

	ordhdr_rec.freight_amt = num(callpoint!.getUserInput())
	discount_amt = num(callpoint!.getColumnData("OPE_ORDTOTALS.DISCOUNT_AMT"))

	if ordHelp!.getExtPrice() <> 0 then 
		disc_per_in = 100 * discount_amt / ordHelp!.getExtPrice()
	else
		disc_pre_in = 0
	endif

	gosub get_sales_tax
	gosub tax_calc
[[OPE_ORDTOTALS.DISCOUNT_AMT.AVAL]]
rem --- Save discount and recalculate tax

	gosub get_ordhdr_rec

	discount_amt = num(callpoint!.getUserInput())
	ordhdr_rec.discount_amt = discount_amt
	user_tpl.prev_sales_total = ordHelp!.getExtPrice()

	if ordHelp!.getExtPrice() <> 0 then 
		disc_per_in = 100 * discount_amt / ordHelp!.getExtPrice()
	else
		disc_pre_in = 0
	endif

	gosub get_sales_tax
	gosub tax_calc
[[OPE_ORDTOTALS.<CUSTOM>]]
rem ==========================================================================
display_fields: rem --- Display fields ***NOT USED***
                rem      IN: ope_ordhdr record
                rem          ordHelp! with totalSalesDisk() calculated
rem ==========================================================================

	callpoint!.setColumnData("OPE_ORDTOTALS.TOTAL_SALES",  str( ordHelp!.getExtPrice() ))
	callpoint!.setColumnData("OPE_ORDTOTALS.DISCOUNT_AMT", ordhdr_rec.discount_amt$)
	callpoint!.setColumnData("OPE_ORDTOTALS.TAX_AMOUNT",   ordhdr_rec.tax_amount$)
	callpoint!.setColumnData("OPE_ORDTOTALS.FREIGHT_AMT",  ordhdr_rec.freight_amt$)

	callpoint!.setStatus("REFRESH")

	return

rem ==========================================================================
tax_calc: rem --- Calculate tax amount
          rem      IN: disc_per_in
          rem          ordHelp!
          rem          ope_ordhdr record
          rem          taxcode dev, rec$, and rec2$
rem ==========================================================================

	if ordHelp!.getTaxable() <> 0 then 
		ordhdr_rec.taxable_amt = disc_per_in * ordHelp!.getTaxable() / 100
	else
		ordhdr_rec.taxable_amt = 0
	endif

	if taxcode_rec.tax_frt_flag$ = "Y" then ordhdr_rec.taxable_amt = ordhdr_rec.taxable_amt + ordhdr_rec.freight_amt
	ordhdr_rec.tax_amount = 0
	tax_amt = round(taxcode_rec.tax_rate * ordhdr_rec.taxable_amt / 100, 2)
	
	if taxcode_rec.op_max_limit <> 0 and abs(tax_amt) > taxcode_rec.op_max_limit then
		tax_amt = taxcode_rec.op_max_limit * sgn(tax_amt)
	else
		ttl_tax_rate = taxcode_rec.tax_rate
		ttl_tax_amt  = tax_amt
	endif

	ordhdr_rec.tax_amount = tax_amt
	print "---Top level tax code: ", taxcode_rec.op_tax_code$, ", tax amt:", tax_amt; rem debug

	for i=1 to 10
		tax_code$ = field(taxcode_rec$, "AR_TOT_CODE_" + str(i:"00"))
		if cvs(tax_code$,2) = "" then continue
		find record (taxcode_dev, key=firm_id$+tax_code$, dom=*continue) taxcode_rec2$

		tax_amt = round(taxcode_rec2.tax_rate * ordhdr_rec.taxable_amt / 100, 2)

		if taxcode_rec2.op_max_limit <> 0 and abs(tax_amt) > taxcode_rec2.op_max_limit then
			tax_amt = taxcode_rec2.op_max_limit * sgn(tax_amt)
		else
			ttl_tax_rate = ttl_tax_rate + taxcode_rec2.tax_rate
			ttl_tax_amt  = ttl_tax_amt + tax_amt
		endif

		ordhdr_rec.tax_amount = ordhdr_rec.tax_amount + tax_amt
		print "---Tax code ", tax_code$, ", amount:", tax_amt; rem debug
	next i

rem --- Correct penny rounding errors

	adj_amt = round(ttl_tax_rate * ordhdr_rec.taxable_amt / 100, 2) - round(ttl_tax_amt, 2)
	if adj_amt then print "---Adjustment amount:", adj_amt; rem debug
	if adj_amt then ordhdr_rec.tax_amount = ordhdr_rec.tax_amount + adj_amt
	callpoint!.setColumnData("OPE_ORDTOTALS.TAX_AMOUNT", ordhdr_rec.tax_amount$)
	callpoint!.setDevObject("tax_amount", ordhdr_rec.tax_amount$)
	callpoint!.setStatus("REFRESH")
	print "---Total tax amount:", ordhdr_rec.tax_amount; rem debug
	
	return

rem ==========================================================================
get_sales_tax: rem --- Get sales tax
               rem     OUT: taxcode_rec$
rem ==========================================================================

	file_name$ = "OPC_TAXCODE"
	taxcode_dev = fnget_dev(file_name$)
	dim taxcode_rec$:fnget_tpl$(file_name$)
	dim taxcode_rec2$:fnget_tpl$(file_name$)
	find record (taxcode_dev, key=firm_id$+ordhdr_rec.tax_code$, dom=*next) taxcode_rec$

	return

rem ==========================================================================
get_ordhdr_rec: rem --- Get order header record and order helper object
rem ==========================================================================

	ordHelp! = cast(OrderHelper, callpoint!.getDevObject("order_helper_object"))	

	file_name$ = "OPE_ORDHDR"
	dim ordhdr_rec$:fnget_tpl$(file_name$)
	find record (fnget_dev(file_name$), key=firm_id$+"  "+ordHelp!.getCust_id()+ordHelp!.getOrder_no()) ordhdr_rec$

	return
