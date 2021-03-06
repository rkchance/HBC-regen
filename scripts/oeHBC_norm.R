#title: Normalization of olfactory epithelium samples
#author: Diya Das and Russell Fletcher
#date: November 7, 2016

rm(list=ls()); options(getClass.msg=FALSE)
library(scone)
library(BiocParallel)
library(optparse)

option_list <- list(
  make_option("--expt", default="", type="character", help="full form, e.g. oeHBC"),
  make_option("--ncores", default="1", type="double"),
  make_option("--norm", default=NULL, type="character")
)

opt <- parse_args(OptionParser(option_list=option_list))
expt_str <- opt$expt
if (!is.null(opt$norm)) {
   load("../ref/scone_params.Rda")
   params <<- params[opt$norm, ]
   print(params)
}

register(MulticoreParam(workers = opt$ncores))

out_dir <- paste0("../output/clust/",expt_str)

set.seed(1999)
load(file.path(out_dir, paste0(expt_str,"_filtdata.Rda")))
expt <- droplevels(expt)
batch <- droplevels(batch)

hk615 <- read.table(file.path("../ref", "hkl615.txt"))
hk615 <- intersect(rownames(counts), unlist(hk615))
del <- read.table(file.path("../ref", "oeHBC_de.txt"))
del <- intersect(rownames(counts), unlist(del))
hk100 <- read.table(file.path("../ref", "hkl100.txt"))
hk100 <- intersect(rownames(counts), unlist(hk100))

# Generate Scores and Ranking
if (is.null(opt$norm)) {
  print(system.time({
    scone_out <- scone(counts, imputation=list(none=impute_null), impute_args=list(0), return_norm = 'no', scaling=list(none=identity, fq=FQT_FN, tmm=TMM_FN), k_ruv=1, k_qc=1, ruv_negcon=hk615, qc=as.matrix(qc), adjust_bio="yes", bio=expt, adjust_batch="yes", batch=batch, run=TRUE, evaluate=TRUE, eval_negcon=hk100, eval_poscon=del, eval_kclust = 10:12)
save(scone_out, file = file.path(out_dir,paste0(expt_str,"_scone_eval.Rda"))) 
 }))
} else {
  print(system.time({
    scone_out <- scone(counts, return_norm = 'in_memory', params = params, imputation=list(none=impute_null),impute_args=list(0), scaling=list(none=identity, fq=FQT_FN, tmm=TMM_FN), k_ruv=1, k_qc=1, ruv_negcon=hk615, qc=as.matrix(qc), adjust_bio="yes", bio=expt, adjust_batch="yes", batch=batch, run=TRUE, evaluate=TRUE, eval_negcon=hk100, eval_poscon=del, eval_kclust = 10:12)
save(scone_out, file = file.path(out_dir,paste0(expt_str,"_", opt$norm, "_scone.Rda")))
  }))
}

