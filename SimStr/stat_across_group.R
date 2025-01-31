# Copyright {2021} Yuxiang Tan
# This file is part of SimStr. 
#
# SimStr is a pipeline to generate simulation datasets for evaluation on strain analysis from metagenomic data.
#
# SimStr is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# SimStr is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SimStr.  If not, see <https://www.gnu.org/licenses/>.

#This script is to compare pair t-test among groups, and return the full matrix and significant values smaller than 0.05
#Inputs: the final value matrix from groups, such as Fig2A_sJSD-s1_XT_EST_4str_sJSD_matr.txt

#check arguments
for (e in commandArgs()) {
        ta = strsplit(e,"=",fixed=TRUE)
        if(! is.na(ta[[1]][2])) {
                temp = ta[[1]][2]
                if(substr(ta[[1]][1],nchar(ta[[1]][1]),nchar(ta[[1]][1])) == "I") {
                temp = as.integer(temp)
                }
        if(substr(ta[[1]][1],nchar(ta[[1]][1]),nchar(ta[[1]][1])) == "N") {
                temp = as.numeric(temp)
                }
        assign(ta[[1]][1],temp)
        } else {
        assign(ta[[1]][1],TRUE)
        }
}

#check whether the para is exist
if (!exists("in_matr_f")) {
    stop(paste("\nRscript stat_across_group.R  \nWarning: Usage: The in_matr_f parameter, standing for the input matrix file, was not given. \n\n",sep=""))
}


#check whether the file is exist
if (!file.exists(in_matr_f)) {
    stop(paste("\nRscript stat_across_group.R in_matr_f=",in_matr_f," \nWarning: Usage: the input matrix is not exist, please check the path. \n\n",sep=""))
}


#in_matr_f <- "Fig2C_XT_EST_2str_MCC_matr.txt"
in_matr <- read.table(in_matr_f,as.is=TRUE,stringsAsFactors = FALSE,header=TRUE)

col_n<-dim(in_matr)[2]
stat_matr <- in_matr[,2:(col_n-1)]
rownames(stat_matr) <- in_matr[,1]

out_matr <- matrix(1,nrow=(col_n-2),ncol=(col_n-2))
rownames(out_matr) <- colnames(stat_matr)
colnames(out_matr) <- colnames(stat_matr)

sig_list <-c("sample1_sample2","p_value_paired_T")
#calculate pairwised t-test
for (s1 in rownames(out_matr)){
    for(s2 in rownames(out_matr)){
        if (s1!=s2){
            t_pv<-t.test(in_matr[,s1],in_matr[,s2],paired = TRUE)$p.value
            out_matr[s1,s2]<-t_pv
            if(!is.na(t_pv) & t_pv<0.05){
                if(strsplit(s1,".",fixed=TRUE)[[1]][1]==strsplit(s2,".",fixed=TRUE)[[1]][1]){
                    sample_pair <- paste(s1,s2,sep = "_")
                    sig_list<-rbind(sig_list,c(sample_pair,t_pv))
                }
            }
        }        
    }
}

write.csv(out_matr,file=paste(in_matr_f,"_pairT.csv",sep = ""),quote=FALSE,row.names=TRUE, fileEncoding="UTF-8")
write.table(sig_list,file=paste(in_matr_f,"_significantPair.txt",sep = ""),sep = "\t",quote=FALSE,row.names=FALSE, col.names=FALSE,fileEncoding="UTF-8")

