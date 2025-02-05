# StrainPanDA - A strain analysis pipeline based on pangenome

StrainPanDA is a tool that deconvolutes pangenome coverage into strain composition and strain gene profile. We provide a fully automated pipeline implemented with [nextflow](https://www.nextflow.io/docs/latest/index.html).

[中文教程链接](https://github.com/xbiome/StrainPanDA/blob/main/StrainPanDA%E4%B8%AD%E6%96%87%E6%95%99%E7%A8%8B.md)

## Installation

### 1. install [Nextflow](https://www.nextflow.io/), and add it into $PATH

```
curl -s https://get.nextflow.io | bash
mv nextflow <YOUR_PATH> # make sure <YOUR_PATH> is within $PATH。
which nextflow # should show<YOUR_PATH>, if not，please check the mv step
```

Note: if you meet Java version problem in nextflow installation, please find [Nextflow](https://www.nextflow.io/) guideline for details.

### 2. get StrainPanDA codes

```
cd <PATH_TO_PANDA> # <PATH_TO_PANDA> is the path to put StrainPanDA codes
git clone https://github.com/xbiome/StrainPanDA.git 
```

### 3. install StrainPanDA dependences

**Use** [**docker**](https://docs.docker.com/engine/install/ubuntu/) **for installation** （Recommended）：


Step1：install PanPhlAn (for mapping short reads to pan-genome databases)

```
docker pull yuxiangtan/strainpanda-mapping:dev
docker tag yuxiangtan/strainpanda-mapping:dev strainpanda-mapping:dev
```
Step2: isntall strainpandar (for decomposing pangenome into strain-sample and strain-GeneFamily matrices in R)

```
docker pull yuxiangtan/strainpanda-strainpandar:dev
docker tag yuxiangtan/strainpanda-strainpandar:dev strainpanda-strainpandar:dev
```

Step3. check the dockers (Firstly, the dockers should be pulled completely)
```
docker run -u $(id -u):$(id -g) strainpanda-mapping:dev panphlan_profile.py -h
docker run -u $(id -u):$(id -g) strainpanda-strainpandar:dev R --no-save
```

If docker pulling failed，please have a look at [FAQs](https://github.com/xbiome/StrainPanDA/blob/main/FAQs.md#errors-pulling-docker-images)


**Local installation** （only use it if docker is not available）

Step1：install PanPhlAn using the following link (for mapping short reads to pan-genome databases)

[https://github.com/SegataLab/panphlan/wiki/Home-1_3](https://github.com/SegataLab/panphlan/wiki/Home-1_3)

Step2. install [R](https://www.r-project.org/) and [strainpandar](https://github.com/xbiome/StrainPanDA/blob/main/src/strainpandar): decomposing pangenome into strains

Install required packages `dplyr`, `foreach`, `MASS`, `NMF`, `pracma`, `vegan`,`getopt`,`data.table`,`R.utils`

```sh
cd <PATH_TO_PANDA>/StrainPanDA/src
tar -czf strainpandar.tar.gz strainpandar
R CMD INSTALL strainpandar.tar.gz
```



## **DataBase Preparation**
The file system of StrainPanDA Database should follow: folder (<PATH_TO_REFERENCE>) must end with the version number (e.g. 202009), such as ref202009.

Each species (e.g. Escherichia-coli-202009) corresponding to a sub-folder, as the following example:

```
ref202009
 ├── Acinetobacter-johnsonii-202009
 └── Escherichia-coli-202009 
```

Prebuild Database of pangenomes can be downloaded by tools such as wget from Zenodo (doi:10.5281/zenodo.6592017)：[StrainPanDA Pre-built pangenome database | Zenodo](https://zenodo.org/record/6592017)

In Zenodo, each tar.gz file represents a species，in the following format: species_name-version_number.tar.gz (e.g. in Escherichia-coli-202009.tar.gz, Escherichia-coli is the species_name and 202009 is the version_number)

Before running StrainPanDA，make sure the tar.gz of the target species is already unzipped within the database folder（<PATH_TO_REFERENCE>）:

```
cd <PATH_TO_REFERENCE>
wget https://zenodo.org/record/6592017/files/Escherichia-coli-202009.tar.gz
tar -zxvf Escherichia-coli-202009.tar.gz #unzip Escherichia-coli-202009
# tar -zxvf *.tar.gz #unzip all species 
```

In each tar.gz file:

 - The pangenome file to be used is the `${species_version}_pangenome.csv` file, and the pangenome.csv is the recongizer by StrainPanDA;
 - The pangenome sequences are in the `${species_version}_centroids.ffn` file;
 - The bowtie2 indexes are the `bt2` files;
 - The pangenome of the species is annotated by the `${species_version}_emapper_anno.tsv` file, with the colunms specified in the header.
 - The vfdb (Apr 9th 2021) annotation is the `${species_version}_vfdb_anno.csv` file, with the first column as the gene family ID and the second column as the VFDB ID.
 - The CAZy (Jul 31st 2019) annotation is the `${species_version}_CAZy_anno.csv` file, with the first column as the gene family ID and the second column as the CAZy catalog ID.

For new species or rebuilding of existing species, user-specific database with annotation could be generated by [the following way](https://github.com/xbiome/StrainPanDA/tree/main/custom_db#readme). 

If you want to analyze your own strain, please refer to [FAQs](https://github.com/xbiome/StrainPanDA/blob/main/FAQs.md#how-to-analysis-your-own-strains-strains-used-in-your-own-experiments-that-are-not-in-the-database-using-strainpanda)

## Run analysis

### Run full analysis

Download the test data into folder（<PATH_TO_FASTQ>). Test data is in [Zenodo](https://zenodo.org/record/6997716#.YyAxU6TiuUk), which a simulation dataset with 20 samples from E. coli genome.

Note: the input files could be 1 or 2 with .fq, .fastq or .fq.gz, .fastq.gz. However, only the newly generated fastq files in phred33 scoring system could be run by panphlan, while some old datasets were in phred64 system which is not accepted by PanPhlAN.

StrainPanDA requires at least 5 samples to run properly and the minimum recommended number of samples is 20.

Create a species list (the name of species much corresponding to the name of subfolders in the pangenome database folder. The list could have multiply lines and one species per line. StrainPanDA will analyze these species one by one.)

```
echo "Escherichia coli" > species_list.txt 
```



#### **Run with docker**

```
nextflow <PATH_TO_PANDA>/StrainPanDA/main.nf -profile docker \
 --ref_path <PATH_TO_REFERENCE> \
 --path <PATH_TO_FASTQ> \
 --ref_list species_list.txt 
```

#### **Run with local installation**

```
nextflow <PATH_TO_PANDA>/StrainPanDA/main.nf \
 --ref_path <PATH_TO_REFERENCE> \
 --path <PATH_TO_FASTQ> \
 --ref_list species_list.txt 
```

If PanPhlAN failed, please have a look at [FAQs](https://github.com/xbiome/StrainPanDA/blob/main/FAQs.md#failing-to-run-panphlan).

### **Run only strainpandar (for rerunning StrainPanDA with modified parameters)**

Assuming StrainPanDA was run and the count matrix ({species-version}.counts.csv) is already generated, see [example](https://github.com/xbiome/StrainPanDA/blob/main/data/Faecalibacterium-prausnitzii-202009.counts.csv). If you want to modify parameters to get better decomposition result, without rerunning the PanPhlAN alignment step, you can run strainpandar independently by RScript.

#### **Run with docker**：

```
#get into a docker container
 docker run --rm -t -i -u $(id -u):$(id -g) -v <PATH_TO_PANDA>/StrainPanDA/bin/:/script -v <PATH_TO_csv>:/data -v <PATH_TO_REFERENCE>:/ref -v $PWD:/work -w /work strainpanda-strainpandar:dev /bin/bash
 #run Rscript within the docker
 Rscript /script/run_strainpandar.r \
 -c /data/Escherichia-coli-202009.counts.csv \
 -r /ref/Escherichia-coli-202009 \
 -o work -t 8 -m 8 -n 0 
```

#### **Run with local installation** ：

```
Rscript <PATH_TO_PANDA>/StrainPanDA/bin/run_strainpandar.r \
 -c data/Escherichia-coli-202009.counts.csv \
 -r <PATH_TO_REFERENCE>/Escherichia-coli-202009 \
 -o work -t 8 -m 8 -n 0 
```

You can get basic parameters from the help information

```sh
Rscript bin/run_strainpandar.r -h
A wrapper script to perform strain decomposition using strainpandar package.
Usage: bin/run_strainpandar.r [-[-help|h]] [-[-counts|c] <character>] [-[-reference|r] <character>] [-[-output|o] [<character>]] [-[-threads|t] [<integer>]] [-[-max_rank|m] [<integer>]] [-[-rank|n] [<integer>]]
    -h|--help         Show this help message
    -c|--counts       Gene-sample count matrix (CSV file) obtained from mapping reads to a reference pangenome [required]
    -r|--reference    Pangenome database path [required]
    -o|--output       Output prefix [default: ./strainpandar]
    -t|--threads      Number of threads to run in parallele [default: 1]
    -m|--max_rank     Max number of strains expected [default: 8]
    -n|--rank         Number of strains expected. If 0, try to select from 1 to `max_rank`. If not 0, overwrite `max_rank`. [default: 0]
```


## **Outputs**

Output folder has two main subfolders: strainpanda_out and work. The work folder is the working directory of nextflow, which contains log and status of runs. If you are not going to use the resume function of nextflow, you can neglect it or remove if directly (rm -rf work)

The result of StrainPanDA is in the strainpanda_out foler:

```
strainpanda_out
 ├── Escherichia-coli-202009.counts.csv
 ├── Escherichia-coli-202009_mapping
 │   ├── C01_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C02_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C03_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C04_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C05_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C06_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C07_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C08_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C09_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C10_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C11_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C12_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C13_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C14_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C15_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C16_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C17_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C18_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   ├── C19_errfree_r0_Escherichia-coli-202009.csv.bz2
 │   └── C20_errfree_r0_Escherichia-coli-202009.csv.bz2
 ├── Escherichia-coli-202009_strainpandar_out
 │   ├── Escherichia-coli-202009.strainpanda.anno_strain_sample.pdf
 │   ├── Escherichia-coli-202009.strainpanda.genefamily_strain.csv
 │   ├── Escherichia-coli-202009.strainpanda.genefamily_strain.pdf
 │   ├── Escherichia-coli-202009.strainpanda.rds
 │   ├── Escherichia-coli-202009.strainpanda.strain_sample.csv
 │   ├── Escherichia-coli-202009.strainpanda.strain_sample.pdf
 │   ├── Escherichia-coli-202009.strainpanda_all_dis.csv
 │   ├── Escherichia-coli-202009.strainpanda_all_neighbor.csv
 │   ├── Escherichia-coli-202009.strainpanda_str_anno_prof.csv
 │   ├── Escherichia-coli-202009.strainpanda_str_merged_prof.csv
 │   └── Escherichia-coli-202009.strainpanda_str_neighbor.csv
 └── pipeline_info
 ├── strainpanda_DAG.svg
 ├── strainpanda_report.html
 ├── strainpanda_timeline.html
 └── strainpanda_trace.txt 
```

Main outputs of the pipeline:

 - Pangenome database mapping outputs
   - Merged count matrix `{species-version}.counts.csv`: each row is one gene family, each column is one sample, values are read counts.
 - Strain decomposition outputs
   - Gene family-strain matrix (**P**) `{species-version}.strainpanda.genefamily_strain.csv`: each row is one gene family, each column is one strain, values (binary) are presence (1) or absence (0) of the gene family.
   - Strain-sample matrix (**S**) `{species-version}.strainpanda.strain_sample.csv`: each row is one strain, each column is one sample, values are the relative abundances of the strain (in fraction).

You can get the functional annotation of predicted strains by using the ID from the Gene family-strain matrix with the database annotation, see [FAQs](https://github.com/xbiome/StrainPanDA/blob/main/FAQs.md#get-the-functional-annotation-of-gene-families)

## Examples

All the examples used in the manuscript can be viewed [here](https://github.com/xbiome/StrainPanDA-data/tree/main/example#readme)

## [FAQs](FAQs.md)


**citation**

Hu, Han, Yuxiang Tan,Chenhao Li, Junyu Chen, Yan Kou, Zhenjiang Zech Xu, Yang‐Yu Liu, Yan Tan, and Lei Dai. 2022. "StrainPanDA: Linked reconstruction of strain composition and gene content profiles via pangenome‐based decomposition of metagenomic data." iMeta. e41. https://doi.org/10.1002/imt2.41

