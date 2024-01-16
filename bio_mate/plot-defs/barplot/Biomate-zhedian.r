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
  packages <- c( "ggsci", "ggsignif","tidyverse","tidyverse","ggthemes","showtext","jsonlite")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }
  
  
  
  
  #library(ggpubr)
  library(ggsci)
  library(ggsignif)
  suppressMessages(library(tidyverse))
  library(ggthemes)
  library(showtext)
  library(jsonlite)
  options(encoding = "UTF-8")
  #options(warn=-1)
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
  create_volcano_plot_from_json <- function(json_file_path, data_file_path, output_file_name) {
    # 检查JSON文件是否存在
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
      stop(paste("CSV file not found:", data_file_path))
    }
    
    tryCatch(
      {
        data <- read.csv(data_file_path,encoding = "UTF-8")
      },
      error = function(e) {
        stop(paste("Error reading CSV file:", e))
      }
    )
    #########更改列名#######
    if (!(column_config$Antibiotics %in% colnames(data))) {
      stop(paste("Column '", column_config$Antibiotics, "' not found in the data file."))
    }
    if (!(column_config$Total.Number %in% colnames(data))) {
      stop(paste("Column 'is", column_config$Total.Number, "' not found in the data file."))
    }
    if (!(column_config$Resistance.rate %in% colnames(data))) {
      stop(paste("Column '", column_config$Resistance.rate, "' not found in the data file."))
    }
    if (!(column_config$Origin %in% colnames(data))) {
      stop(paste("Column '", column_config$Origin, "' not found in the data file."))
    }    
    
    pos <- which(colnames(data) %in% c(column_config$Antibiotics, 
                                       column_config$Total.number, 
                                       column_config$Resistance.rate,
                                       column_config$Origin))
    colnames(data)[colnames(data) == column_config$Antibiotics] <- "Antibiotics"
    colnames(data)[colnames(data) == column_config$Total.number] <- "Total.number"
    colnames(data)[colnames(data) == column_config$Resistance.rate] <- "Resistance.rate"
    colnames(data)[colnames(data) == column_config$Origin] <- "origin"
    
    a=data
    ###颜色形式
    temp_color=config$plot_settings$colortype
    ###具体颜色
    temp_color_you_choose=config$plot_settings$coloryouchoose
    print(temp_color_you_choose)    
    ##具体字体
    temp_size2=config$plot_settings$zitisize
    temp_cuti=config$plot_settings$cuti
    temp_size=temp_size2/3
    temp_pheight=config$plot_settings$pheight
    ###升序/降序
    temp_shunxu=config$plot_settings$shunxu
    temp_ref=config$plot_settings$pailie
    ###具体颜色实现
    showtext_auto()
    if (temp_color == "igv")    color1=scale_color_igv()
    if (temp_color == "igv")    fill1=scale_fill_igv(na.translate = FALSE)
    if (temp_color == "jama")   color1=scale_color_jama()
    if (temp_color == "jama")   fill1=scale_fill_jama(na.translate = FALSE)
    if (temp_color == "nejm")   color1=scale_color_nejm()
    if (temp_color == "nejm")    fill1=scale_fill_nejm(na.translate = FALSE)
    if (temp_color == "lancet")   color1=scale_color_lancet()
    if (temp_color == "lancet")  fill1=scale_fill_lancet(na.translate = FALSE)
    if (temp_color == "AAAS")    fill1=scale_fill_aaas(na.translate = FALSE)
    if (temp_color == "AAAS")   color1=scale_color_aaas()
    if (temp_color == "jco")    color1=scale_color_jco()
    if (temp_color == "jco")   fill1=scale_fill_jco(na.translate = FALSE)
    if (temp_color == "NPG")    color1=scale_color_npg()
    if (temp_color == "NPG")   fill1=scale_fill_npg(na.translate = FALSE)
    if (temp_color == "Your order")    color1=scale_color_manual(values = temp_color_you_choose)
    if (temp_color == "Your order")   fill1=scale_fill_manual(values = temp_color_you_choose)
    if (temp_color == "Carpet")   fill1=scale_fill_manual(values = c("#EE6B4D","#4B9792"))
    if (temp_color == "Carpet")   color1=scale_color_manual(values = c("#EE6B4D","#4B9792"))
    ###字体###
    ziti=theme(axis.text.x = 
                 element_text(angle = 45,vjust = 0.5,hjust = 0.5,
                              size=temp_size2,colour = "black"),
               text=element_text(family="source-han-serif-cn",size=temp_size2,colour = "black"))
    if (temp_cuti  == "Yes") ziti=theme(axis.text.x = element_text(angle = 45,vjust = 0.5,hjust = 0.5,face = "bold",
                                                                   size=temp_size2,colour = "black"),
                                        axis.title = element_text(face = "bold",size=temp_size2,colour = "black"),
                                        axis.text.y = element_text(face = "bold",size=temp_size2,colour = "black"),
                                        text=element_text(family="source-han-serif-cn",face = "bold",size=temp_size2,colour = "black"))
    
    zz=0
    zz1=0
    zz2=0
    if (temp_shunxu == "first") zz1=1 else zz1=2
    if (temp_ref == "Ascending Order") zz2=10 else zz2=20
    zz=zz1+zz2
    
    if (zz==11) {b=a %>%
      arrange((origin),(Resistance.rate))}
    
    if (zz==12) {b=a %>%
      arrange(desc(origin),(Resistance.rate))}
    if (zz==21) {b=a %>%
      arrange((origin),desc(Resistance.rate))}
    if (zz==22) {b=a %>%
      arrange(desc(origin),desc(Resistance.rate))}
    
    
    b=as.data.frame(b)
    a2=mutate(b,naiyaonumber=round(Total.number*Resistance.rate*0.01))
    a3=unique(a2$Antibiotics)
    a2$Antibiotics <- factor(a2$Antibiotics,levels = a3)
    
    ######P值计算######
    xx2=as.data.frame(a2)
    temp_all=data.frame(all=c(),year=c())
    a4=as.matrix(a3)
    numbers=nrow(a4)
    b2=unique(a2$origin)
    b4=as.matrix(b2)
    numbers2=nrow(b4)
    h=data.frame()
    max2=0
    pos=0
    pos2=0
    postive=0
    for (i in 1:numbers) {
      temp=filter(a2,Antibiotics==a4[i])
      for (i2 in 1:numbers2 ){
        temp2=filter(temp,origin==b4[i2])
        if (i2==1) {negative=as.numeric(temp2[1,"Total.number"]-0)
        neg=temp2[1,"naiyaonumber"]
        neg2=negative-neg
        max1=temp2[1,"Resistance.rate"] 
        } else {postive=temp2[1,"Total.number"]
        pos=temp2[1,"naiyaonumber"]
        pos2=postive-pos
        max2=temp2[1,"Resistance.rate"]
        }
        T1=((pos+pos2)*(pos+neg))/(negative+postive)
        T2=((neg+neg2)*(pos+neg))/(negative+postive)
        T3=((pos+pos2)*(pos2+neg2))/(negative+postive)
        T4=((neg+neg2)*(pos2+neg2))/(negative+postive)
        
        if (neg<5 | neg2<5 | pos2<5 | pos<5|T1<5 |T2<5 |T3<5 | T4<5 ) ##Fisher/卡方判断标准
        {
          yang=c(pos,pos2,neg,neg2)
          tab=matrix(yang,ncol = 2,nrow = 2)
          h[i,1]=fisher.test(tab)$p.value
          h[i,2]="Fisher"
        }  else{yang=c(pos,pos2,neg,neg2)
        tab=matrix(yang,ncol = 2,nrow = 2)
        h[i,1]=chisq.test(tab,correct = FALSE)$p.value
        h[i,2]="Kafang"}
        if (max1>max2) {h[i,3]=max1} else{h[i,3]=max2}
      }
      
    }
    h
    h=mutate(h,names=row.names(h))
    temp_2=filter(h,V1<=0.05)
    temp_2
    h3=data.frame(sign=c(),xmin=c(),xmax=c(),y_position=c())
    if (nrow(temp_2)>0){
      for (i in 1:nrow(temp_2)){
        if (temp_2[i,"V1"] < 0.001) {x_temp="***"} else{
          if (temp_2[i,"V1"] < 0.01) {x_temp="**"} else {x_temp="*"}
        }
        h_temp=data.frame(sign=c(x_temp),
                          xmin=as.numeric(temp_2[i,"names"])-0.25,
                          xmax=as.numeric(temp_2[i,"names"])+0.25,
                          y_position=as.numeric(temp_2[i,"V3"])+temp_pheight
        )
        h3=rbind(h3,h_temp)
      }}else {temp_yes="No"}
    ymax=max(h$V3)+4+temp_pheight
    
    ###标题设置
    text_ylab=config$general$y_name
    temp_xlab=config$general$x_name
    title1=config$general$title
    temp_legend=config$general$lab_name
    
    #P1标记P值标记数值
    p1=ggplot(a2,aes(x=Antibiotics, y=Resistance.rate))+# 创建一个基于a2数据集的ggplot对象，x轴为Antibiotics，y轴为Resistance.rate
      geom_bar(aes(x=Antibiotics,   # 添加柱状图层，使用origin作为填充颜色，组合origin进行分组
                   y=Resistance.rate,
                   fill=origin,
                   group=origin), 
               stat="identity",
               position=position_dodge(0.8),width=0.8
      )+
      theme_few()+
      scale_y_continuous(limits = c(0,ymax),expand=c(0,0))+
      ziti+
      fill1+
      color1+
      geom_signif(#添加显著性标记，使用h3中的xmin、xmax、y_position和sign参数
        xmin = h3$xmin,
        xmax = h3$xmax,
        y_position = h3$y_position ,
        annotation =h3$sign,
        textsize=temp_size,
        tip_length = 0.01)+
      geom_text(aes(label=sprintf("%.1f",Resistance.rate),group=origin),vjust=-.8,  # 添加文本标签，标签内容为Resistance.rate的值，组合origin进行分组
                size = temp_size,
                position = position_dodge(width = 0.8))+
      ylab(text_ylab)+
      ggtitle(title1)+
      xlab(temp_xlab)+
      guides(fill=guide_legend(title=temp_legend))
    
    #P2不标记P值标记数值    
    p2=ggplot(a2,aes(x=Antibiotics, y=Resistance.rate))+
      geom_bar( aes(x=Antibiotics, y=Resistance.rate,fill=origin,group=origin), 
                stat="identity",
                position=position_dodge(0.8),width=0.8
      )+
      theme_few()+
      scale_y_continuous(limits = c(0,ymax),expand=c(0,0))+
      ziti+
      fill1+
      color1+
      geom_text(aes(label=sprintf("%.1f",Resistance.rate),# # 添加文本标签，标签内容为Resistance.rate的值，组合origin进行分组
                    group=origin),vjust=-.8, size = temp_size,
                position = position_dodge(width = 0.8))+
      ylab(text_ylab)+
      ggtitle(title1)+
      xlab(temp_xlab)+
      guides(fill=guide_legend(title=temp_legend))
    #P3不标记P值不标记数值        
    p3=ggplot(a2,aes(x=Antibiotics, y=Resistance.rate))+
      geom_bar( aes(x=Antibiotics,
                    y=Resistance.rate,
                    fill=origin,
                    group=origin), 
                stat="identity",
                position=position_dodge(0.8),width=0.8
      )+
      theme_few()+
      scale_y_continuous(limits = c(0,ymax),expand=c(0,0))+
      ziti+
      fill1+
      color1+
      ylab(text_ylab)+
      ggtitle(title1)+
      xlab(temp_xlab)+
      guides(fill=guide_legend(title=temp_legend))
    #P4标记P值不标记数值       
    p4=ggplot(a2,aes(x=Antibiotics, y=Resistance.rate))+
      geom_bar( aes(x=Antibiotics, y=Resistance.rate,fill=origin,group=origin), 
                stat="identity",
                position=position_dodge(0.8),width=0.8
      )+
      theme_few()+
      scale_y_continuous(limits = c(0,ymax),expand=c(0,0))+
      ziti+
      fill1+
      color1+
      geom_signif(#添加显著性标记，使用h3中的xmin、xmax、y_position和sign参数
        xmin = h3$xmin,
        xmax = h3$xmax,
        y_position = h3$y_position ,
        annotation =h3$sign,
        textsize=temp_size,
        tip_length = 0.01)+
      ylab(text_ylab)+
      ggtitle(title1)+
      xlab(temp_xlab)+
      guides(fill=guide_legend(title=temp_legend))
    
    ###保存
    wid=config$plot_settings$width
    hei=config$plot_settings$height
    name2=output_file_name
    temp_yes=config$plot_settings$pvaluebiaoji
    textname=config$plot_settings$shuzhibiaoji
    
    if(temp_yes=="Yes"& textname=="Yes") {ggsave(filename = name2,plot = p1,width = wid,height = hei)} else{
      if (temp_yes =="Yes"& textname=="No") {ggsave(filename = name2,plot = p4,width = wid,height = hei)}
      else if (temp_yes =="No"& textname=="Yes") {ggsave(filename = name2,plot = p2,width = wid,height = hei)}
      else{ggsave(filename = name2,plot = p3,width = wid,height = hei)} }
    
    
  }
  plot <- create_volcano_plot_from_json(json_file_path, data_file_path, output_file_name)
  warnings()
}
