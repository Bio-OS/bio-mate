# 如果需要的library没有的话，先下载
if (!"optparse" %in% installed.packages()[, "Package"]) {
  # 这个包用来解析命令行选项
  install.packages("optparse", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
}
library(optparse)
# 解析第一个选项
args <- commandArgs(trailingOnly = TRUE)
command <- args[1]

if (command == "plot") {
  # 如果需要的library没有的话，先下载
  packages <- c( "pheatmap", "tidyverse","jsonlite","readr","RColorBrewer")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }
  
######包调用#####
library(pheatmap)
library(RColorBrewer)
suppressMessages(library(tidyverse))
library(jsonlite)  
library(readr)  
  #命令行选项
  option_list <- list(
    make_option(c("--config"), type = "character", default = NULL, help = "Path to JSON config file", metavar = "character"),
    make_option(c("--output"), type = "character", default = "output.png", help = "Output file name with extension", metavar = "character")
  )
  
  opt_parser <- OptionParser(option_list = option_list)
  opts <- parse_args(opt_parser, args = args[-1])
  json_file_path <- opts$config
  data_file_path <- opts$input
  output_file_name <- opts$output
  create_heatmp_plot_from_json <- function(json_file_path, data_file_path, output_file_name) {
  #####读取Json#####
    if (!file.exists(json_file_path)) {
      stop(paste("JSON file not found:", json_file_path))
    }
    
    tryCatch(
      {
        config <- fromJSON(json_file_path)
      },
      error = function(e) {
        stop(paste("Error reading JSON file:", e))
      }
    )
    # 从JSON文件中读取列配置
    column_config <- config$columns
    
    # 从JSON中读取数据文件path
    data_file_path <- config$dataFile$dataFilePath
    
    # 检查CSV文件是否存在
    if (!file.exists(data_file_path)) {
      stop(paste("Metaphlan3 file not found:", data_file_path))
    }
    
    tryCatch(
      {
        data <- read_tsv(data_file_path)
      },
      error = function(e) {
        stop(paste("Error reading Metaphlan3 file:", e))
      }
    )
           if (!column_config$cladename %in% colnames(data)) {
      stop("cladename col not found in data")
      }#判断是否存在clade列
      colnames(data)[colnames(data) == column_config$cladename] <- "clade_name"
    
      #####读入#####
      a=data
      type=column_config$type
      #####前处理#####
      a=a%>% dplyr::filter(str_detect(clade_name,"s__"))                     ##筛选物种列
      a=a[!grepl("t__", a$clade_name), ]#mpa4 有SGB分类级别，需要删除
      a3= a %>% dplyr::filter(str_detect(clade_name,type))             
      clade_cols <- grep("clade_name", names(a3))###筛选除clade_name列外的全部列
      a3[, -clade_cols] <- lapply(a3[, -clade_cols], function(x) x / sum(x))#a3[, -clade_cols]选择了除了这些列之外的所有列，并将其应用于lapply()函数。
      a3_species=a3 %>% dplyr::filter(str_detect(clade_name,"\\|s_"))        ##筛选物种表
      
      ######物种表制作#######
      a3_test=as.data.frame(a3_species)                                      
      tax_a3 <- strsplit(a3_test[,1],"\\|")                                  ##分割
      tax_a3=matrix(unlist(tax_a3),ncol=7,byrow = T)                         ##分割
      colnames(tax_a3)=c("Domain","Phylum","Class","Order","Family","Genus","Species")    ##分割
      tax_a3=as.data.frame(tax_a3)
      tax_a3$Species=str_replace(tax_a3$Species,"s__","")
      ######行名制作########
      
      a3_species=as.data.frame(a3_species) 
      row.names(a3_species)=tax_a3$Species
      row.names(tax_a3)=tax_a3$Species
      
      ######删掉不需要信息#####
      a3_species <- subset(a3_species, select = -clade_name )
      
      
      a3_species
      
      ######制作属信息(热图注释）######
      genus_a3 = data.frame("Genus" = tax_a3$Genus)
      rownames(genus_a3) = rownames(a3_species)
      
      
      a3_test=a3_species
      a3_test$genus=tax_a3$Genus
      a3_test
      a3_test_2<- a3_test %>% 
        arrange(genus) 
      a3_test_2=subset(a3_test_2, select = -genus )
      ######画图#####
      
      if (config$plot_settings$annoation){##是否有注释，如果没有执行else
      pheatmap(a3_test_2,
               cluster_cols = config$plot_settings$cluster_cols,#列聚类
               cluster_rows = config$plot_settings$cluster_rows,#行聚类
               annotation_row = genus_a3,#注释
               cellheight = config$plot_settings$cellheight,#高度
               cellwidth = config$plot_settings$cellwidth,#宽度
               display_numbers = config$plot_settings$display_numbers,#展示数值
               number_color = config$plot_settings$number_color,#颜色
               main = config$general$title,#标题
               fontsize=config$plot_settings$fontsize,#字体大小
               color = colorRampPalette(rev(brewer.pal(n = 7, name =config$plot_settings$color_type)))(100),#颜色
               width = config$plot_settings$width,#图片宽度
               height  = config$plot_settings$height,#图片高度
               angle_col=config$plot_settings$angle_col,#字体倾斜角度
               filename = output_file_name)}else{
                 pheatmap(a3_test_2,
                          cluster_cols = config$plot_settings$cluster_cols,#列聚类
                          cluster_rows = config$plot_settings$cluster_rows,#行聚类
                          cellheight = config$plot_settings$cellheight,#高度
                          cellwidth = config$plot_settings$cellwidth,#宽度
                          display_numbers = config$plot_settings$display_numbers,#展示数值
                          number_color = config$plot_settings$number_color,#颜色
                          main = config$general$title,#标题
                          fontsize=config$plot_settings$fontsize,#字体大小
                          color = colorRampPalette(rev(brewer.pal(n = 7, name =config$plot_settings$color_type)))(100),#颜色
                          width = config$plot_settings$width,#图片宽度
                          height = config$plot_settings$height,#图片高度
                          angle_col=config$plot_settings$angle_col,#字体倾斜角度
                          filename = output_file_name)
                 
               }
  }
  create_heatmp_plot_from_json(json_file_path,data_file_path, output_file_name)
}
