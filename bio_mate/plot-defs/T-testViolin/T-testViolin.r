# 如果需要的library没有的话，先下载
if (!"optparse" %in% installed.packages()[, "Package"]) {
  # 这个包用来解析命令行选项
  install.packages("optparse", repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
}

library(optparse)
# 解析第一个选项
args <- commandArgs(trailingOnly = TRUE)
command <- args[1]

# 执行plot板块
if (command == "plot") {
  # 如果需要的library没有的话，先下载
  packages <- c("ggplot2", "gridExtra", "stringr", "ggsignif", "vroom", "magrittr", "jsonlite", "grid")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(ggsignif)
  library(RColorBrewer)
  library(gridExtra)
  library(jsonlite)
  library(magrittr)
  library(vroom)
  library(stringr)
  library(ggplot2)
  library(grid)

  # 命令行选项
  option_list <- list(
    make_option(c("--config"), type = "character", default = NULL, help = "Path to JSON config file", metavar = "character"),
    make_option(c("--output"), type = "character", default = "output.png", help = "Output file name with extension", metavar = "character")
  )

  # 解析选项
  opt_parser <- OptionParser(option_list = option_list)
  opts <- parse_args(opt_parser, args = args[-1])
  json_file_path <- opts$config
  output_file_name <- opts$output

  plot_T_testViolin_plot <- function(json_file_path, data_file_path, output_file_name) {
    # 检查JSON文件是否存在
    if (!file.exists(json_file_path)) {
      stop(paste("JSON file not found:", json_file_path))
    }

    # 读取json列表参数
    tryCatch(
      {
        config <- fromJSON(json_file_path)
      },
      error = function(e) {
        stop(paste("Error reading JSON file:", e))
      }
    )

    # 从JSON中读取数据文件path
    data_file_path <- config$dataFile$dataFilePath

    # 从JSON中读取用户输入的列名
    column_config <- config$columns

    # 检查CSV文件是否存在
    if (!file.exists(data_file_path)) {
      stop(paste("CSV file not found:", data_file_path))
    }

    # 读取表格数据文件, vroom默认会猜测表格的分割符，如果你的表格属于较为正常的类型
    tryCatch(
      {
        data <- vroom::vroom(data_file_path)
      },
      error = function(e) {
        stop(paste("Error reading CSV file:", e))
      }
    )
    # 判断用户输入的列名是否存在于输入的数据中
    if (!(column_config$Value %in% colnames(data))) {
      stop(paste("Column '", column_config$Value, "' not found in the data file."))
    }
    if (!(column_config$platform %in% colnames(data))) {
      stop(paste("Column '", column_config$platform, "' not found in the data file."))
    }

    # 检验是否输入了Group列，如果没有，则不会进行组内点线的绘制
    add_line <- !(nchar(stringr::str_remove_all(c(column_config$Group), " ")) == 0)

    if (add_line) {
      # 判断输入的组名，是否存在于数据中
      if (!(column_config$Group %in% colnames(data))) {
        stop(paste("Column '", column_config$Group, "' not found in the data file."))
      }
      DATA <- data[c(column_config$Value, column_config$platform, column_config$Group)]
      # 用户可自定义选择是否添加，组内的电线
      add_line <- config$plot_settings$add_line
    } else {
      DATA <- data[c(column_config$Value, column_config$platform)]
    }

    ### -------------- 所有用户可选的参数
    # 通用参数
    BaseLabelSize <- config$general$BaseLabelSize # 整体字体的大小
    BaseRectSize <- config$general$BaseRectSize # 整体边框的大小
    Title <- config$general$Title # 图标题的名称
    PlotColor <- config$general$PlotColor
    pictureRes <- config$general$pictureRes
    plotwidth <- config$general$plotwidth
    plotheight <- config$general$plotheight
    titlehjust <- config$general$titlehjust

    # 绘图参数
    trim <- config$plot_settings$trim # 是否去掉小提琴尾巴
    position_dodge <- config$plot_settings$position_dodge # 小提琴图间的距离
    Legend_SHOW <- config$plot_settings$Legend_SHOW # 是否展示图例
    expand <- config$plot_settings$expand # 控制y轴两端留白的大小
    boxplotSize <- config$plot_settings$boxplotSize # 箱型图的大小
    boxplotWidth <- config$plot_settings$boxplotWidth # 箱型图的宽度
    add_signif <- config$plot_settings$add_signif # 是否添加显著性检验Pvalue
    SiglabelSize <- config$plot_settings$SiglabelSize # 显著性检验Pvalue标签大小
    testmethod <- config$plot_settings$testmethod # 显著性检验方法
    step_Size <- config$plot_settings$step_Size # 显著性检验线段纵向间距
    SiglineSize <- config$plot_settings$SiglineSize # 显著性检验线段大小
    legendPos <- config$plot_settings$legendPos # 图例的位置
    legendSize <- config$plot_settings$legendSize # 图例的大小
    linealpha <- config$plot_settings$linealpha # 组内连线的透明度
    legendnrows <- config$plot_settings$legendnrows # 图例的行数
    legendtitle_position <- config$plot_settings$legendtitle_position

    # 绘图前预处理
    colnames(DATA)[1:2] <- c("Value", "Type")

    # 小提琴填充颜色 - 根据用户输入的分类变量数目去拓展颜色
    fillColor <- colorRampPalette(c(PlotColor))(length(unique(DATA$Type)))

    ### --------------  开始绘图
    p <-
      # 绘图数据输入和坐标轴映射
      ggplot(
        data = DATA, aes(
          x = Type, y = as.numeric(Value), fill = Type
        )
      ) +
      # 小提琴图层设置
      geom_violin(
        trim = trim, # 小提琴去尾巴
        color = NA, # 小提琴边框颜色
        position = position_dodge(position_dodge), # 设置类别间的距离
        show.legend = Legend_SHOW
      ) +
      # y轴缩放设置
      scale_y_continuous(expand = expand) +
      # 人工填充颜色
      scale_fill_manual(values = fillColor) +
      # 箱型图层设置
      geom_boxplot(
        fill = NA, # 不填充颜色
        position = position_dodge(position_dodge), size = boxplotSize,
        color = "black", # 边框默认为黑色
        show.legend = F, width = boxplotWidth
      ) +
      labs(x = column_config$platform, y = column_config$Value, title = Title) +
      # 主题设置
      theme_classic(base_size = BaseLabelSize, base_rect_size = BaseRectSize, base_line_size = BaseRectSize) +
      theme(
        axis.ticks.length = unit(0.2, "cm"), # 设置坐标轴刻度的长度
        axis.ticks = element_line(size = 0.5), # 设置坐标轴刻度的宽度
        legend.key.size = unit(legendSize, "cm"), # 设置图例大小
        legend.position = c(legendPos),
        legend.direction = "horizontal", # 默认设置图例横行设置
        legend.background = element_blank(), # 图例背景设置为空
        legend.box.background = element_blank(), # 个体图例背景设置为空
        plot.title = element_text(hjust = titlehjust)
      ) +
      # 图例设置
      guides(fill = guide_legend(nrow = legendnrows, title.position = legendtitle_position)) # 设置图例的行数

    # 是否自动添加两两显著性检验标签
    if (add_signif) {
      # 计算需要进行两两检验的组合
      combi_signif <- combn(DATA$Type %>% as.character() %>% unique(), 2, simplify = FALSE)
      # 添加显著性检验结果
      p <- p +
        geom_signif(
          comparisons = combi_signif,
          map_signif_level = function(p) paste0("P = ", sprintf("%.2g", p)), # 添加显著性检验标签
          textsize = SiglabelSize, # 显著性检验标签大小
          test = testmethod, # 显著性检验方法
          step_increase = step_Size, # 显著性检验标签纵向距离
          size = SiglineSize # 显著性检验线段大小
        )
    }

    # 是否添加组内个体，在不同变量间的连线趋势
    if (add_line) {
      p <-
        p + geom_line(
          data = DATA,
          aes(group = Group, x = Type, y = as.numeric(Value)),
          inherit.aes = F, # 不继承之前的映射参数
          alpha = linealpha # 线段透明度设置
        )
    } else {
      p
    }

    # 以png格式保存结果
    png(
      output_file_name,
      width = plotwidth, # 设置图片宽度
      height = plotheight, # 设置图片高度
      units = "px",
      res = pictureRes # 设置图片分辨率
    )

    grid::grid.draw(p)

    dev.off()
  }

  ### --------------  执行绘图函数
  plot_T_testViolin_plot(json_file_path, data_file_path, output_file_name)
}
