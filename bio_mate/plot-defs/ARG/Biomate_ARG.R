
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
  packages <- c( "ggtree","ggstar","reshape2","ggnewscale","ggtreeExtra","tidyverse","jsonlite","readr","RColorBrewer","phytools")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }
  
  ######包调用#####
  suppressMessages(library(ggtree))
  library(phytools)
  library(ggtreeExtra)
  library(RColorBrewer)
  suppressMessages(library(tidyverse))
  library(jsonlite)  
  library(readr)  
  library(ggstar)
  library(reshape2)
  library(ggnewscale)
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
  #####文件夹切换#####
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
    stop(paste("Path file not found:", data_file_path))
  }
  
  tryCatch(
    {
      data <- read.csv(data_file_path)
    },
    error = function(e) {
      stop(paste("Error reading Path file:", e))
    }
  )
  
  
  ######检查软件
  ifelse(system("command -v abricate", ignore.stdout = F) != 1,
         "",
         { print("No abricate in conda envs")
           system2("conda", args = c("install", "-c", "conda-forge", "-c", "bioconda", "-c", "defaults", "abricate"))
         })
  ifelse(system("command -v parsnp", ignore.stdout = F) != 1, 
         "",stop(paste("No parsnp in conda envs")))
  
  ######检查是否存在Path列
  if (!column_config$path %in% colnames(data)) {
    stop("path col not found in data")
  }
  colnames(data)[colnames(data) == column_config$path] <- "path"
  
  ######检查是否需要参考，如果需要参考，检查是否存在ref列，如果不存在ref列自动进行随机参考选择
  test_ref=config$general$ref
  if(test_ref){
    if (column_config$ref %in% colnames(data)) {
      colnames(data)[colnames(data) == column_config$ref] <- "ref"
    }else { print("no ref")
      test_ref= FALSE}}
  
  ######把文件挪到一个文件夹下
  
  system("mkdir -p temp")
  for (i in row.names(data)) {
    tryCatch({
      temp <- paste0("cp ", data[i, "path"], "/*.fasta temp/")
      system(temp)
    }, error = function(e) {
      # 处理错误的操作
      print(paste("Error occurred for row", data[i, "path"]))
      # 抛出错误并终止程序
      stop("Error occurred. Program terminated.")
    })
  }
  ####检查Fasta数量，小于2报错
  fasta_shuliang=list.files("./temp",pattern = "*fasta$")
  
  if (length(fasta_shuliang) >1) {
    print("File OK")
  } else {
    stop("Please keep two and more fasta in all Path")
  }
  #####执行命令-分析耐药基因
  temp=paste0("abricate --threads ",config$general$threads," temp/*.fasta > temp/1.tab")
  tryCatch({
    system(temp)
  }, error = function(e) {
    stop("An error occurred while running abricate")
  })
  tryCatch({
    system("abricate --summary temp/1.tab > temp/summary.tab") 
  }, error = function(e) {
    stop("An error occurred while running abricate")
  })
  tryCatch({
    system("sed -i 's/temp\\\\///g' temp/summary.tab")
  }, error = function(e) {
    stop("An error occurred while running abricate")
  })
  #####执行命令-进行SNP分析
  system("mkdir -p parsnp_temp")
  if(test_ref){
    temp=paste0("parsnp -p ",config$general$threads," -d temp -D 0.6 -r temp/",data[1,"ref"], " -o parsnp_temp")
  }else{
    temp=paste0("parsnp -p ",config$general$threads," -d temp -D 0.6 -r ! -o parsnp_temp")
  }
  tryCatch({
    system(temp)
  }, error = function(e) {
    stop("An error occurred while running parsnp")
  })
  
  
  #####读入#####
  tree=read.newick("parsnp_temp/parsnp.tree")
  ARG=read_tsv("temp/summary.tab")
  # 去除Tiplabel中不必要的'
  ARG$`#FILE`=gsub("temp/","",ARG$`#FILE`)
  tree$tip.label=gsub("'","",tree$tip.label)
  # 遍历ARG$#FILE列中的每个值
  for (i in seq_along(ARG$`#FILE`)) {
    # 检查ARG$#FILE列中的值是否不在tree$tip.label中
    if (!(ARG$`#FILE`[i] %in% tree$tip.label)) {
      # 将ARG$#FILE列中不在tree$tip.label中的值加上.ref后缀
      ARG$`#FILE`[i] <- paste0(ARG$`#FILE`[i], ".ref")
    }
  }
  
  
  ########数值处理，生成柱状图表格ARG_num和圆圈表格ARG_temp2
  ARG_temp=select(ARG,-"NUM_FOUND")
  ARG_num=data.frame("label"=ARG$`#FILE`,"Num"=ARG$NUM_FOUND)
  ARG_temp=as.data.frame(ARG_temp)
  row.names(ARG_temp)=ARG_temp$`#FILE`
  ARG_temp=select(ARG_temp,-"#FILE")
  ARG_temp[ARG_temp == "."] <- "F"
  ARG_temp[ARG_temp != "F"] <- "T"
  ARG_temp$`#FILE`=row.names(ARG_temp)
  ARG_temp2=melt(ARG_temp,id.vars = "#FILE")
  ARG_temp2[ARG_temp2== "F"] <- NA    
  test=ggtree(tree)
  colnames(ARG_temp2)=c("X","variable","value")
  


  ###########圆圈热图绘制(theme()无效果)############
      textsize=config$plot_settings$startextsize
      textvjust=config$plot_settings$startextvjust# 设置垂直对齐方式，使用textvjust作为参数值
                texthjust=config$plot_settings$startexthjust
        textline.size=config$plot_settings$startextlinesize
    
        texttext.angle=config$plot_settings$startextangle
    #print(textvjust)
  gftile_CAZR_2 <- geom_fruit(# 创建一个geom_fruit层，使用ARG_temp2作为数据源，geom为geom_star
    data=ARG_temp2,
    geom=geom_star,
    mapping=aes(x= variable, y=X, fill=value),
    size = config$plot_settings$star_size,
    starstroke=config$plot_settings$starstroke,
    starshape = config$plot_settings$starshape, # 设置星形图的样式，使用config$plot_settings$starshape作为参数值
    offset=config$plot_settings$staroffset,# 设置文本大小，使用textsize作为参数值
    pwidth=config$plot_settings$starpwidth,
    axis.params = list(axis="x",
                       text.size=textsize,
                       vjust=textvjust, 
                       hjust=texthjust,
                       line.size=textline.size,
                       text.angle=texttext.angle)
  )
  #使用config$plot_settings$starlinecolor作为颜色值
  linecolor <- scale_color_manual(values=config$plot_settings$starlinecolor)
  fillcolor <- scale_fill_manual(values=config$plot_settings$starfillcolor,na.translate = FALSE)
  fg <- geom_fruit_list(gftile_CAZR_2,linecolor,fillcolor)
    #print(fg)
  if (!config$general$heatmap) fg=theme()
  
  ####title设定###############
  title_temp=labs(title=config$general$title)
  
  ########标尺设定############
  scale1=theme()
  if (config$general$treescaletype=="xasis")scale1= theme_tree()
  fontsize=config$plot_settings$scalefontsize
  linesize=config$plot_settings$scalelinesize
  offset=config$plot_settings$scaleoffset
  if (config$general$treescaletype=="dandu")scale1=geom_treescale(fontsize=fontsize,
                                                                  linesize=linesize,
                                                                  offset=offset)
  
  
  ########tiplab设定(theme()无任何效果)#########
  if(config$general$tiplab){
    temp_tip=geom_tiplab(size=config$plot_settings$tiplabsize)}else{temp_tip=theme()}
  
  #########柱状图设定############
  # print(ARG_num)
  bar_plot=geom_fruit(data=ARG_num, geom=geom_bar,
                      color=1,
                      fill=config$plot_settings$barcolor,
                      mapping=aes(y=label, x=Num),
                      pwidth=config$plot_settings$barpwidth, 
                      orientation="y", 
                      stat="identity",
                      offset=config$plot_settings$baroffset,
                      width=config$plot_settings$barwidth
  )#+scale_color_manual(values=config$plot_settings$barcolor)#+scale_fill_manual(values=config$plot_settings$barcolor)
  if (!config$general$barplot) bar_plot=theme()

  
  ###########生成进化树图########
  #print("tree")
  
  
  test=ggtree(tree,
              layout=config$plot_settings$layout,
              branch.length=config$plot_settings$branchlength,
              size=config$plot_settings$treesize,
              color=config$plot_settings$treecolor,
              linetype=config$plot_settings$treelinetype)
  
  
  
  #############生成总图##########
  #test+title_temp+fg+bar_plot+temp_tip+scale1
  test+title_temp+temp_tip+scale1+fg+bar_plot+scale1
  ggsave(output_file_name,height = config$plot_settings$height,width = config$plot_settings$width)
  
}
    create_heatmp_plot_from_json(json_file_path,data_file_path, output_file_name)
    }
