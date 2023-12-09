from reportlab.graphics.shapes import *
from reportlab.graphics.charts.textlabels import Label
from reportlab.graphics import renderPDF, renderPM, renderSVG, renderPS
from reportlab.lib import colors, fonts
from reportlab.lib.colors import toColor
import copy
import pandas as pd

#注册中文字体
def register_zh_font():
    from reportlab.pdfbase import pdfmetrics, ttfonts
    zh_fontdir = os.path.join(os.path.dirname(__file__), "Fonts")
    try:
        pdfmetrics.registerFont(ttfonts.TTFont('song', "%s/simsun.ttc"%zh_fontdir))
        pdfmetrics.registerFont(ttfonts.TTFont('hei', "%s/simhei.ttf"%zh_fontdir))
        pdfmetrics.registerFont(ttfonts.TTFont('fang', "%s/simfang.ttf"%zh_fontdir))
        pdfmetrics.registerFont(ttfonts.TTFont('yh', "%s/msyh.ttf"%zh_fontdir))
        pdfmetrics.registerFontFamily(
            "song",
            normal     = "song",  #常规<宋体>  Times-Roman
            bold       = "hei",   #粗体<黑体>  Times-Bold
            italic     = "fang",  #粗体<仿宋>  Iimes-Italic
            boldItalic = "yh",    #粗斜体      Times-BoldItalic
        )
    except Exception as e:
        print(str(e))
        sys.stderr.write("Can't register default chinese font 'song'\n")
register_zh_font()

def select_myfont(context, bold=False, italic=False):
    """对中文/英文自动选择合适的字体"""
    import re
    pattern = re.compile(r'[\u4e00-\u9fa5]')
    if pattern.search(context): #匹配中文
        try:
            if bold:
                return ("yh" if italic else "hei")
            else:
                return ("fang" if italic else "song")
        except:
            pass
    """如果选择找中文字体失败, 则选择英文字体"""
    if bold:
        return ("Times-BoldItalic" if italic else "Times-Bold")
    else:
        return ("Times-Italic" if italic else "Times-Roman")

def mytoColor(color_str):
    """把输入表示颜色得字符串数值转换为标准可识别得类型, 无法转换则为None"""
    try:
        return toColor(color_str)
    except:
        return None

