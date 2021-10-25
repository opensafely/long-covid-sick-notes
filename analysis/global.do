* Set filepaths
global projectdir `c(pwd)'
di "$projectdir"
global outdir $projectdir/output/cohorts
di "$outdir"
global tabfigdir $projectdir/output/tabfig
di "$tabfigdir"

* Create directories required 
capture mkdir "$tabfigdir"

adopath + $projectdir/analysis/ado
