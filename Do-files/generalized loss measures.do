


if "`c(username)'" =="guillaumedaudin" {
	global hamburg "~/Documents/Recherche/2016 Hambourg et Guerre"
	global hamburggit "~/Documents/Recherche/2016 Hambourg et Guerre/2016-Hamburg-Impact-of-War"
}

if "`c(username)'" =="tirindee" {
	global hamburg "C:\Users\TIRINDEE\Google Drive\ETE/Thesis"
	global hamburggit "C:\Users\TIRINDEE\Google Drive\ETE/Thesis/Data/do_files/Hamburg"
}


if "`c(username)'" =="Tirindelli" {
	global hamburg "/Users/Tirindelli/Google Drive/ETE/Thesis"
	global hamburggit "/Users/Tirindelli/Google Drive/ETE/Thesis/Data/do_files/Hamburg"
}



set more off




capture program drop loss_function
program loss_function
args  interet inourout outremer

*Exemple : loss_function  Blockade Exports 1 
*Exemple : loss_function Blockade  XI 1

clear

 local explained_variable "lnvalue" 


use "$hamburg/database_dta/allcountry2_sitc.dta", clear


gen lnvalue=ln(value)
replace lnvalue=ln(0.00000000000001) if value==0

capture replace sitc18_en="Raw mat fuel oils" if sitc18_en=="Raw mat; fuel; oils"

encode pays_grouping, gen(pays)

merge m:1 pays_grouping year using "$hamburg/database_dta/WarAndPeace.dta"

drop if _merge==2

replace war_status = "Peace" if war_status==""

blif


gen break=(year>1795)



if `outremer'==0 drop if pays_grouping=="Outre-mers"

if "`inourout'"=="XI" {
	order exportsimports value
	collapse (sum) value, by(year-break)
	gen exportsimports="XI"
}




drop if predicted==1

encode  war_status, gen(war_status_num)
replace war_status_num=0 if war_status=="Peace"

gen year_of_war=year
replace year_of_war=year_of_war-1744 if year >=1744 & year<=1748
replace year_of_war=year_of_war-1756 if year >=1756 & year<=1763
replace year_of_war=year_of_war-1778 if year >=1778 & year<=1783
replace year_of_war=year_of_war-1793 if year >=1793 & year<=1801
replace year_of_war=year_of_war-1803 if year >=1803 & year<=1815
replace year_of_war=0 if year_of_war==year

gen war_peace =""

gen noweight =1

if "`interet'" =="R&N" {
	replace war_peace = "Mercantilist_War" if war_status!="Peace" & year>=1744
	replace war_peace = "R&N War" if war_status_num!=. & year>=1793
}


if "`interet'" =="Blockade" {
	replace war_peace = "Mercantilist_War" if war_status!="Peace" & year>=1744
	replace war_peace = "Blockade" if war_status_num!=. & year>=1808 & year <=1815
	replace year_of_war=year-1808 if year >=1808 & year<=1815
}


if "`interet'" =="War" {
	replace war_peace = "War" if war_status_num!=0 & year>=1744
}


replace war_peace="Peace" if war_peace==""
encode war_peace, gen(war_peace_num)
replace war_peace_num=0 if war_peace=="Peace"

replace war_status="Peace" if war_peace=="Peace"
replace war_status_num=0 if war_peace=="Peace"


tabulate war_status_num war_status if war_peace=="Peace"


preserve


collapse (sum) value, by(pays year exportsimports war_status_num year_of_war war_peace_num noweight)

generate lnvalue=ln(value)