class PyCircos(object):
    def __init__(self,
        W = 800,  #绘图画布宽度
        H = 800,  #绘图画布高度
        u = 1,    #字体线条缩放比例
        centerx = None,    #圈图圆心, default: (0.5*W, 0.5*H)
        centery = None,    #圈图圆心, default: (0.5*W, 0.5*H)
        datafile = None,   #输入文件数据类型列表
        chrlimit = None,   #选择绘图染色体, None/空值表示所有染色体都绘制
        block_angles = 1,  #基因组/染色体之间空白分割的角度
        first_end_block_angle = 30,   #首尾染色体之间分隔的角度
        first_angle = 90,  #第一个基因组起始绘图的角度
        show_dataname = True, #显示数据名称标题
        dataname_scale_fmt = {}, #数据刻度标签风格样式
        dataname_title_fmt = {}, #数据名称风格样式
        dataname_title_angle_dr = None, #数据名称与首个个染色体的角度间隔
        ):
        """
        datafile表头:
        PlotName: 自定义名称标签, 绘图图列的默认标签
        PlotType: 绘图类型, 只能从genome, karyotype, hist, point, link, line中选取一种
        PlotData: 绘图具体的数据文件
        PlotRaius:绘图圆环的内径外径
        """                      
        self.u = u
        self.W = W * self.u
        self.H = H * self.u
        self.centerx = self.default_assignment(centerx, 0.5*self.W)
        self.centery = self.default_assignment(centery, 0.5*self.H)

        """读取inputfile并且提取信息"""
        self.datafile = datafile
        self.data = pd.read_table(datafile, header=0, keep_default_na=False, encoding="utf-8")
        self.all_data = {}
        for dv in self.data.itertuples():
            #if dv.PlotType not in ["genome", "karyotype", "hist", "point", "link", "line"]:continue
            readdf = pd.read_table(dv.PlotData, header=0, keep_default_na=False, encoding="utf-8")
            """染色体名称列统一设置为字符类型, 否则会出现数值和字符类型混用异常"""
            for colname in readdf.columns:
                if colname.startswith("ChrName"):
                    readdf[colname] = readdf[colname].astype(str)
            if dv.PlotType not in self.all_data.keys():
                self.all_data[dv.PlotType] = []
            """选择绘图染色体"""
            if dv.PlotType == "genome" and chrlimit:
                readdf = readdf[readdf["ChrName"].isin(chrlimit.split(" "))]
            """如果有字段PlotRadius, 就获取其中的绘图内径、外径信息"""
            try:
                data_plot_r = dv.PlotRadius
            except:
                data_plot_r = ""
            self.all_data[dv.PlotType].append([dv.PlotName, readdf, data_plot_r])
        
        ##获取类型数据的最大/最小值, 注意某些文件没有Value字段
        self.all_data_max = {}
        self.all_data_min = {}
        for k, dfs in self.all_data.items():
            try:
                self.all_data_max[k] = max([df[1]["Value"].max() for df in dfs])
                self.all_data_min[k] = min([df[1]["Value"].min() for df in dfs])
            except:
                self.all_data_max[k] = None
                self.all_data_min[k] = None
        
        self.first_end_block_angle = first_end_block_angle
        self.block_angles = [block_angles]*(self.all_data["genome"][0][1].shape[0] - 1) + \
            [self.first_end_block_angle]
        self.first_angle = first_angle        

        """对绘图的线条字体等绘图单元风格样式设置默认值"""
        """genome and karyotype style format"""
        self.chr_ring_fmt = {
            "strokeColor": colors.black,
            "strokeWidth": 1.5 * self.u,
            "strokeLineJoin" : 1,}
        self.chr_label_fmt = {
            "fontSize": 20*self.u,
            "fontName": "Times-Roman",
            "fillColor": colors.black,}
        self.cyto_ring_fmt = {
            "strokeColor": None,
            "strokeWidth": 0.2 * self.u,
            "strokeLineJoin": 1,
            "strokeLineCap": 1}
        self.cyto_label_fmt = {
            "fontSize": 8 * self.u,
            "fontName": "Times-Roman",
            "fillColor": colors.black,}
        self.chr_scale_fmt = {
            "strokeColor": colors.black,
            "strokeWidth": 0.5 * self.u}
        self.chr_scale_label_fmt = {
            "fontSize": 4* self.u,
            "fontName": "Times-Roman",
            "fillColor": colors.black}

        """plotdata style format"""
        self.link_fmt = {
            "strokeColor": colors.black,
            "strokeWidth": 0.01 * self.u,}
        self.hist_fmt = {
            #"fillColor": colors.blue, #每个hist颜色推荐在文件中详细设置
            "strokeColor": colors.black,
            "strokeWidth": 0.01 * self.u,
            "strokeLineJoin": 1,
            "strokeLineCap": 1}
        self.line_fmt = { 
            #"fillColor": colors.pink,
            "strokeColor": colors.black,
            "strokeWidth": 0.5 * self.u,
            "strokeLineJoin": 1,
            "strokeLineCap": 1}
        self.point_fmt = {
            #"fillColor": colors.blue, #每个point颜色推荐在文件中详细设置
            "strokeColor": None,
            "strokeWidth": 0.01 * self.u,
            "strokeLineJoin": 1,
            "strokeLineCap": 1}
        self.data_label_fmt = {
            "fontSize": 8 * self.u,
            "fontName": "Times-Roman",
            "fillColor": colors.black,
            }
       
        self.show_dataname = show_dataname 
        self.dataname_scale_fmt = dataname_scale_fmt
        self.dataname_title_fmt = dataname_title_fmt
        self.dataname_title_angle_dr = dataname_title_angle_dr

        #绘图
        self.d = Drawing(self.W, self.H)

    def default_fmt(self, fmt, default_fmt):
        """可变变量参数深拷贝, 改变了存储地址，使之不受上一层绘图参数设置的影响"""
        fmt = copy.deepcopy(fmt)
        for k in default_fmt.keys():
            if k in ["fontSize", "strokeWidth", "dr"]:
                fmt[k] = self.default_assignment(fmt.get(k, None), default_fmt[k])
            else:
                fmt[k] = fmt.get(k, default_fmt[k])
        return fmt
     
    def default_assignment(self, v, default_v):
        """空值替换为默认值"""
        return (v*self.u if v else default_v)

    def select_font(self, context, bold=True, italic=False):
        """对中文/英文自动选择合适的字体"""
        if re.compile(r'[\u4e00-\u9fa5]'):
            if bold:
                return ("yh" if italic else "hei")
            else:
                return ("fang" if italic else "song")
        else:
            if bold:
                return ("Times-BoldItalic" if italic else "Times-Bold")
            else:
                return ("Times-Italic" if italic else "Times-Roman")

    """圈图基础绘图单元, 扇形圆环"""
    def BaseRing(self,
        centerx,  #圆心横轴坐标
        centery,  #圆心纵轴坐标
        inner_r,  #圆环内径
        outer_r,  #圆环外径
        start_angle, #绘图圆环起始角度
        end_angle,   #绘图圆环终止角度
        **kw,  #设置扇形的样式风格键值对, 同Path函数中参数一致
        ):
        """扇形轮廓"""
        ring_outline = Path(**kw)
        """生成内弧线点坐标列表"""
        innerArcPoints = getArcPoints(centerx, centery, inner_r, start_angle, end_angle)
        #print(innerArcPoints)
        """生成外弧线点坐标列表"""
        outerArcPoints = getArcPoints(centerx, centery, outer_r, start_angle, end_angle)
        #print(outerArcPoints)
        """按照顺序连接轮廓点""" 
        ring_outline.moveTo(innerArcPoints[0][0], innerArcPoints[0][1])
        for points in innerArcPoints[1:]:
            ring_outline.lineTo(points[0], points[1])
        for points in outerArcPoints[::-1]: #轮廓线条连接顺序和内弧线相反
            ring_outline.lineTo(points[0], points[1])
        ring_outline.closePath()
        return ring_outline
    
    """绘制基因组和核型条带各元素"""
    def Genome(self, 
        inner_r, #圆环内径
        outer_r, #圆环外径
        centerx = None,  #绘图圆心横轴坐标, None表示是画布中心
        centery = None,  #绘图圆心纵轴坐标, None表示是画布中心
        chrinfo = None,  #绘图的基因组信息, None表示从datafile中获取
        show_karyotype = True,  #是否显示核型条带
        karyotype = None,       #核型条带信息, None表示从datafile值获取
        chrtotalsize = None,    #基因组总碱基数, None表示从datafile的genome只能自动计算
        block_angles = None,    #基因组/染色体之间空白分割的角度
        first_angle = None,      #基因组/染色体起始绘图角度
        show_chr_label = True,  #是否添加染色体标签
        chr_label_dr = 5,       #染色体标签与染色体绘图区径向外延距离
        chr_label_fmt = {},     #染色体标签风格样式设置
        chr_ring_fmt = {},      #染色体样式风格设置
        show_cyto_label = True, #是否添加核型条带标签
        cyto_label_dr = 2,      #核型条带标签与核型绘图区径向外延距离
        cyto_label_fmt = {},    #核型条带标签风格样式设置
        cyto_ring_fmt = {},     #核型条带风格样式设置
        show_chr_scale = True,  #是否添加染色体刻度
        chr_scale_step = 10*1000*1000, #染色体刻度大小
        chr_scale_dr = 2,         #染色体刻度长度
        chr_scale_fmt = {},       #染色体刻度线风格样式
        chr_scale_label_fmt = {}, #染色体刻度标签风格样式
        ):
        inner_r = inner_r * self.u
        outer_r = outer_r * self.u        
        centerx = self.default_assignment(centerx, self.centerx)
        centery = self.default_assignment(centery, self.centery)
        block_angles = self.default_assignment(block_angles, self.block_angles)
        begin_angle  = self.default_assignment(first_angle, self.first_angle)
        chrinfo = (chrinfo if chrinfo else self.all_data["genome"][0][1])
        chrtotalsize = (chrtotalsize if chrtotalsize else chrinfo["Size"].sum())
    
        degrees = (360.0 - sum(block_angles)) / chrtotalsize #基因组单个碱基对应的角度
        if show_karyotype:
            karyotype = (karyotype if karyotype else self.all_data["karyotype"][0][1])
        else:
            karyotype = pd.DataFrame([], columns=["ChrName", "Start", "End", "Color"])
        
        """如果未提供图形和字体元素风格样式, 就用默认设置"""
        chr_ring_fmt        = self.default_fmt(chr_ring_fmt, self.chr_ring_fmt)
        chr_label_fmt       = self.default_fmt(chr_label_fmt, self.chr_label_fmt)
        cyto_ring_fmt       = self.default_fmt(cyto_ring_fmt, self.cyto_ring_fmt)
        cyto_label_fmt      = self.default_fmt(cyto_label_fmt, self.cyto_label_fmt)
        chr_scale_fmt       = self.default_fmt(chr_scale_fmt, self.chr_scale_fmt)
        chr_scale_label_fmt = self.default_fmt(chr_scale_label_fmt, self.chr_scale_label_fmt)
        
        g = Group()
        ci = 0
        for chrv in chrinfo.itertuples():
            chr_name = chrv.ChrName
            chr_len = chrv.Size
            try:
                chrcolor = chrv.Color
            except:
                chrcolor = colors.pink
            """数据是顺时针绘图, 但是角度值是逆时针增加, 需要注意方向"""
            start_angle = begin_angle - chr_len * degrees
            end_angle = begin_angle
            """绘制每条染色体/基因组的扇形圆环"""
            chr_ring = self.BaseRing(centerx, centery, inner_r, outer_r,
                start_angle, end_angle, fillColor = chrcolor)
            for k in chr_ring_fmt.keys():
                exec(f"chr_ring.{k} = chr_ring_fmt['{k}']")
            g.add(chr_ring)

            """绘制核型明暗条带"""
            chr_karyotype = karyotype[karyotype["ChrName"]==chr_name]
            for cyto in chr_karyotype.itertuples():
                if cyto.Start > chr_len or cyto.End > chr_len:
                    """核型坐标超出染色体大小"""
                    continue
                cyto_start_angle = end_angle - cyto.End * degrees
                cyto_end_angle = end_angle - cyto.Start * degrees
                cyto_mid_angle = (cyto_start_angle + cyto_end_angle)*0.5
                cyto_ring = self.BaseRing(centerx, centery, inner_r, outer_r,
                    cyto_start_angle, cyto_end_angle, 
                    fillColor = mytoColor(cyto.Color))
                for k in cyto_ring_fmt.keys():
                    exec(f"cyto_ring.{k} = cyto_ring_fmt['{k}']")
                g.add(cyto_ring)
                
                """添加条带标签"""
                if show_cyto_label:
                    try:
                        cyto_tag = cyto.Label
                    except:
                        cyto_tag = ""
                    if not cyto_tag:continue #忽略空值
                    cytopos = getArcPoints(centerx, centery, inner_r - cyto_label_dr * self.u, 
                        cyto_mid_angle, cyto_mid_angle)
                    cyto_label_tag = Label(_text = str(cyto_tag),
                        x = cytopos[0][0],
                        y = cytopos[0][1],
                        fontName = select_myfont(str(cyto_tag)),
                        fillColor = mytoColor(cyto.Color),
                        angle = (cyto_mid_angle-180 if 
                            (90<cyto_mid_angle%360<270 or -270<cyto_mid_angle%360<-90)
                             else cyto_mid_angle),
                        boxAnchor = ('w' if 
                            (90<cyto_mid_angle%360<270 or -270<cyto_mid_angle%360<-90) else 'e'),
                        )
                    """添加条带标签默认风格样式"""
                    for k in cyto_label_fmt.keys():
                        exec(f"cyto_label_tag.{k} = cyto_label_fmt['{k}']")
                    g.add(cyto_label_tag)

            """添加染色体标签"""
            if show_chr_label:
                mid_angle = (start_angle + end_angle)*0.5
                chrpos = getArcPoints(centerx, centery, outer_r + chr_label_dr * self.u,
                    mid_angle, mid_angle)
                chr_label_tag = Label(_text = str(chr_name),
                    x = chrpos[0][0], y=chrpos[0][1],
                    fontName = select_myfont(str(chr_name)),
                    angle = mid_angle - 90,
                    boxAnchor = "s")
                """添加染色体标签默认风格样式"""
                for k in chr_label_fmt.keys():
                    exec(f"chr_label_tag.{k} = chr_label_fmt['{k}']")
                g.add(chr_label_tag)

            """添加染色体刻度"""
            if show_chr_scale:
                sntag = 0
                for i in range(0, chr_len, chr_scale_step):
                    scale_angle = end_angle - i * degrees
                    scale_Arc1 = getArcPoints(centerx, centery, outer_r,
                         scale_angle, scale_angle)
                    scale_Arc2 = getArcPoints(centerx, centery, 
                        outer_r + chr_scale_dr * self.u, scale_angle, scale_angle)
                    """添加刻度线"""
                    chr_scale = Line(scale_Arc1[0][0], scale_Arc1[0][1], 
                        scale_Arc2[0][0], scale_Arc2[0][1])
                    for k in chr_scale_fmt.keys():
                        exec(f"chr_scale.{k} = chr_scale_fmt['{k}']")
                    g.add(chr_scale)                    
                    """添加刻度标签"""
                    scale_Arc = getArcPoints(centerx, centery, outer_r + chr_scale_dr * self.u,
                        scale_angle, scale_angle)
                    chr_scale_label = Label(_text = str(sntag), x = scale_Arc[0][0], y = scale_Arc[0][1],
                        fontName = select_myfont(str(sntag)),
                        angle = (scale_angle-180 if 
                            (90 < scale_angle%360 < 270 or -270 < scale_angle%360 < -90) else scale_angle),
                        boxAnchor = ("e" if 
                            (90 < scale_angle%360 < 270 or -270 < scale_angle%360 < -90) else "w"),
                            )
                    for k in chr_scale_label_fmt.keys():
                        exec(f"chr_scale_label.{k} = chr_scale_label_fmt['{k}']")
                    g.add(chr_scale_label)
                    sntag += 1

            """转动到下一个基因组绘图角度"""
            begin_angle = start_angle - block_angles[ci]
            ci += 1
        return g

    def PlotData(self,
        inner_r,  #绘图圆环内径
        outer_r,  #绘图圆环外径
        inputdataname = None,
        inputdata = pd.DataFrame([],  #绘图数据dataframe
            columns=["ChrName", "Start", "End", "Value"]),
        plottype = "hist",  #绘图类型
        centerx = None, #圆心横轴坐标
        centery = None, #圆心纵轴坐标
        chrinfo = None,  #绘图的基因组信息, None表示从datafile中获取
        chrtotalsize = None, #基因组总碱基数, None表示从datafile的genome只能自动计算
        block_angles = None, #基因组/染色体之间空白分割的角度
        first_angle = None,  #基因组/染色体绘图起始角度
        limit_max_value = None, #绘图数据最大值, 超出此值会矫正为此最大值绘图
        limit_min_value = None, #绘图数据最小值, 低于此值会矫正为此最小值绘图
        split_value = None,     #绘图数据分隔基准值, 可以使数据在此基准上下显示, 只对hist有效
        show_bg = True,  #是否显示背景
        bg_grid_num = 4, #背景网格线数目  
        link_fmt = {},   #关联纽带图link元素风格样式
        hist_fmt = {},   #柱状图hist元素风格样式
        line_fmt = {},   #折线图line, 面积图line_area, 线段图segment图风格样式
        point_fmt = {},  #点状图point风格样式
        point_size = 5,  #点大小
        show_label = True,   #是否显示数据标签
        data_label_fmt = {}, #数据标签的风格样式, 字体颜色主要在datafile对应类型文件中设置
        show_dataname = True, #显示数据名称标题
        dataname_scale_fmt = {}, #数据刻度标签风格样式
        dataname_title_fmt = {}, #数据名称风格样式
        dataname_title_angle_dr = None, #数据名称与首个个染色体的角度间隔
        ):

        inner_r = inner_r * self.u
        outer_r = outer_r * self.u
        centerx = self.default_assignment(centerx, self.centerx)
        centery = self.default_assignment(centery, self.centery)
        block_angles = self.default_assignment(block_angles, self.block_angles)
        begin_angle = self.default_assignment(first_angle, self.first_angle)
        chrinfo = (chrinfo if chrinfo else self.all_data["genome"][0][1])
        chrtotalsize = (chrtotalsize if chrtotalsize else chrinfo["Size"].sum())
        degrees = (360.0 - sum(block_angles)) / chrtotalsize #基因组单个碱基对应的角度
        
        """如果未提供图形和字体元素风格样式, 就用默认设置"""
        link_fmt       = self.default_fmt(link_fmt, self.link_fmt)        
        hist_fmt       = self.default_fmt(hist_fmt, self.hist_fmt)
        line_fmt       = self.default_fmt(line_fmt, self.line_fmt)
        point_fmt      = self.default_fmt(point_fmt, self.point_fmt)
        data_label_fmt = self.default_fmt(data_label_fmt, self.data_label_fmt)
        show_dataname  = self.default_assignment(show_dataname, self.show_dataname)
        dataname_scale_fmt = self.default_fmt(dataname_scale_fmt, self.dataname_scale_fmt)
        dataname_title_fmt = self.default_fmt(dataname_title_fmt, self.dataname_title_fmt)
        dataname_title_angle_dr = self.default_assignment(
            dataname_title_angle_dr, self.dataname_title_angle_dr)

        g = Group()        
        if plottype == "link":
            """主要用于绘制:基因融合, SV结构变异
            绘图方法: 二阶贝塞尔曲线, 默认已圆心为控制点"""
            link_labels = []
            for record in inputdata.itertuples():
                #print(record)
                chr_name1  = record.ChrName1
                chr_start1 = record.Start1
                chr_end1   = record.End1
                chr_label1 = record.Label1
                chr_name2  = record.ChrName2
                chr_start2 = record.Start2
                chr_end2   = record.End2
                chr_label2 = record.Label2
                try:
                    link_color = mytoColor(record.Color)
                except:
                    link_color = colors.pink
                if chr_name1 not in list(chrinfo["ChrName"]):continue
                if chr_name2 not in list(chrinfo["ChrName"]):continue
                chr_idx1 = list(chrinfo["ChrName"]).index(chr_name1)
                chr_idx2 = list(chrinfo["ChrName"]).index(chr_name2)

                chr_start1_angle = begin_angle - \
                    (chrinfo.iloc[:chr_idx1]["Size"].sum() + chr_start1) * degrees - \
                    sum(block_angles[:chr_idx1])
                chr_end1_angle   = begin_angle - \
                    (chrinfo.iloc[:chr_idx1]["Size"].sum() + chr_end1) * degrees - \
                    sum(block_angles[:chr_idx1])
                chr_start2_angle = begin_angle - \
                    (chrinfo.iloc[:chr_idx2]["Size"].sum() + chr_start2) * degrees - \
                    sum(block_angles[:chr_idx2])                    
                chr_end2_angle   = begin_angle - \
                    (chrinfo.iloc[:chr_idx2]["Size"].sum() + chr_end2) * degrees - \
                    sum(block_angles[:chr_idx2])

                chr_pos_start1 = getArcPoints(centerx, centery, outer_r,
                    chr_start1_angle, chr_start1_angle)
                chr_pos_end1   = getArcPoints(centerx, centery, outer_r,
                    chr_end1_angle, chr_end1_angle)
                chr_pos_start2 = getArcPoints(centerx, centery, outer_r,
                    chr_start2_angle, chr_start2_angle)
                chr_pos_end2   = getArcPoints(centerx, centery, outer_r,
                    chr_end2_angle, chr_end2_angle)

                link_path = Path(
                    fillColor = link_color, 
                    strokeColor = link_color, 
                    strokeWidth = 0.01 * self.u)
                link_path.moveTo(chr_pos_start1[0][0], chr_pos_start1[0][1])
                """计算二阶贝塞尔曲线控制点, 绘制第一条曲线"""
                control_center1 = getArcPoints(centerx, centery, inner_r,
                    (chr_start1_angle + chr_end2_angle)*0.5, 
                    (chr_start1_angle + chr_end2_angle)*0.5)
                link_path.curveTo(chr_pos_start1[0][0], chr_pos_start1[0][1],
                    control_center1[0][0], control_center1[0][1],
                    chr_pos_end2[0][0], chr_pos_end2[0][1])
                for pp in getArcPoints(centerx, centery, outer_r, chr_end2_angle, chr_start2_angle):
                    link_path.lineTo(pp[0], pp[1])
                """计算二阶贝塞尔曲线控制点, 绘制第二条曲线"""
                control_center2 = getArcPoints(centerx, centery, inner_r,
                    (chr_start2_angle + chr_end1_angle)*0.5,
                    (chr_start2_angle + chr_end1_angle)*0.5)
                link_path.curveTo(chr_pos_start2[0][0], chr_pos_start2[0][1],
                    control_center2[0][0], control_center2[0][1],
                    chr_pos_end1[0][0], chr_pos_end1[0][1])
                for pp in getArcPoints(centerx, centery, outer_r, chr_end1_angle, chr_start1_angle):
                    link_path.lineTo(pp[0], pp[1])
                link_path.closePath()
                for k in link_fmt.keys():
                    exec(f"link_path.{k} = link_fmt['{k}']")
                g.add(link_path)
                
                """定位link的基因标签位置"""
                link_label_pos1_angle = (chr_start1_angle + chr_end1_angle)*0.5
                link_label_pos1 = getArcPoints(centerx, centery, outer_r,
                    link_label_pos1_angle, link_label_pos1_angle)
                link_label_pos2_angle = (chr_start2_angle + chr_end2_angle)*0.5
                link_label_pos2 = getArcPoints(centerx, centery, outer_r,
                    link_label_pos2_angle, link_label_pos2_angle)
                link_labels.append([link_label_pos1, chr_label1, link_label_pos1_angle])
                link_labels.append([link_label_pos2, chr_label2, link_label_pos2_angle])                
            
            if show_label:
                """显示link对应的基因标签"""
                for pos, genename, geneangle in link_labels:
                    if genename:
                        link_gene_label = Label(_text = str(genename), x = pos[0][0], y = pos[0][1],
                            fontName = select_myfont(str(genename)),
                            angle = (geneangle-180 if (90<geneangle%360<270 or -270<geneangle%360<-90) 
                                else geneangle),
                            boxAnchor = ('w' if (90<geneangle%360<270 or -270<geneangle%360<-90) else 'e'),
                        )
                        for k in data_label_fmt.keys():
                            exec(f"link_gene_label.{k} = data_label_fmt['{k}']")
                        g.add(link_gene_label)
            #return g
        
        if plottype == "link":
            max_value = 1
            min_value = 0
        else:
            max_value = inputdata["Value"].max()
            min_value = inputdata["Value"].min()
        #print(max_value, min_value, limit_max_value, limit_min_value)
        limit_max_value = self.default_assignment(limit_max_value, max_value)
        limit_min_value = self.default_assignment(limit_min_value, min_value)
        #print(limit_max_value, limit_min_value)
        if limit_min_value != limit_max_value:
            r_degrees = (outer_r - inner_r) / (limit_max_value - limit_min_value) #单位径向长度
        else:
            """最大最小值相等是, 重新推敲一个不等的最大最小值, 且不能都为0值"""
            limit_min_value = 0
            if limit_max_value!=0:
                r_degrees = (outer_r - inner_r)/limit_max_value
            else:
                limit_max_value = 1
                r_degrees = (outer_r - inner_r)/limit_max_value
        if split_value == None or split_value < limit_min_value or split_value > limit_max_value:
            """split_value必须是在最大最小值之间, 否则为最小值"""
            split_value = limit_min_value
        #print("r_degrees:", r_degrees, split_value)

        ci = 0
        for chrv in chrinfo.itertuples():
            chr_name = chrv.ChrName
            chr_len = chrv.Size
            """数据是顺时针绘图, 但是角度值是逆时针增加, 需要注意方向""" 
            start_angle = begin_angle - chr_len * degrees
            end_angle = begin_angle
            """染色体数据"""
            if plottype == "link":
                chr_inputdata = pd.DataFrame([], columns=["Start", "End"])
            else:
                chr_inputdata = inputdata[inputdata["ChrName"]==chr_name]
            """显示背景"""
            if show_bg:
                bg_ring = self.BaseRing(centerx, centery,
                    (inner_r if plottype != "link" else outer_r),
                    outer_r,
                    start_angle, 
                    end_angle,
                    fillColor = mytoColor("rgba(0.95,0.95,0.95,1)"),
                    strokeColor = mytoColor("rgba(0,0,0,1)"),
                    strokeWidth = 0.5* self.u,
                    )
                if (plottype == "link" and ci == 0) or  plottype:
                    g.add(bg_ring)
                bg_grid_step = 0.1
                if bg_grid_num > 0 and plottype != "link":
                    brd = float(outer_r - inner_r) / (bg_grid_num + 1)
                    for i in range(bg_grid_num):
                        grid_p = Path(
                            storkeWidth = (inner_r + i * brd)/1000.0,
                            fillColor = None,
                            strokeColor = colors.grey,
                            strokeLineJoin = 1,
                            strokeLineCap = 0
                            )
                        grid_pangle = start_angle + 1 * bg_grid_step
                        while grid_pangle < end_angle - bg_grid_step:
                            grid_p_start = getArcPoints(centerx, centery, 
                                inner_r + (i+1)*brd,
                                grid_pangle, grid_pangle)
                            grid_p_end = getArcPoints(centerx, centery,
                                inner_r + (i+1)*brd,
                                grid_pangle + bg_grid_step,
                                grid_pangle + bg_grid_step)
                            grid_p.moveTo(grid_p_start[0][0], grid_p_start[0][1])
                            grid_p.lineTo(grid_p_end[0][0], grid_p_end[0][1])
                            grid_pangle += 4 * bg_grid_step
                        g.add(grid_p)

            if plottype == "hist": #绘制柱状图
                for dv in chr_inputdata.itertuples():
                    chr_start = dv.Start
                    chr_end = dv.End
                    if chr_start > chr_len or chr_end > chr_len:continue
                    value = dv.Value                    
                    try:
                        value_color = mytoColor(dv.Color)
                    except:
                        value_color = colors.blue
                    try:
                        value_label = dv.Label
                    except:
                        value_label = ""
                    hist_start_angle = end_angle - chr_end * degrees
                    hist_end_angle = end_angle - chr_start * degrees
                    hist_mid_angle = (hist_start_angle + hist_end_angle) * 0.5
                    """超过默认最大值截取到最大值为止"""
                    value = (limit_max_value if value > limit_max_value else value)
                    """超过默认最小值截取到最小值为止"""
                    value = (limit_min_value if value < limit_min_value else value)
                    hist_ring = self.BaseRing(centerx, centery, 
                        inner_r + (split_value - limit_min_value) * r_degrees,
                        inner_r + (value - limit_min_value) * r_degrees,
                        hist_start_angle,
                        hist_end_angle,
                        fillColor = value_color,
                    )
                    for k in hist_fmt.keys():
                        exec(f"hist_ring.{k} = hist_fmt['{k}']")               
                    g.add(hist_ring)

            elif plottype == "point":  #绘制点状图
                for dv in chr_inputdata.itertuples():
                    chr_start = dv.Start
                    chr_end = dv.End
                    if chr_start > chr_len or chr_end > chr_len:continue
                    value = dv.Value
                    try:
                        value_color = mytoColor(dv.Color)
                    except:
                        value_color = colors.red
                    try:
                        value_label = dv.Label
                    except:
                        value_label = ""
                    point_start_angle = end_angle - chr_end * degrees
                    point_end_angle = end_angle - chr_start * degrees
                    point_mid_angle = (point_start_angle + point_end_angle) * 0.5

                    value = (limit_max_value if value > limit_max_value else value)
                    value = (limit_min_value if value < limit_min_value else value)
                    point_pos = getArcPoints(centerx, centery,
                        inner_r + value * r_degrees,
                        point_mid_angle, point_mid_angle)
                    point_circle = Circle(point_pos[0][0], point_pos[0][1],
                        point_size * self.u, 
                        fillColor = value_color,
                        )
                    for k in point_fmt.keys():
                        exec(f"point_circle.{k} = point_fmt['{k}']")
                    g.add(point_circle)

            elif plottype == "line": #绘制折线图
                """连接线条绘制, 坐标必须升序排序"""
                chr_inputdata = chr_inputdata.sort_values(by=["Start", "End"], ascending=True)
                pn = 0
                line_path = Path()
                for dv in chr_inputdata.itertuples():
                    pos_start, pos_end  = dv.Start, dv.End
                    if pos_start > chr_len:continue
                    if pos_end > chr_len: pos_end = chr_len
                    pos_start_angle = end_angle -  pos_end * degrees
                    pos_end_angle = end_angle - pos_start * degrees
                    pos_mid_angle = (pos_start_angle + pos_end_angle) * 0.5
                    value = dv.Value
                    value = (limit_max_value if value > limit_max_value else value)
                    value = (limit_min_value if value < limit_min_value else value)
                    point_pos = getArcPoints(centerx, centery,
                        inner_r + value * r_degrees,
                        pos_mid_angle, pos_mid_angle,                                                
                        )
                    if pn == 0:
                        first_point_pos = getArcPoints(centerx, centery,
                            inner_r + value * r_degrees,
                            pos_end_angle, pos_end_angle,
                            )
                        line_path.moveTo(first_point_pos[0][0], first_point_pos[0][1])
                        line_path.lineTo(point_pos[0][0], point_pos[0][1])
                    else:
                        line_path.lineTo(point_pos[0][0], point_pos[0][1])
                    pn += 1
                if pn > 0:
                    end_point_pos = getArcPoints(centerx, centery,
                        inner_r + value * r_degrees,
                        pos_start_angle, pos_start_angle,
                        )
                    line_path.lineTo(end_point_pos[0][0], end_point_pos[0][1])
                for k in line_fmt.keys():
                    exec(f"line_path.{k} = line_fmt['{k}']")
                g.add(line_path)

            elif plottype == "line_area": #绘制面积图
                chr_inputdata = chr_inputdata.sort_values(by=["Start", "End"], ascending=True)
                pn = 0
                line_area_path = Path()
                for dv in chr_inputdata.itertuples():
                    pos_start, pos_end = dv.Start, dv.End
                    if pos_start > chr_len:continue
                    if pos_end > chr_len: pos_end = chr_len                 
                    pos_start_angle = end_angle - pos_end * degrees
                    pos_end_angle = end_angle - pos_start * degrees
                    pos_mid_angle = (pos_start_angle + pos_end_angle) * 0.5
                    value = dv.Value
                    value = (limit_max_value if value > limit_max_value else value)
                    value = (limit_min_value if value < limit_min_value else value)
                    point_pos = getArcPoints(centerx, centery,
                        inner_r + value * r_degrees,
                        pos_mid_angle, pos_mid_angle)
                    if pn == 0:
                        chr_first_angle = pos_end_angle
                        first_point_inner = getArcPoints(centerx, centery, inner_r, 
                            pos_end_angle, pos_end_angle)
                        first_point_pos = getArcPoints(centerx, centery, inner_r + value * r_degrees, 
                            pos_end_angle, pos_end_angle)

                        line_area_path.moveTo(first_point_inner[0][0], first_point_inner[0][1])
                        line_area_path.lineTo(first_point_pos[0][0], first_point_pos[0][1])
                        line_area_path.lineTo(point_pos[0][0], point_pos[0][1])
                    else:
                        line_area_path.lineTo(point_pos[0][0], point_pos[0][1])
                    pn += 1
                if pn > 0:
                    end_point_pos = getArcPoints(centerx, centery, inner_r + value * r_degrees,
                        pos_start_angle, pos_start_angle)
                    line_area_path.lineTo(end_point_pos[0][0], end_point_pos[0][1])
                    """内径弧线"""
                    inner_arc = getArcPoints(centerx, centery, inner_r,
                        pos_start_angle, chr_first_angle)                    
                    for pp in inner_arc:
                        line_area_path.lineTo(pp[0], pp[1])
                for k in line_fmt.keys():
                    exec(f"line_area_path.{k} = line_fmt['{k}']")
                line_area_path.closePath()                
                g.add(line_area_path)                

            elif plottype == "segment": #绘制线段图
                for dv in chr_inputdata.itertuples():
                    pos_start, pos_end, value = dv.Start, dv.End, dv.Value
                    value = (limit_max_value if value > limit_max_value else value)
                    value = (limit_min_value if value < limit_min_value else value)
                    if pos_start > chr_len or pos_end > chr_len:continue
                    try:
                        value_color = mytoColor(dv.Color)
                    except:
                        value_color = colors.black
                    segment_path = Path(strokeColor=value_color, strokeWidth=2*self.u)
                    pos_start_angle = end_angle - pos_end * degrees
                    pos_end_angle = end_angle - pos_start * degrees
                    segment_arc = getArcPoints(centerx, centery,
                        inner_r + value * r_degrees,
                        pos_start_angle, pos_end_angle)
                    for pn, pp in enumerate(segment_arc):
                        if pn == 0:
                            segment_path.moveTo(pp[0], pp[1])
                        else:
                            segment_path.lineTo(pp[0], pp[1])
                    for k in line_fmt.keys():
                        if k == "strokeColor": continue #线段颜色在文件中设置
                        exec(f"segment_path.{k} = line_fmt['{k}']")
                    g.add(segment_path)

            else:
                pass

            if show_label: #绘制数据标签
                for dv in chr_inputdata.itertuples():
                    pos_start = dv.Start
                    pos_end = dv.End
                    if pos_start > chr_len or pos_end > chr_len:continue
                    pos_start_angle = end_angle - pos_end * degrees
                    pos_end_angle = end_angle - pos_start * degrees
                    pos_mid_angle = (pos_start_angle + pos_end_angle) * 0.5

                    value = dv.Value
                    value = (limit_max_value if value > limit_max_value else value)
                    value = (limit_min_value if value < limit_min_value else value)
                    anno_label_dr = 0 * self.u
                    if inner_r > outer_r:
                        anno_label_dr = - anno_label_dr
                    anno_label = dv.Label
                    anno_pos = getArcPoints(centerx, centery,
                        inner_r + (value - limit_min_value) * r_degrees + anno_label_dr,
                        pos_mid_angle,
                        pos_mid_angle,
                        )
                    if anno_label: #如果标签不为空
                        if inner_r > outer_r:
                            align = ("w" if (90<pos_mid_angle%360<270 or -270<pos_mid_angle%360<-90) else "e")
                        else:
                            align = ("e" if (90<pos_mid_angle%360<270 or -270<pos_mid_angle%360<-90) else "w")
                        anno_label_info = Label(_text = str(anno_label),
                            x = anno_pos[0][0], y = anno_pos[0][1],
                            fontName = select_myfont(str(anno_label)),
                            angle = (pos_mid_angle-180 if (
                                90<pos_mid_angle%360<270 or -270<pos_mid_angle%360<-90
                                ) else pos_mid_angle),
                            boxAnchor = align,
                            )
                        for k in data_label_fmt.keys():
                            exec(f"anno_label_info.{k} = data_label_fmt['{k}']")
                        g.add(anno_label_info)                    
            #角度顺延
            begin_angle = start_angle - block_angles[ci]
            #ci += 1

            if show_dataname:  #显示数据名称
                import math
                value_dis = abs(limit_max_value - limit_min_value)
                """迭代选择合适的value刻度, 使得刻度低于4"""
                value_step = 100
                while math.ceil(value_dis / value_step) <= 4:
                    value_step = value_step / 5
                #print(value_dis, value_step)
                while math.ceil(value_dis / value_step) >= 4:
                    value_step = value_step * 5
                #print(value_dis, value_step)
                first_angle = self.default_assignment(first_angle, self.first_angle)
                y_values = []
                for i in range(math.ceil(value_dis / value_step)):
                    y_value = limit_min_value + i * value_step
                    if y_value > limit_max_value:
                        y_value = limit_max_value
                        continue  
                    y_values.append(y_value)
                y_values.append(limit_max_value)

                for yi, y_value in enumerate(y_values):
                    y_tick_arc = getArcPoints(centerx, centery,
                            inner_r + (y_value - limit_min_value) * r_degrees,
                            first_angle, first_angle + 1)
                    tick_path = Path(strokeColor = colors.black, strokeWidth=0.5*self.u)
                    for pn, pp in enumerate(y_tick_arc):
                        if pn == 0:
                            tick_path.moveTo(pp[0], pp[1])
                        else:
                            tick_path.lineTo(pp[0], pp[1])
                    if ci == 0 and max_value != min_value:
                        g.add(tick_path)
                    """数据刻度线和刻度标签"""
                    label_pos = getArcPoints(centerx, centery,
                        inner_r + (y_value - limit_min_value)* r_degrees,
                        first_angle + 2, first_angle + 2)
                    y_tick_label = Label(_text = "%.4g"%y_value, #保留4位有效数值
                        x = label_pos[0][0],
                        y = label_pos[0][1],
                        fillColor = colors.black,
                        fontName = "Times-Roman",
                        #fontSize = 10,
                        #angle = first_angle + 2 - 90,
                        boxAnchor = "e",                        
                        )
                    for k in dataname_scale_fmt.keys():
                        if k == "angle":
                            #angle = dataname_scale_fmt[k] + (first_angle + 2 - 90)
                            #y_tick_label.angle = angle
                            exec(f"y_tick_label.{k} = dataname_scale_fmt['{k}'] + \
                                {first_angle} + 2 - 90")
                        else:
                            exec(f"y_tick_label.{k} = dataname_scale_fmt['{k}']")
                    if ci == 0 and plottype!= "link" and max_value != min_value:
                        g.add(y_tick_label)

                """数据名称"""
                if inputdataname:
                    y_title_pos = getArcPoints(centerx, centery,
                        (inner_r + 0.5*value_dis * r_degrees if plottype != "link" else outer_r),
                        first_angle + dataname_title_angle_dr, 
                        first_angle + dataname_title_angle_dr)
                    y_title_label = Label(_text = str(inputdataname),
                        x = y_title_pos[0][0],
                        y = y_title_pos[0][1],
                        #angle  = first_angle + 15,
                        fontName = select_myfont(str(inputdataname)),
                        boxAnchor = "e",                        
                        )
                    for k in dataname_title_fmt.keys():
                        if k == "angle":
                            #angle = dataname_title_fmt[k] + (first_angle + 15 - 90)
                            #y_title_label.angle = angle
                            exec(f"y_title_label.{k} = dataname_title_fmt['{k}'] + \
                                {first_angle} + {dataname_title_angle_dr} - 90")
                        else:
                            exec(f"y_title_label.{k} = dataname_title_fmt['{k}']")
                    if ci == 0:
                        g.add(y_title_label)

                #染色体顺延索引+1
                ci += 1

        return g
            
    def savefile(self, outfile):
        """根据后缀保存文件"""
        if outfile.endswith(".pdf"):
            renderPDF.drawToFile(self.d, outfile)
        elif any([outfile.endswith(suffix) for suffix in [".png", ".jpg"]]):
            renderPM.drawToFile(self.d, outfile)
        elif outfile.endswith(".svg"):
            renderSVG.drawToFile(self.d, outfile)
        elif outfile.endswith(".eps"):
            renderPS.drawToFile(self.d, outfile, dpi=300) #, backend="_renderPM" "rlPyCairo"
        else:
            sys.stderr.write("Error outfile format\n")
            sys.exit(1)

    
