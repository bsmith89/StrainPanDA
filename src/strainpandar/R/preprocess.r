##' @title preprocess
##'
##' @import dplyr
##' @importFrom reshape2 dcast
##' @param count.matrix a count matrix by mapping reads from multiple samples to a pangenome of one species, each row is one gene and each column is one sample
##' @param pangenome.file the pangenome.csv file generated by panphlan
##' @param min.cov minimum rpkm for the gene family (default: 10)
##' @param frac.gene minimum fraction of gene families has count > min.cov relative to the minimum gene family number (default: 1)
##' @param scaling a scaling factor to normalize the library size for each sample (default: 1e9)
##' @author Xbiome
##' @description filter input data
##' @export
preprocess <- function(count.matrix, pangenome.file, min.cov=10, frac.gene=0.9, scaling=1e9, min.reads=10e6){
  ## normalize counts
    message("`preprocess` called with pangenome_path: ", pangenome.file, ", min.cov: ", min.cov, ", frac_gene: ", frac.gene, ", scaling: ", scaling, ", min.reads: ", min.reads)
  mat <- apply(count.matrix/100, 2, function(x) x/sum(x)) * scaling
  gene.family.number <- NULL
  ## collapse to gene families

  if (is.character(pangenome.file)){
    anno <- read.table(pangenome.file, head=FALSE)
  }else{
    anno <- pangenome.file
    ## unify column names
    colnames(anno) <- paste0("V", 1:6)
  }
  min.gf <- dplyr::distinct(anno, V1, V3) %>% count(V3) %>% pull(2) %>% min
  total.gf <- distinct(anno, V1) %>% pull(1) %>% length()
  rownames(anno) <- anno$V2
  tmp <- anno[rownames(mat),]
  len <- abs(tmp$V6-tmp$V5) + 1
  ## normalize by gene lengths
  mat <- mat/len
  mat <- merge(anno[, 1:2], mat, by.x=2, by.y=0) %>%
    dplyr::select(-1) %>%
    group_by_at(1) %>%
    summarise_all(sum) %>%
    data.frame(row.names = 1, check.names=F)

  mat[mat<min.cov] <- 0 ## too few reads

  ## 1. filter genes with low/high coverage
  mat[mat>300] <- 300  ## cap the data at a max value
  ## 2. filter low coverage sample
  sample.keep <- colSums(mat>0) >= min.gf * frac.gene  &
    colSums(count.matrix) > min.reads
  # message(sprintf("Sample(s) filtered for the species: %s\n", names(which(!sample.keep))))
  mat <- mat[,sample.keep, drop=FALSE]
  mat <- mat[rowSums(mat)>0, ] ## remove genes with 0 reads for now

  tmp <- distinct(anno, V1, V3) %>%
    mutate(dummy=1) %>%
    dcast(V1~V3, value.var="dummy", fill=0) %>%
    data.frame(row.names = 1)
  reference <- tmp[rownames(mat),]

  structure(
    list(data=as.matrix(mat),
       reference=reference,
       min.genefamily=min.gf,
       total.genefamily=total.gf),
    class="strainpandar"
  )
}