*reg with no product/sector differentiation
eststo choc_diff_status_noprod: `reg_type' `explained_variable'  ///
    i.war_status_num#i.war_peace_num  c.year_of_war#i.war_status_num#i.war_peace_num ///
	i.pays c.year#i.pays ///	
	if exportsimports=="`inourout'" ///
    [iweight=`weight'], `reg_option'
	
	
	
restore

*reg with priduct FE and trend
eststo choc_diff_status: `reg_type' `explained_variable'  /// 
	i.war_status_num#i.war_peace_num  c.year_of_war#i.war_status_num#i.war_peace_num ///
	i.pays#i.product  c.year#i.pays#i.product ///	
	if exportsimports=="`inourout'" ///
	[iweight=`weight'], `reg_option'
	

*reg with product differantiation but no war status diff.
eststo choc_diff_goods: `reg_type' `explained_variable' /// 
	i.product#i.war_peace_num c.year_of_war#i.product#i.war_peace_num ///
	i.pays#i.product  c.year#i.pays#i.product ///	
	if exportsimports=="`inourout'" ///
	[iweight=`weight'], `reg_option'
	
preserve

collapse (sum) value, by(product year exportsimports year_of_war war_peace_num noweight)
gen lnvalue=ln(value)

*reg with product differantiation but no war status diff. no country FE
eststo choc_diff_goods_nopays: `reg_type' `explained_variable' ///
	i.product#i.war_peace_num c.year_of_war#i.product#i.war_peace_num ///
	i.product  c.year#i.product ///	
	if exportsimports=="`inourout'" ///
    [iweight=`weight'], `reg_option'
	
	
restore
	
eststo choc_diff_status_no_wart: `reg_type' `explained_variable'  /// 
	i.war_status_num#i.war_peace_num  ///
	i.pays#i.product  c.year#i.pays#i.product ///	
	if exportsimports=="`inourout'" ///
	[iweight=`weight'], `reg_option'

	
eststo choc_diff_goods_no_wart: `reg_type' `explained_variable' /// 
	i.war_peace_num#i.product  ///
	i.pays#i.product  c.year#i.pays#i.product ///	
	if exportsimports=="`inourout'" ///
	[iweight=`weight'], `reg_option'

		
	
	/*
	
eststo `inourout'_eachproduct2: poisson value i.pays#i.sitc c.year#i.pays ///
	c.year#i.sitc i.each_status_sitc i.pays#1.break c.year#1.break ///
	if exportsimports=="`inourout'", vce(robust) iterate(40)	
eststo `inourout'_eachsitc3: poisson value i.pays#i.sitc c.year#i.pays ///
	c.year#i.sitc i.each_status i.pays#1.break c.year#1.break if ///
	exportsimports=="`inourout'", vce(robust) iterate(40)
	
*/

if "`c(username)'" =="guillaumedaudin" {
esttab choc_diff_status_noprod ///
        choc_diff_status ///
		choc_diff_status_no_wart ///
		choc_diff_goods_nopays ///
		choc_diff_goods ///
		choc_diff_goods_no_wart ///
/*	`inourout'_eachsitc2 ///
	`inourout'_eachsitc3  ///
*/	using "$hamburggit/Tables/reg_choc_diff_`reg_type'_`product_class'_`interet'_`inourout'_`weight'_`outremer'_`predicted'.csv", ///
	label replace mtitles("war # status_noprod" /// 
	"war # status" ///
	"war # status no wart" ///
	"war # goods_noprod" ///
	"war # goods" ///
	"war # goods no wart") 
}

else{ 
if "`interet'"=="Blockade" local option 
if "`interet'"=="Blockade" local option keep 

esttab choc_diff_status_noprod ///
        choc_diff_status ///
		choc_diff_status_no_wart ///
		choc_diff_goods_nopays ///
		choc_diff_goods ///
		choc_diff_goods_no_wart ///
		using "$hamburggit/Impact of War/Paper/reg_choc_diff_`reg_type'_`product_class'_`interet'_`inourout'_`weight'_`outremer'_`predicted'.tex", ///
	label replace mtitles("war status_noprod" /// 
	"war status" ///
	"war status no wart" ///
	"war goods_noprod" ///
	"war goods" ///
	"war goods no wart") style(tex) substitute(# $\times$ _ "" \sym{ "" *} * R&N R\&N)
}		

esttab choc_diff_status_noprod ///
        choc_diff_status ///
		choc_diff_status_no_wart ///
		choc_diff_goods_nopays ///
		choc_diff_goods ///
		choc_diff_goods_no_wart, label
	
eststo clear



end


loss_function  Blockade Exports 1
