from pycircos import *
import click
import json

@click.command()
@click.argument("configfile")
def main(configfile):
    config = json.loads(open(configfile, 'r').read())    
    p = PyCircos(
        W = config["general"]["image_size"][0],
        H = config["general"]["image_size"][1],
        centerx  = config["general"]["plot_center"][0],
        centery  = config["general"]["plot_center"][1],
        chrlimit = config["general"]["draw_genomes"],
        datafile = config["dataFile"]["dataFilePath"],
        block_angles = config["general"]["block_angles"],
        first_angle  = config["general"]["first_angle"],
        first_end_block_angle = config["general"]["first_end_block_angle"],
        show_dataname = config["general"]["show_dataname"],
        dataname_scale_fmt = {
            "fontSize": config["general"]["dataname_scale_fontSize"],
            "angle":    config["general"]["dataname_scale_angle"],
            },
        dataname_title_fmt = {
            "fontSize": config["general"]["dataname_title_fontSize"],
            "angle":    config["general"]["dataname_title_angle"],
            },
        dataname_title_angle_dr = config["general"]["dataname_title_angle_dr"],
        )

    if config["plot_settings"]["show_genome"]:
        p.d.add(p.Genome(
            inner_r = config["general"]["genome_r"][0],
            outer_r = config["general"]["genome_r"][1],
            centerx = None,
            centery = None,            
            chrinfo = None,        #默认和BioCircos中datafile文件中genome文件一致
            show_karyotype = config["plot_settings"]["show_karyotype"],
            karyotype      = None, #默认和BioCircos中datafile文件中的karyotype内容一致
            chrtotalsize   = None, #默认和BioCircos中datafile文件中genome文件一致
            block_angles   = None, #默认和BioCircos一致
            show_chr_label = config["plot_settings"]["show_chr_label"],
            chr_label_dr   = config["plot_settings"]["chr_label_dr"],
            chr_label_fmt  = {
                "fontSize":  config["plot_settings"]["chr_label_fmt_fontSize"],
                "fillColor": mytoColor(config["plot_settings"]["chr_label_fmt_fillColor"]),
                },
            chr_ring_fmt = {
                "fillColor":   mytoColor(config["plot_settings"]["chr_ring_fmt_fillColor"]),
                "strokeColor": mytoColor(config["plot_settings"]["chr_ring_fmt_strokeColor"]),
                "strokeWidth": config["plot_settings"]["chr_ring_fmt_strokeWidth"],
                },
            show_cyto_label = config["plot_settings"]["show_cyto_label"],
            cyto_label_dr   = config["plot_settings"]["cyto_label_dr"],
            cyto_label_fmt  = {
                "fontSize":  config["plot_settings"]["cyto_label_fmt_fontSize"],
                "fillColor": mytoColor(config["plot_settings"]["cyto_label_fmt_fillColor"]),
                },
            cyto_ring_fmt  = {}, #为BioCircos中设置的默认值, 在karyotype文件中设置
            show_chr_scale = config["plot_settings"]["show_chr_scale"],
            chr_scale_step = config["plot_settings"]["chr_scale_step"],
            chr_scale_dr   = config["plot_settings"]["chr_scale_dr"],
            chr_scale_fmt  = {
                "strokeWidth": config["plot_settings"]["chr_scale_fmt_strokeWidth"],
                },
            chr_scale_label_fmt = {
                "fontSize": config["plot_settings"]["chr_scale_label_fmt_fontSize"],
                },
        ))
    
    if config["plot_settings"]["show_link"] and \
        len(p.all_data.get("link", [])) > 0:
        for num, inputdata in enumerate(p.all_data["link"]):
            if num > 1: continue #只显示绘制第1个link文件
            p.d.add(p.PlotData(
                inner_r   = config["general"][f"link_{num+1}_r"][0],
                outer_r   = config["general"][f"link_{num+1}_r"][1],
                plottype  = "link",
                inputdataname = inputdata[0],
                inputdata = inputdata[1],
                show_bg   = True,
                link_fmt  = {
                    "strokeWidth": config["plot_settings"]["link_strokeWidth"],
                    "strokeColor": mytoColor(config["plot_settings"]["link_strokeColor"]),
                    },
                show_label = config["plot_settings"]["show_link_label"],
                data_label_fmt = {
                    "fontSize":  config["plot_settings"]["link_label_fontSize"],
                    "fillColor": mytoColor(config["plot_settings"]["link_label_fillColor"]),
                    },
                ))
    if True: #肯定要绘制标题
        if config["general"]["title"]:
            p.d.add(Label(_text = str(config["general"]["title"]),
                x = config["general"]["title_pos"][0],
                y = config["general"]["title_pos"][1],
                fontName  = select_myfont(str(config["general"]["title"]),
                    bold=True, italic=False),
                fontSize  = config["general"]["title_fontSize"],
                fillColor = mytoColor(config["general"]["title_fillColor"]),
                boxAnchor = "c", #居中, 其他参数有: n,e,s,w,ne.nw,se,sw
            ))
    p.savefile("output.png")
    #p.savefile("output.pdf")

if __name__ == "__main__":
    main()

    
