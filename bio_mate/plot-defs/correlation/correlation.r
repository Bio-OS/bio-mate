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
  packages <- c("corrplot", "RColorBrewer", "gridExtra", "vroom", "magrittr", "ggpubr", "jsonlite", "grid")
  new_packages <- packages[!(packages %in% installed.packages()[, "Package"])]
  if (length(new_packages)) {
    install.packages(new_packages, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/")
  }

  library(ggpubr)
  library(RColorBrewer)
  library(corrplot)
  library(gridExtra)
  library(jsonlite)
  library(magrittr)
  library(vroom)
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

  plot_correlation_plot <- function(json_file_path, data_file_path, output_file_name) {
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

    # 从JSON文件中读取列配置
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

    # 检查所需的列是否存在
    if (!(column_config$ID %in% colnames(data))) {
      stop(paste("Column '", column_config$ID, "' not found in the data file."))
    }

    # 去掉原始数据ID列，并赋予成行名
    data <- as.data.frame(data)
    IDnum <- which(colnames(data) == column_config$ID)
    rownames(data) <- data[, IDnum]
    data <- data[, -IDnum]

    # 剩余变量列全部强制转为数字变量
    data <- as.data.frame(apply(mtcars, 2, function(x) as.numeric(x)))

    # 计算 the p-value 的函数
    cor.mtest <- function(mat, ...) {
      mat <- as.matrix(mat)
      n <- ncol(mat)
      p.mat <- matrix(NA, n, n)
      diag(p.mat) <- 0
      for (i in 1:(n - 1)) {
        for (j in (i + 1):n) {
          tmp <- cor.test(mat[, i], mat[, j], ...)
          p.mat[i, j] <- p.mat[j, i] <- tmp$p.value
        }
      }
      colnames(p.mat) <- rownames(p.mat) <- colnames(mat)
      p.mat
    }

    # 计算两两变量间的pvalue
    pvaluedata <- cor.mtest(data)
    # 计算两两变量间的相关系数
    cordata <- cor(data, use = "pairwise.complete.obs")

    ### -------------- 所有用户可选的参数
    # 通用参数
    Trait_NNN <- config$general$Title
    tlcol <- config$general$labelcolor
    Gradient_color <- config$general$PlotColor
    pictureRes <- config$general$pictureRes
    plotwidth <- config$general$plotwidth
    plotheight <- config$general$plotheight

    # 绘图参数
    orderS <- config$plot_settings$ArrangeBy
    tl.cex <- config$plot_settings$LabelSize
    CLcex <- config$plot_settings$LegendLabelSize
    mar2 <- config$plot_settings$mars
    Siglevel <- config$plot_settings$siglevel
    pchsize <- config$plot_settings$pchsize
    number.cex <- config$plot_settings$SigLabelSize


    # 以png格式保存结果
    png(
      output_file_name,
      width = plotwidth, # 设置图片宽度
      height = plotheight, # 设置图片高度
      units = "px",
      res = pictureRes # 设置图片分辨率
    )

    ### 开始绘图
    # 图层1 -- 添加相关系数方块大小
    corrplot(cordata %>% as.matrix(),
      type = "lower", # 默认放在左下角
      order = orderS, # 变了排序依据
      method = "square", # 默认放置方块形状
      tl.cex = tl.cex, # 坐标轴字体大小
      cl.cex = CLcex, # 图例字体大小
      diag = T, # 对角线是否也绘制
      tl.pos = "lt", # 坐标轴字体位置
      mar = mar2, # 绘图四边空白距离（依次是 bottom, lef, top, right）
      tl.srt = 90, # 坐标轴字体旋转角度
      title = Trait_NNN, # 绘图主图题目
      p.mat = pvaluedata %>% as.matrix(), # 添加显著性检验信息
      tl.col = tlcol, # 坐标轴字体颜色
      col = colorRampPalette(Gradient_color)(100), # 相关系数渐变色设置
      insig = c("blank"), # 不显著的直接设为空
      pch.cex = pchsize, # 不显著字体大小
      sig.level = Siglevel # 显著性阈值
    )

    # 图层2 -- 和同层一相同，区别在于对于不显著的区块，添加叉叉形状凸显
    corrplot(cordata %>% as.matrix(),
      type = "lower",
      order = orderS,
      method = "square",
      tl.cex = tl.cex,
      cl.cex = CLcex,
      p.mat = pvaluedata %>% as.matrix(),
      mar = mar2,
      add = T, # 设置叠加绘图
      title = "", # 主题不添加
      diag = T,
      tl.pos = "n", # 坐标轴标签不添加
      tl.srt = 45,
      tl.col = tlcol,
      col = colorRampPalette(Gradient_color)(100),
      insig = c("pch"), # 不显著区域添加叉叉
      pch.cex = pchsize,
      sig.level = Siglevel
    )

    # 相关系数矩阵化，并却掉标签，放置重复添加
    MID <- cordata %>% as.matrix()
    colnames(MID) <- rep(" ", ncol(MID))

    # 图层3 -- 添加相关系数值
    corrplot(
      MID,
      type = "upper", # 在右上角添加
      order = orderS,
      method = "number", # 添加数字
      tl.cex = tl.cex,
      cl.cex = CLcex,
      mar = mar2,
      add = T,
      tl.pos = "n",
      diag = F,
      title = "",
      tl.srt = 45,
      tl.col = tlcol,
      col = colorRampPalette(Gradient_color)(100),
      insig = c("pch"), # 不显著的添加叉叉
      pch.cex = pchsize,
      number.cex = number.cex, # 设置系数值字体大小
      cl.pos = FALSE, # 不再次添加图例
      sig.level = Siglevel
    )

    dev.off()
  }

  ### --------------  执行绘图函数
  plot_correlation_plot(json_file_path, data_file_path, output_file_name)
}
