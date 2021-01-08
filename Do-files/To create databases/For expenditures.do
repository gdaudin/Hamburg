
if "`c(username)'" =="guillaumedaudin" {
	global hamburg "~/Documents/Recherche/2016 Hambourg et Guerre"
	global hamburggit "~/Répertoires GIT/2016-Hamburg-Impact-of-War"
}

else if "`c(username)'" =="tirindee" {
	global hamburg "C:\Users\tirindee\Google Drive\ETE\Thesis"
	global hamburggit "C:\Users\TIRINDEE\Google Drive\ETE/Thesis/Data/do_files/Hamburg"
}


if "`c(username)'" =="Tirindelli" {
	global hamburg "/Users/Tirindelli/Google Drive/Hamburg"
	global hamburggit "/Users/Tirindelli/Google Drive/Hamburg/Paper"
}



insheet using "$hamburggit/External Data/MitchellGBPublicFinance.csv", case clear

rename v1 year

replace TotalGrossExpendituresMillion  	=usubinstr(TotalGrossExpendituresMillion,",",".",.)
replace ArmyandOrdnanceGrossMillion  	=usubinstr(ArmyandOrdnanceGrossMillion,",",".",.)
replace NavyGrossMillion  				=usubinstr(NavyGrossMillion,",",".",.)

destring TotalGrossExpendituresMillion ArmyandOrdnanceGrossMillion NavyGrossMillion, replace

generate ArmyandOrdnanceNetthsd = ArmyNetthsd+ OrdnanceNetthsd  

merge 1:1 year using "$hamburg/database_dta/ST_silver.dta"
drop if _merge==2
drop _merge


generate TotalNet=log10(TotatnetexpendituresThsd*1000/1000000*ST_silver)

generate ArmyandOrdnanceNet = log10(ArmyandOrdnanceNetthsd*1000/1000000*ST_silver)
generate NavyNet = log10(NavyNetthsd*1000/1000000*ST_silver)
generate TotalGross = log10(TotalGrossExpendituresMillion*1000000/1000000*ST_silver)
generate ArmyandOrdnanceGross = log10(ArmyandOrdnanceGrossMillion*1000000/1000000*ST_silver)
generate NavyGross = log10(NavyGrossMillion*1000000/1000000*ST_silver)

twoway (line TotalNet  year) (line TotalGross  year)
twoway (line NavyNet  year) (line NavyGross  year)



save "$hamburg/database_dta/Expenditures.dta",  replace


insheet using "$hamburggit/External Data/AcerraZysbergFRBudgetMarine.csv", case clear
replace FrenchBudget  	=usubinstr(FrenchBudget,",",".",.)
destring FrenchBudget, replace

merge 1:1 year using "$hamburg/database_dta/FR_silver.dta"
drop if _merge==2
drop _merge

replace FrenchBudget=log10(FrenchBudget*1000000*FR_silver/1000000)

merge 1:1 year using "$hamburg/database_dta/Expenditures.dta"
drop _merge
sort year
twoway (line NavyNet  year) (line NavyGross  year) (line FrenchBudget year)

save "$hamburg/database_dta/Expenditures.dta",  replace

