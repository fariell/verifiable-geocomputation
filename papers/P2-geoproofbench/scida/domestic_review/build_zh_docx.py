#!/usr/bin/env python3
"""Build the Chinese review manuscript (.docx) from the SciDA final text."""
from __future__ import annotations

import os

from docx import Document
from docx.enum.table import WD_CELL_VERTICAL_ALIGNMENT, WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor

HERE = os.path.dirname(os.path.abspath(__file__))
FIG = os.path.abspath(os.path.join(HERE, "..", "figures"))
OUT = os.path.join(HERE, "面向数字高程模型分析的机器可检验命题集_中文送审稿.docx")

SONG = "SimSun"
HEI = "SimHei"
TIMES = "Times New Roman"


def _east_asia(run, name: str) -> None:
    run.font.name = TIMES
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.get_or_add_rFonts()
    rfonts.set(qn("w:ascii"), TIMES)
    rfonts.set(qn("w:hAnsi"), TIMES)
    rfonts.set(qn("w:eastAsia"), name)


def _run(p, text, *, size=12, bold=False, italic=False, color=None, font=SONG, super=False):
    r = p.add_run(text)
    r.bold = bold
    r.italic = italic
    r.font.size = Pt(size)
    if super:
        r.font.superscript = True
        r.font.size = Pt(max(8, size - 3))
    if color is not None:
        r.font.color.rgb = color
    _east_asia(r, HEI if bold and font == HEI else font)
    return r


def set_doc_defaults(doc: Document) -> None:
    sec = doc.sections[0]
    sec.page_width = Cm(21.0)
    sec.page_height = Cm(29.7)
    sec.left_margin = Cm(2.54)
    sec.right_margin = Cm(2.54)
    sec.top_margin = Cm(2.54)
    sec.bottom_margin = Cm(2.54)
    normal = doc.styles["Normal"]
    normal.font.name = TIMES
    normal.font.size = Pt(12)
    normal.element.rPr.rFonts.set(qn("w:eastAsia"), SONG)
    pf = normal.paragraph_format
    pf.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    pf.space_after = Pt(6)
    pf.first_line_indent = Cm(0.74)


def para(doc, text, *, size=12, bold=False, align="justify", first=True, space_after=6, font=SONG):
    p = doc.add_paragraph()
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    p.paragraph_format.space_after = Pt(space_after)
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.first_line_indent = Cm(0.74) if first else Cm(0)
    p.alignment = {
        "left": WD_ALIGN_PARAGRAPH.LEFT,
        "center": WD_ALIGN_PARAGRAPH.CENTER,
        "right": WD_ALIGN_PARAGRAPH.RIGHT,
        "justify": WD_ALIGN_PARAGRAPH.JUSTIFY,
    }[align]
    _run(p, text, size=size, bold=bold, font=HEI if bold and font == HEI else font)
    return p


def heading(doc, text, level: int) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_before = Pt(12 if level == 1 else 8)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    sizes = {1: 16, 2: 14, 3: 13}
    p.alignment = WD_ALIGN_PARAGRAPH.LEFT
    _run(p, text, size=sizes[level], bold=True, font=HEI)


def caption(doc, text) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(10)
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    _run(p, text, size=10.5, font=SONG)


def add_figure(doc, filename: str, cap: str) -> None:
    path = os.path.join(FIG, filename)
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_after = Pt(2)
    run = p.add_run()
    run.add_picture(path, width=Cm(15.8))
    caption(doc, cap)


def add_table(doc, headers, rows, cap: str) -> None:
    caption(doc, cap)
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = "Table Grid"
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for j, h in enumerate(headers):
        cell = table.rows[0].cells[j]
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        cell.text = ""
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.first_line_indent = Cm(0)
        _run(p, h, size=9, bold=True, font=HEI)
    for i, row in enumerate(rows):
        for j, val in enumerate(row):
            cell = table.rows[i + 1].cells[j]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            cell.text = ""
            p = cell.paragraphs[0]
            p.paragraph_format.first_line_indent = Cm(0)
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            _run(p, val, size=9, font=SONG)
    doc.add_paragraph().paragraph_format.space_after = Pt(6)


def bullet(doc, text) -> None:
    p = doc.add_paragraph()
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.left_indent = Cm(0.74)
    p.paragraph_format.space_after = Pt(3)
    _run(p, "• " + text, size=12, font=SONG)


def refs(doc, items) -> None:
    heading(doc, "参考文献", 1)
    for i, item in enumerate(items, 1):
        p = doc.add_paragraph()
        p.paragraph_format.first_line_indent = Cm(0)
        p.paragraph_format.left_indent = Cm(0.74)
        p.paragraph_format.first_line_indent = Cm(-0.74)
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.25
        _run(p, f"{i}. {item}", size=10.5, font=SONG)


def build() -> str:
    doc = Document()
    set_doc_defaults(doc)

    # Cover / review header
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_after = Pt(4)
    _run(p, "所内审查用中文稿", size=14, bold=True, font=HEI)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    _run(p, "对应投稿：Scientific Data · Data Descriptor（数据描述文）终稿", size=11, font=SONG)

    para(
        doc,
        "说明：本稿为英文投稿终稿的中文学术译文，供国内审查使用。章节结构、数字、标识符与判定与英文稿一致。"
        "专有名词、文件名、命题编号（如 GPB-001、P-COMP-1）及软件名称保持原文。"
        "参考文献条目保留英文著录，便于与期刊稿核对。本工作使用合成栅格与公开高程产品窗口，不含未公开内部数据。",
        first=False,
        size=10.5,
    )

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_before = Pt(18)
    p.paragraph_format.space_after = Pt(8)
    _run(p, "面向数字高程模型分析的机器可检验命题集", size=18, bold=True, font=HEI)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_after = Pt(4)
    _run(p, "A machine-checked proposition set for digital elevation model analysis", size=12, italic=True, font=TIMES)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_before = Pt(10)
    _run(p, "郭迎钢（通讯作者）", size=12, font=SONG)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    _run(p, "西北核技术研究所，西安 710024，中国", size=11, font=SONG)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    _run(p, "电子邮箱：fariel_gyg@163.com　　ORCID：0000-0002-8207-9941", size=11, font=SONG)

    heading(doc, "摘要", 1)
    para(
        doc,
        "本数据描述文提交 GeoProofBench v0.1，即一套经版本管理的、关于数字高程模型（DEM）算子的机器可检验命题目录。"
        "本发布包含六条已实现的一阶命题、五条组合或反例记录，以及四十四个为后续条目预留的占位标识符。"
        "每条已交付命题具有稳定标识符、单句性质、相互独立的 Dafny 与 Lean 4 规约、一道数值闸门，以及已记录的判定。"
        "算子包括 Wang–Liu 填洼与确定性八邻域（D8）流向。"
        "Wolfram 穷举检查与 manim 见证仅在实际使用处随数据集提交，不是每条标识符的必备项。"
        "所附定制代码仅用于复现上述判定。本数据集不提出新的插值方法。"
        "它记录性质在何处成立、在何处作为算子本身的性质而失败，以及重采样在何处预期会破坏唯一性。"
        "输入栅格包括 5×5 平面、256×256 合成地形、已标注的同尺寸合成占位，以及三幅公开产品窗口。"
        "数据许可为 CC-BY-4.0，软件许可为 MIT。",
    )

    heading(doc, "1　背景与概述", 1)
    para(
        doc,
        "三十年来，DEM 软件形成了一条共用分析流水线：填洼"
        "1、流向"
        "2,3、流域划分，以及坡度或曲率估计"
        "4,5。"
        "每一步在作业意义上被视为正确，却很少写成可供独立机器核验的陈述。"
        "同一栅格交给不同 GIS 软件，可以给出不同的流场和流域图"
        "6。"
        "这种分歧并非学究式好奇：汇水面积、河网长度与出口指派进入洪水制图、基础设施选址和已发表的流域统计。"
        "一个未经声明的平坦环，就足以把流域关系颠倒过来。"
        "GeoProofBench 之所以存在，是因为这些算子早已作为数据产品流通；所缺的是一份可引用的记录，写明每个算子本应履行的义务。",
        first=True,
    )
    # The superscripts above won't work as I mixed them into the string. I need a helper that parses [n] or I write paragraphs with explicit superscript runs.

    # Redo background with mixed runs - I'll replace the first para by a function that supports ^n^ markers.
    # Actually the para() already written doesn't have superscripts. Let me delete last para and rewrite using cite helper.

    # Simpler approach: use 上标括号 〔1〕 as plain [1] in Chinese academic style which is acceptable.
    # I'll rewrite using ［1］ inline which is standard in Chinese papers.

    # The previous para is already added without cites. I need to rebuild more carefully.
    # Easier: don't use the first heading body - I'll reconstruct the document from scratch
    # with a cite-aware paragraph function.

    return None  # placeholder; full rebuild below


def add_mixed(doc, parts, *, first=True, size=12, align="justify"):
    """parts: list of (text, kwargs) or plain str."""
    p = doc.add_paragraph()
    p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.first_line_indent = Cm(0.74) if first else Cm(0)
    p.alignment = {
        "left": WD_ALIGN_PARAGRAPH.LEFT,
        "center": WD_ALIGN_PARAGRAPH.CENTER,
        "justify": WD_ALIGN_PARAGRAPH.JUSTIFY,
    }[align]
    for part in parts:
        if isinstance(part, str):
            _run(p, part, size=size, font=SONG)
        else:
            text, kw = part
            _run(p, text, size=size, font=SONG, **kw)
    return p


def sup(n: str):
    return (n, {"super": True})


def build_full() -> str:
    doc = Document()
    set_doc_defaults(doc)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_after = Pt(2)
    _run(p, "所内审查用中文稿", size=14, bold=True, font=HEI)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_after = Pt(8)
    _run(p, "对应投稿：Scientific Data · Data Descriptor（数据描述文）终稿", size=11, font=SONG)

    add_mixed(
        doc,
        [
            "说明：本稿为英文投稿终稿的中文学术译文，供国内审查使用。章节结构、数字、标识符与判定与英文稿一致。"
            "专有名词、文件名、命题编号（如 GPB-001、P-COMP-1）及软件名称保持原文。"
            "参考文献条目保留英文著录，便于与期刊稿核对。本工作使用合成栅格与公开高程产品窗口，不含未公开内部数据。",
        ],
        first=False,
        size=10.5,
    )

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_before = Pt(16)
    p.paragraph_format.space_after = Pt(6)
    _run(p, "面向数字高程模型分析的机器可检验命题集", size=18, bold=True, font=HEI)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    _run(p, "A machine-checked proposition set for digital elevation model analysis", size=12, italic=True)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_before = Pt(12)
    _run(p, "郭迎钢（通讯作者）", size=12, font=SONG)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    _run(p, "西北核技术研究所，西安 710024，中国", size=11, font=SONG)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0)
    p.paragraph_format.space_after = Pt(12)
    _run(p, "电子邮箱：fariel_gyg@163.com　　ORCID：0000-0002-8207-9941", size=11, font=SONG)

    heading(doc, "摘要", 1)
    para(
        doc,
        "本数据描述文提交 GeoProofBench v0.1，即一套经版本管理的、关于数字高程模型（DEM）算子的机器可检验命题目录。"
        "本发布包含六条已实现的一阶命题、五条组合或反例记录，以及四十四个为后续条目预留的占位标识符。"
        "每条已交付命题具有稳定标识符、单句性质、相互独立的 Dafny 与 Lean 4 规约、一道数值闸门，以及已记录的判定。"
        "算子包括 Wang–Liu 填洼与确定性八邻域（D8）流向。"
        "Wolfram 穷举检查与 manim 见证仅在实际使用处随数据集提交，不是每条标识符的必备项。"
        "所附定制代码仅用于复现上述判定。本数据集不提出新的插值方法。"
        "它记录性质在何处成立、在何处作为算子本身的性质而失败，以及重采样在何处预期会破坏唯一性。"
        "输入栅格包括 5×5 平面、256×256 合成地形、已标注的同尺寸合成占位，以及三幅公开产品窗口。"
        "数据许可为 CC-BY-4.0，软件许可为 MIT。",
    )

    heading(doc, "1　背景与概述", 1)
    add_mixed(
        doc,
        [
            "三十年来，DEM 软件形成了一条共用分析流水线：按 Wang–Liu 溢流规则填洼（内部洼地抬至最低溢流水位）",
            sup("1"),
            "，流向（含确定性八邻域 D8 路由",
            sup("2"),
            "与平坦面指派",
            sup("3"),
            "），流域划分，以及 Horn 3×3 加权拟合或 Zevenbergen–Thorne 剖面曲率",
            sup("4,5"),
            "。每一步在作业意义上被视为正确，却很少写成可供独立机器核验的陈述。"
            "同一栅格交给不同 GIS 软件，可以给出不同的流场和流域图",
            sup("6"),
            "。近十年的栅格 DEM 算法选择仍会改变填洼处理、提取河网与剖面",
            sup("7–9"),
            "。这种分歧并非学究式好奇：汇水面积、河网长度与出口指派进入洪水制图、基础设施选址和已发表的流域统计。"
            "一个未经声明的平坦环，就足以把流域关系颠倒过来。"
            "GeoProofBench 之所以存在，是因为这些算子早已作为数据产品流通；所缺的是一份可引用的记录，写明每个算子本应履行的义务。",
        ],
    )
    add_mixed(
        doc,
        [
            "主要读者是生产并复用这些算子的 DEM 与水文学共同体。形式化方法是记录语言，而不是本数据集的研究对象。"
            "相邻领域已经把数值核当作证明义务来处理",
            sup("10–17"),
            "。DEM 表面也被用作地面车辆线性时序逻辑路径规划的输入",
            sup("18"),
            "。那条工作核验的是地形上的任务，而不是地形算子本身。"
            "GeoProofBench 与之互补：它归档后续规划器、模型或 GIS 工具可能默认成立的算子命题。",
        ],
    )
    add_mixed(
        doc,
        [
            "GeoAI 与水文学问答基准衡量的是与标注或教科书答案的一致性",
            sup("19,20"),
            "。这些资源对语言层面评价仍然有用。GeoProofBench 并不取代它们。"
            "它补上其下缺失的一层：当模型或 GIS 软件主张几何保证时，可以引用一个命题标识符，而不是在匹配标签答案时才引用。"
            "同一批标识符也是后续自动推理器、或引用 DEM 算子的 GeoMath 类智能体可以据以计分的具名义务。本发布不含已训练智能体。",
        ],
    )
    add_mixed(
        doc,
        [
            "GeoProofBench 首先是一份数据集：经版本管理的命题记录、栅格、度量表格与判定。"
            "数据记录一节列出十一条已交付记录（六条一阶算子与五条组合或反例）以及数据包文件布局。"
            "Dafny、Lean 4 与 Python 文件用于复现必选闸门。Wolfram 穷举检查与 manim 见证是可选提交物，不是每条记录的组成部分。"
            "这些代码都不能替代目录本身。"
            "标识符 GPB-006 至 GPB-014 以及 GPB-016 至 GPB-050 是为社区后续条目预留的占位名，不是已实现命题。"
            "此前没有任何论文发表过这一命题集。一篇相关的遥感文章",
            sup("21"),
            "不与本数据集共享数据。",
        ],
    )

    heading(doc, "2　方法", 1)
    heading(doc, "2.1　命题模型", 2)
    para(
        doc,
        "每条已交付命题沿三条独立轨道检查。Dafny 与 Lean 4 陈述抽象算子（填洼、D8、坡度、曲率）的性质，并证明关于这些规约的引理。"
        "后文的引理计数是针对规约的证明，并不证明某一 Python 文件是该算子的唯一实现。"
        "参考驱动是按规约撰写的规范 Python 重实现。数值闸门检查该重实现在所提交阵列上满足规约见证。"
        "Python 文件不是规约；规约是 Dafny 与 Lean 文件。闸门是有限测试，不是证明。"
        "仅当数值闸门成立且相应证明文件验证通过时，记录才标记为 PASS。"
        "两个证明器是同一义务的独立重述；互不以 Python 驱动作为对方的测试预言。"
        "小网格上的 Wolfram 穷举检查与 manim 见证仅在实际使用处提交。",
    )
    para(
        doc,
        "每条已交付命题具有稳定标识符、单句性质、一份 Dafny 规约、一份独立的 Lean 4 重述、一道 Python 数值闸门，以及已记录的判定。"
        "标识符、性质语句、栅格、度量 JSON 与判定构成数据记录。证明文件与驱动程序是复现程序。"
        "其余标签与 PASS 不可互换：",
    )
    bullet(
        doc,
        "FP（failure of property，性质失败）：在该输入类上命题已被断言，但所给算子并不满足。相对假设而言，失败是意外的。不把它当作软件崩溃。"
        "本发布未记录 FP 实例。v0.1 交付的是在其声明输入类上成立的义务、已文档化的反例，以及一条已文档化边界（FAIL-TOLERANCE）。"
        "若一条已在某输入类上断言的命题随后在该类实例上失败，才记录 FP。",
    )
    bullet(
        doc,
        "FAIL-TOLERANCE（容差失败）：输入落在命题所声明的前提之外，因此该性质不被断言。"
        "它不是允许算子出错，也不是意外失败（意外失败是 FP）。"
        "本发布仅用于 P-COMP-4 的四个 45° 格：在 0° 与 90° 上，对西向倾斜平面重采样后主张唯一 D8；"
        "在 45° 上双线性插值混合了基方向邻域，故不主张唯一 D8。该 45° 混合是 GIS 中已知的重采样边界，不是 GeoProofBench 的新发现。这些格子不计入 PASS 合计，也不改标为软件 FAIL。",
    )
    bullet(
        doc,
        "NEGATIVE-RESULT PASS（负结果通过）：反例本身就是预期记录（未填洼四环；Zevenbergen–Thorne 对 Horn）。",
    )

    heading(doc, "2.2　一阶算子", 2)
    add_mixed(
        doc,
        [
            "本发布完成六条算子（表5）。填洼遵循 Wang–Liu 溢流规则",
            sup("1"),
            "：内部洼地抬至最低溢流水位。填洼及其溢流与下标并列打破之后，D8 路由（O'Callaghan 与 Mark 的确定性八邻域规则）在严格下降规则下选择唯一最陡下降邻域",
            sup("2"),
            "：仅当该邻域严格低于中心时才记录后继；若无严格更低邻域，则标记为 NoFlow（无 D8 后继）。"
            "流域唯一性仅在填洼之后、在该严格下降条件下陈述。"
            "5×5 教学平面每流动一步高程下降 1，因为 A=1 且 w=1；P-COMP-1b 无下降，因为未填洼环是平坦的。"
            "Zevenbergen–Thorne 剖面曲率",
            sup("5"),
            "与 Horn 二阶拟合",
            sup("4"),
            "分别给出规约，不视为可互换（见技术验证）。",
        ],
    )

    heading(doc, "2.3　组合", 2)
    para(
        doc,
        "P-COMP-1 断言：经 Wang–Liu 填洼后，在 D8 下每个内部格恰有一个终点。论证使用五条引理：填洼给出 min(nbr)≤cell；"
        "随后 D8 下降；内部轨道在 n·m 步内由鸽笼原理封闭；矩形边界提供一个无流终点；唯一性把候选终点坍缩。"
        "P-COMP-1b 是互补见证：未填洼的四格平坦环不终止。"
        "P-COMP-2 把同一链条实例化到 256² 常值平面以及行向坡度 ε∈{10⁻⁶, 10⁻⁴}。"
        "P-COMP-4 把西向倾斜平面按尺度 {0.5, 1, 2, 4}× 与旋转 {0°, 45°, 90°} 重采样。"
        "其前提是旋转 ∈{0°, 90°}；仅在这些角度上主张重采样后唯一 D8。"
        "四个 45° 格落在前提之外：双线性插值混合基方向邻域。该混合是 GIS 中已知的重采样边界，不是 GeoProofBench 的新发现。"
        "P-COMP-5 检查填洼幂等性，以及一维填洼输出在 Python、Dafny 与 Lean 之间的哈希一致。"
        "幂等 fill(fill(h))=fill(h) 的主张范围是无 NoData、有限实数的矩形栅格。",
    )
    para(
        doc,
        "图1是该链条的教学模板。图1a 为未填洼四格平坦环（P-COMP-1b）：D8 循环而不终止。"
        "图1b 为 5×5 教学平面 h(p,q)=Ap+Bq+C，其中 A=1（沿列下标减小方向每格高程下降）、B=0、C=12（中心高程）；"
        "(p,q) 为相对网格中心的整数偏移，格距 w=1。填洼后流向唯一向西。"
        "图1c 给出 Dafny 与 Lean 文件所记录的五引理次序；它是证明结构图，不是额外的数值闸门。"
        "多分辨率数据层与公开窗口见图2与图3，不是本教学模板。",
    )
    add_figure(
        doc,
        "fig1_fill_watershed.png",
        "图1　P-COMP-1 的教学模板。（a）条件边界反例（P-COMP-1b）：未填洼四格平坦环，D8 循环而不终止。"
        "（b）填洼后 5×5 教学平面 h=Ap+Bq+C，A=1，B=0，C=12。金色箭头标出唯一向西的 D8 后继。"
        "（c）Dafny 与 Lean 记录的五引理链。云端 dafny verify PCOMP_1.dfy 对该编译单元报告 17 verified members / 0 errors（含 include）；"
        "Lean lake build 为 0 errors。图1a 与 P-COMP-3 同为 NEGATIVE-RESULT PASS，但种类不同。",
    )

    heading(doc, "2.4　输入栅格", 2)
    add_mixed(
        doc,
        [
            "多分辨率套件所用的四套数据列于表6。三幅合成阵列的生成参数见表1；驱动程序为 experiments/phase2/ 下的 p_comp_1_multires.py。"
            "该套件需要四种网格尺寸，包括 3601² 的 SRTM 形状阵列以及 4 m 粗化后的 256² 阵列。"
            "作者工作站未能取得这两个尺寸的完整公开文件。这是本发布的获取限制，不是 SRTM 或 3DEP 产品本身的缺陷。"
            "随后取得的公开产品检查是 Copernicus GLO-30 瓦片 N32E110 以及 3DEP ImageServer 窗口（表7、图3）。"
            "它们不能代替 3601² 的尺寸应力栅格：256² 的 GLO-30 窗口不是 3601² 的 SRTM 瓦片。"
            "因此 v0.1 为这两个尺寸提交已标注的合成占位；后续版本可以加入真正的 3601² SRTM 瓦片，在此之前这些行不是产品精度声明。"
            "1 m 与 5 m 窗口取自同产品族的 3DEP ImageServer 最近邻导出，而非已分级的 USGS COG 文件（端点见数据可用性）。"
            "三幅公开产品为：USGS 3DEP 1 m 激光雷达窗口（洛杉矶 Griffith Park）",
            sup("22"),
            "、USGS 3DEP 5 m 阿拉斯加 IFSAR 窗口（Fairbanks 一带）",
            sup("23"),
            "，以及 Copernicus DEM GLO-30 瓦片 N32E110 上的窗口",
            sup("24"),
            "。",
        ],
    )
    para(doc, "在其他闸门中注入噪声时，σ∈{0, 10⁻³, 10⁻², 10⁻¹, 0.5} m。")

    add_table(
        doc,
        ["数据层", "生成方式"],
        [
            [
                "terrain-A（256²，5 m）",
                "ramp 0.05x+0.02y，两座高斯丘，十二个开挖洼地，再叠加 N(0, 5×10⁻³)，NumPy 整数种子 20260906（numpy.random.default_rng）。",
            ],
            [
                "SRTM 尺度（3601²，30 m）",
                "N32E110 的 .hgt.gz 未能完整获取后使用。"
                "1180+0.035(3600−x)+85 sin(x/180)+55 cos(y/220)+25 sin((x+y)/95)，再叠加 N(0, 1.6)，整数种子 11032。",
            ],
            [
                "lidar-down（256²，4 m）",
                "细网格 1024² 场 0.04x+0.015y+4 sin(x/18) cos(y/22)+1.2 sin(x/3.5)+0.8 cos(y/4.2)，再叠加 N(0, 0.25)，整数种子 20260907，然后 4×4 块平均到 256²。",
            ],
        ],
        "表1　合成栅格生成器（非产品精度）。三幅占位均由 p_comp_1_multires.py 重建。高斯 σ 的单位为高程米。",
    )

    heading(doc, "2.5　验证环境", 2)
    para(
        doc,
        "数值闸门在作者工作站上以 Python 3.12（NumPy）运行。"
        "Dafny 4.11 与带 mathlib 的 Lean 4.18.0 从所提交源码在独立 AutoDL 云端镜像上重跑，该镜像不共享工作站验证器缓存；"
        "下文引用的引理计数来自这些云端日志，而不是本地输出的副本。"
        "Wolfram Script 14 仅在工作站使用（云端镜像无 Wolfram 许可；该跳过已记录，不视为 FAIL）。"
        "命令与路径位于数据集中的 experiments/ 与 formal/。",
    )

    heading(doc, "3　数据记录", 1)
    add_mixed(
        doc,
        [
            "形式化规约提供最高记录保证，但核心数据产品——命题语句、输入栅格、度量表与判定——可以不依赖 Dafny 或 Lean 而使用和引用。"
            "可引用对象是科学数据银行上的命题目录 GeoProofBench-v0.1-deposit.zip",
            sup("25"),
            "。表3列出十一条已交付记录。四十四个占位标识符（GPB-006 至 014 与 GPB-016 至 050）写在 benchmark/ 中，是计划扩展，不是 v0.1 的已实现命题，也不作为表3的行。"
            "表4为数据包文件布局。数据记录侧重 JSON、栅格与度量表；代码可用性列出 Dafny、Lean 与 Python 复现文件。",
        ],
    )
    para(
        doc,
        "度量 JSON 位于 experiments/phase2/results/，文件名为 gpb021（P-COMP-1）、gpb024*（多分辨率）、"
        "gpb025*（重采样）、gpb026*（哈希）以及 gpb027_realworld。"
        "表2为字段词典。表6中 n_out 列对应 JSON 字段 uniq_out。"
        "除非某套件另有说明，n_term 与 uniq_out 在内部框上计算（去掉一格边界）。",
    )

    add_table(
        doc,
        ["字段", "类型", "单位", "定义"],
        [
            ["n_pit", "整数", "—", "未填洼栅格上内部四邻域局部极小值个数。"],
            ["n_term", "整数", "—", "D8 轨道到达终点的内部格个数。"],
            ["uniq_out", "整数", "—", "这些终止格中互异终点的个数。"],
            ["longest", "整数", "格步", "最长终止 D8 路径的长度。"],
            ["ridgeline_frac", "浮点", "1", "D8 入度为 0 的内部格比例。"],
            [
                "drainage_density_per_m",
                "浮点",
                "m⁻¹",
                "入度≥2 的内部格个数，除以（内部格数×格距）。",
            ],
        ],
        "表2　本描述文所用度量 JSON 字段词典。",
    )
    add_table(
        doc,
        ["状态", "数量", "标识符", "说明"],
        [
            ["一阶", "6", "GPB-001 至 005 与 GPB-015", "GPB-002b 为 002 的二维配套（见表5），不是第七条一阶标识符"],
            ["组合", "5", "P-COMP-1 至 5", "P-COMP-1b 为 1 的未填洼环配套"],
        ],
        "表3　已交付的 GeoProofBench v0.1 记录。配套不计入额外的一阶或组合标识符。",
    )
    add_table(
        doc,
        ["路径", "内容"],
        [
            ["experiments/phase2/results/", "度量 JSON：gpb021、gpb024*、gpb025*、gpb026*、gpb027_realworld。"],
            ["experiments/*/figures/", "可选 mp4 见证（若已提交）。"],
            ["benchmark/", "标识符列表，含四十四个计划扩展占位。"],
            ["papers/P2-geoproofbench/", "描述文文本与插图。"],
            ["formal/dafny/*.dfy", "13 个 Dafny 规约文件（见代码可用性）。"],
            ["formal/lean4/", "VeriGIS 库、lakefile.toml、lean-toolchain（见代码可用性）。"],
        ],
        "表4　数据包文件布局。度量 JSON 的 SHA-256 在对应结果文件中；Lake 缓存未提交。",
    )
    add_table(
        doc,
        ["标识符", "性质", "主导 Dafny 文件"],
        [
            ["GPB-001", "平面上的坡度符号", "P001_horn_slope.dfy"],
            ["GPB-002", "填洼至溢流水位", "P002_pit_filling.dfy"],
            ["GPB-002b", "二维填洼单调且幂等", "P002_pit_filling_2d.dfy"],
            ["GPB-003", "平面上 ZT 曲率为零", "P003_curvature.dfy"],
            ["GPB-004", "平面上 Horn 拟合精确", "P004_consistency.dfy"],
            ["GPB-005", "唯一 D8 后继", "P005_d8.dfy"],
            ["GPB-015", "D8 下的流域唯一性", "P006_watershed.dfy"],
        ],
        "表5　已交付一阶算子及主导工件。GPB-002b 是 GPB-002 的二维配套，不是第七条一阶标识符。"
        "六条一阶记录为 GPB-001 至 005 与 GPB-015。GPB-015 使用历史文件前缀 P006（流域模块）；标识符是 015，与六条计数并不冲突。",
    )
    add_table(
        doc,
        ["数据层", "网格", "n_pit", "n_term", "n_out", "longest"],
        [
            ["plane-5 m", "5×5", "0", "9", "3", "3"],
            ["terrain-A", "256²", "53", "64516", "98", "351"],
            ["SRTM 尺度占位*", "3601²", "2519307", "12952801", "6027216", "28"],
            ["lidar-down 占位*", "256²", "1782", "64516", "20137", "13"],
        ],
        "表6　同一填洼后 D8 链条所用的多分辨率数据层。星号标合成占位，不是公开高程产品。",
    )

    heading(doc, "4　数据概览", 1)
    para(
        doc,
        "表6与图2在四种网格尺寸上报告同一填洼后 D8 程序。填洼后每个内部格均终止（n_term 等于内部格数）。"
        "互异出口数随粗糙度与网格增大：5×5 平面为 3，terrain-A 为 98，含噪 SRTM 尺度占位为 6.03×10⁶。"
        "最长路径并不按同一方式缩放：terrain-A 达 351 步，而 lidar-down 占位经 4×4 块平均后，尽管同为 256²，最长路径仅为 13。"
        "正因如此，图2是数据图而不是结果图：它显示所提交数据层如何不同，而不是一种新的插值器。",
    )
    add_figure(
        doc,
        "fig2_multires.png",
        "图2　四套已提交数据层上的填洼后 D8 清单。（a）单位平面 5×5，以带标签网格与 D8 箭头显示（平面上山影无定义）；格内数字为高程。"
        "（b）合成 terrain-A，256²。（c）SRTM 尺度占位。所提交文件是完整 3601² 阵列；本面板仅为显示用块平均降采样，不能代替该栅格。"
        "（d）lidar-down 占位，256²；4 m 上 4×4 块平均后的块状残差是所提交数据层的性质，不是显示伪影。"
        "图2b–d 各面板独立用颜色表示高程（蓝/绿较低，黄/白较高）。n_pit、n_out 与最长路径为已提交度量。"
        "图2c、图2d 不是公开高程产品。公开产品窗口见图3。",
    )
    para(
        doc,
        "表7把同一闸门用于三幅形状同为 256² 的公开产品窗口。三者均 PASS P-COMP-1（填洼后内部洼地为 0；64,516 / 64,516 内部格终止）。"
        "随格距由 1 m 激光雷达增至 28.4 m GLO-30，山脊比例上升、河网密度下降。"
        "该趋势与粗化的预期效应一致，是这三幅窗口的特征，不是对这些地貌的一般性声明。"
        "需要为填洼后唯一出口给出具名义务的水文用户，可从 P-COMP-1 与表7入手；需要为旋转重采样给出具名边界的开发者，应使用使用说明中的 FAIL-TOLERANCE 格。"
        "进一步的汇总统计应从所提交阵列计算。",
    )
    add_table(
        doc,
        ["窗口", "格距", "n_pit", "n_out", "ridge", "Dd"],
        [
            ["USGS 3DEP 激光雷达，Griffith Park", "1 m", "88", "234", "0.125", "0.106"],
            ["阿拉斯加 IFSAR，Fairbanks 窗口", "5 m", "270", "253", "0.225", "0.0363"],
            ["Copernicus GLO-30，N32E110", "28.4 m", "626", "4981", "0.318", "0.00685"],
        ],
        "表7　公开产品窗口（256²）；P-COMP-1 闸门全部 PASS。ridge：内部 D8 入度为 0。Dd：河网密度（m^-1）。",
    )
    add_figure(
        doc,
        "fig3_realworld.png",
        "图3　用于多样性检查的公开 256² 窗口。（a）USGS 3DEP 1 m 激光雷达，Griffith Park。"
        "（b）USGS 3DEP 5 m IFSAR，Fairbanks 一带。（c）Copernicus GLO-30，瓦片 N32E110。"
        "色阶按面板各自映射高程（蓝/绿较低，黄/白较高），不能当作产品之间的高程比较。"
        "各面板报告同一填洼后 D8 程序下的内部洼地数 n_pit、山脊比例（内部 D8 入度为 0 的格）以及河网密度 Dd"
        "（入度≥2 的内部格除以内部格数乘格距）。三幅窗口均 PASS P-COMP-1。",
    )

    heading(doc, "5　技术验证", 1)
    para(
        doc,
        "验证支持所提交记录的技术质量。它不是对新地形算法的分析。表8汇总用户可从档案复现的闸门。",
    )
    add_table(
        doc,
        ["记录", "判定"],
        [
            ["P-COMP-1，5×5 平面", "PASS"],
            ["P-COMP-1b 四环", "NEGATIVE-RESULT PASS"],
            ["P-COMP-2", "PASS"],
            ["P-COMP-3", "NEGATIVE-RESULT PASS"],
            ["P-COMP-4", "8 PASS + 4 FAIL-TOLERANCE（全部为 45° 旋转）"],
            ["P-COMP-5 哈希 / 二维填洼", "12/12 与 4/4 PASS"],
            ["三幅公开窗口", "PASS"],
            ["FP（本发布）", "无实例"],
        ],
        "表8　已记录判定汇总。FAIL-TOLERANCE 格不计入 PASS 合计。本发布未记录 FP 实例。",
    )

    heading(doc, "5.1　数值闸门与形式闸门", 2)
    para(
        doc,
        "在用于 P-COMP-1 的 5×5 单位平面上（图1b），记录报告：填洼后无内部洼地；每个流动 D8 步高程下降 1；"
        "全部 9 个内部格至多 3 步终止，有 3 个互异出口。"
        "作者工作站上对 4⁴ 张映射的 Wolfram 穷举给出 pigeonholeAll=true、descentAllFix=true、ringHasFixedPoint=false。"
        "AutoDL 云端镜像无 Wolfram 许可并跳过该脚本；Python、Dafny 与 Lean 闸门不依赖它。",
    )
    para(
        doc,
        "对所提交文件独立进行的 AutoDL 云端 dafny verify 重跑（无工作站缓存）报告："
        "PCOMP_1.dfy 为 17 verified members / 0 errors，终止文件 P006_terminate_under_strict.dfy 为 12 / 0。"
        "同一镜像报告 PCOMP_2.dfy 为 25 / 0，PCOMP_4_homotopy.dfy 为 20 / 0，PCOMP_5_idempotent.dfy 为 15 / 0。"
        "这些整数是各编译单元（该文件及其 include）的验证器成员计数，不是 GeoProofBench 的引理总数。"
        "PCOMP_1.dfy 本身陈述 11 条引理：五条对应图1c 的 (i)–(v)（NoPitImpliesDescent、D8PreservesDescent、OrbitLengthBound、BoundaryNonEmpty、FillThenWatershed）；其余为二维或鸽笼变体、唯一性包装与一例。"
        "所提交 VeriGIS 库相对锁定 mathlib 的 Lean lake build 同样在该镜像上执行，并以 0 errors 完成：库可构建。"
        "锁文件导入 2764 个 mathlib 模块；该数字是工具链规模，不是 GeoProofBench 引理数，也不用作命题成立的证据。",
    )
    para(
        doc,
        "P-COMP-2：256² 常值平面有 65536 / 65536 个终止格（全部为 NoFlow）。"
        "行向坡 ε=10⁻⁶ 与 10⁻⁴ 终止，最长路径 255，出口 256 个（全部向北）。"
        "P-COMP-2 的度量 JSON 报告 visited_cells=16,908,288。该字段是路径长度求和，不是互异格普查，也不是表6的一列。"
        "对每个起始格，驱动程序把 D8 路径步数加一（起点本身），再对每套 256² 起始格求和。"
        "常值平面贡献 65,536。每条行向坡套件贡献 8,421,376（256×(255×256/2)+65,536）。三套合计 16,908,288。",
    )
    para(
        doc,
        "P-COMP-4：12 个尺度–旋转格中 8 个在唯一 D8 且 σ=0 下 PASS。四个 45° 格全部为上文定义的 FAIL-TOLERANCE（前提旋转 ∈{0°, 90°}）。"
        "P-COMP-5：四个一维填洼实例（平面、洼地、斜坡、级联）用 SHA-256 在 Python、Dafny 与 Lean 中哈希。"
        "全部 4 个实例 × 3 种实现一致，记为 12 / 12。"
        "二维 fill(fill(h))=fill(h) 在 σ=0 下于四幅无 NoData、有限实数的矩形栅格成立（4 / 4）。"
        "反向堆并列调度一并检查：Wang–Liu 优先洪水以填洼高程再加 (r,c) 为堆键；把 (r,c) 分量变号得到第二种调度。两套输出在所记录 epsilon 内一致。",
    )
    para(doc, "三幅公开窗口上的 P-COMP-1：填洼后内部洼地为 0；64516 / 64516 内部格终止（表7）。")

    heading(doc, "5.2　作为记录保留的反例", 2)
    para(
        doc,
        "未填洼四环是不终止的 D8 轨道（P-COMP-1b；图1a）：这是条件边界反例，标出 P-COMP-1 不适用的范围。"
        "两幅 9×9 斑块 z=D x²+A x 表明 Zevenbergen–Thorne 剖面曲率 H_xx=2D 与 Horn 二阶系数 D_x=A 不是同一函数（P-COMP-3；图4）。"
        "系数对 (A,D)=(0.21, 0.00705) 与 (0.07, 0.03485) 经选择使中心格取值均非零且不同时为零，不是随机抽取。"
        "该图是存在性见证，不是总体推断。二者均编目为 NEGATIVE-RESULT PASS。",
    )
    add_figure(
        doc,
        "fig4_zt_horn.png",
        "图4　算子不可互换反例（P-COMP-3），与图1a 条件边界环种类不同的 NEGATIVE-RESULT PASS。"
        "（a）网格 A：z=D x²+A x，A=0.21，D=0.00705。（b）网格 B：A=0.07，D=0.03485。"
        "H_xx 为 Zevenbergen–Thorne 剖面曲率；D_x 为 Horn 东西向二阶坡度系数。"
        "中心格取值均非零且不同时为零，故两算子不可互换。网格证明存在性，不是总体主张。",
    )

    heading(doc, "6　使用说明", 1)
    heading(doc, "6.1　预期复用", 2)
    para(doc, "预设三条入口。")
    para(
        doc,
        "DEM 算法开发者可以把 GPB 标识符附着到坡度、填洼、D8 或流域实现上，并在其输出栅格上重跑所提交的 Python 闸门。"
        "该路径是样本测试：检查有限阵列，不是对新代码的证明。"
        "失配于是与具名义务不一致，而不是与未命名的实验室惯例不一致。"
        "已文档化的反例（P-COMP-1b、P-COMP-3）是新算法的压力测试：它们标出在填洼良好、坡度清楚的栅格上做常规精度评分时容易漏掉的边界情形。",
    )
    para(
        doc,
        "水文模拟者可在工作流主张填洼后唯一出口时引用 P-COMP-1；当研究区含平坦或旋转重采样时，可引用 P-COMP-1b 或 45° FAIL-TOLERANCE 格。"
        "表7中的公开窗口度量是起始示例，不是区域产品。",
    )
    para(
        doc,
        "需要机器检验保证的形式化方法研究者，须对照所提交的 Dafny 或 Lean 规约重述其算子，并重跑 dafny verify 或 lake build。"
        "Lean 重述独立于 Dafny 内核；一致是交叉核对，而不是复制脚本。"
        "该嵌入是专家路径，仅重跑 Python 闸门的 GIS 用户不必走这条路。"
        "占位标识符 GPB-006 至 GPB-014 以及 GPB-016 至 GPB-050 是扩展面。",
    )

    heading(doc, "6.2　如何运行", 2)
    para(
        doc,
        "从数据集根目录起，每个算子有 run_*.sh（Windows 上为对应 .py）。"
        "形式文件用 dafny verify formal/dafny/<file>.dfy 以及 cd formal/lean4 && lake build 验证。"
        "Lean 4.18.0 由 formal/lean4/lean-toolchain 锁定。Lake 缓存未提交；首次 lake build 按锁文件获取 mathlib（需要网络；冷缓存约数十分钟）。"
        "Python 驱动导入 NumPy，公开窗口另需 GDAL；这些 import 即所提交的依赖清单。Wolfram 脚本可选。不要把缺少 Wolfram 许可当作闸门失败。",
    )
    para(
        doc,
        "45° 重采样格以及合成 SRTM / lidar-down 行是有意设置的边界。本发布不含 GPU 并行汇流累积。",
    )

    heading(doc, "7　数据可用性", 1)
    add_mixed(
        doc,
        [
            "数据记录一节列出文件与格式。版本记录在科学数据银行 V1 开放获取",
            sup("25"),
            "：https://doi.org/10.57760/sciencedb.011r9"
            "（CSTR https://cstr.cn/31253.11.sciencedb.011r9；标识符 31253.11.sciencedb.011r9）。"
            "下载不受限制。数据许可 CC-BY-4.0，软件许可 MIT。",
        ],
    )
    add_mixed(
        doc,
        [
            "所用公开栅格获取方式如下。USGS 3DEP 窗口来自 ImageServer 导出"
            " https://elevation.nationalmap.gov/arcgis/rest/services/3DEPElevation/ImageServer/exportImage ，"
            "参数 bboxSR=4326、imageSR=4326、size=256,256、format=tiff、interpolation=RSP_NearestNeighbor："
            "Griffith Park 激光雷达（west=−118.2964，south=34.1348，格距 1 m）",
            sup("19"),
            "以及 Fairbanks IFSAR（west=−147.815，south=64.894，格距 5 m）",
            sup("20"),
            "。Copernicus GLO-30 瓦片 N32E110",
            sup("21"),
            "用 GDAL /vsicurl/ 读取公开 COG："
            "https://copernicus-dem-30m.s3.eu-central-1.amazonaws.com/Copernicus_DSM_COG_10_N32_00_E110_00_DEM/Copernicus_DSM_COG_10_N32_00_E110_00_DEM.tif。",
        ],
    )
    para(
        doc,
        "本工作仅使用合成栅格与公开高程产品，不涉及人类受试者、个人数据或受限地理资料。",
        first=True,
    )

    heading(doc, "8　代码可用性", 1)
    para(
        doc,
        "定制代码与数据同归档（MIT 许可）。Dafny 规约在 formal/dafny/（13 个文件）；"
        "Lean 4 重述在 formal/lean4/（lakefile.toml、lean-toolchain；省略 Lake 缓存）；"
        "Python 与可选 Wolfram 驱动在 experiments/。"
        "生成当前判定所用软件版本：Python 3.12、Dafny 4.11、带 mathlib 的 Lean 4.18.0、NumPy、用于窗口 GeoTIFF 读取的 GDAL、manim 0.21（动画）。"
        "公开栅格见数据可用性。"
        "同一目录树亦置于 https://github.com/fariell/verifiable-geocomputation（公开开发副本；Scientific Data 非双盲）。"
        "审稿人可从数据可用性 DOI 的不受限科学数据银行压缩包下载代码，不另设匿名 GitHub 镜像。"
        "数值闸门不需要额外专有二进制。",
    )

    heading(doc, "9　资助", 1)
    para(
        doc,
        "本研究未获得外部资助，亦无项目编号。工作由作者在西北核技术研究所的单位时间内完成。",
        first=True,
    )

    heading(doc, "10　作者贡献", 1)
    para(doc, "郭迎钢提出工作、撰写规约与驱动程序、执行验证并撰写文稿。", first=True)

    heading(doc, "11　利益冲突", 1)
    para(doc, "作者声明不存在利益冲突。", first=True)

    refs(
        doc,
        [
            "Wang, L. & Liu, H. An efficient method for identifying and filling surface depressions in digital elevation models for hydrologic analysis and modelling. Int. J. Geogr. Inf. Sci. 20, 193–213 (2006). https://doi.org/10.1080/13658810500433453",
            "O'Callaghan, J. F. & Mark, D. M. The extraction of drainage networks from digital elevation data. Comput. Vis. Graph. Image Process. 28, 323–344 (1984). https://doi.org/10.1016/S0734-189X(84)80011-0",
            "Garbrecht, J. & Martz, L. W. The assignment of drainage direction over flat surfaces in raster digital elevation models. J. Hydrol. 193, 204–213 (1997). https://doi.org/10.1016/S0022-1694(96)03138-1",
            "Horn, B. K. P. Hill shading and the reflectance map. Proc. IEEE 69, 14–47 (1981). https://doi.org/10.1109/PROC.1981.11918",
            "Zevenbergen, L. W. & Thorne, C. R. Quantitative analysis of land surface topography. Earth Surf. Process. Landf. 12, 47–56 (1987). https://doi.org/10.1002/esp.3290120107",
            "Zhou, Q. & Liu, X. Error assessment of grid-based flow routing algorithms used in hydrological models. Int. J. Geogr. Inf. Sci. 18, 319–338 (2004). https://doi.org/10.1080/13658810410001690444",
            "Lindsay, J. B. Efficient hybrid breaching-filling sink removal methods for flow path enforcement in digital elevation models. Hydrol. Process. 30, 846–857 (2016). https://doi.org/10.1002/hyp.10648",
            "Schwanghart, W. & Scherler, D. Bumps in river profiles: uncertainty assessment and smoothing using quantile regression techniques. Earth Surf. Dynam. 5, 821–839 (2017). https://doi.org/10.5194/esurf-5-821-2017",
            "Clubb, F. J. et al. Geomorphometric delineation of floodplains and terraces from objectively defined topographic thresholds. Earth Surf. Dynam. 5, 369–385 (2017). https://doi.org/10.5194/esurf-5-369-2017",
            "Boldo, S., Filliâtre, J.-C. & Melquiond, G. Combining Coq and Gappa for certifying floating-point programs. In Intelligent Computer Mathematics (eds Carette, J. et al.) 59–73 (Springer, 2009). https://doi.org/10.1007/978-3-642-02614-0_10",
            "Melquiond, G. Proving bounds on real-valued functions with computations. In Automated Reasoning (eds Armando, A. et al.) 2–17 (Springer, 2008). https://doi.org/10.1007/978-3-540-71070-7_2",
            "Fumex, C., Marché, C. & Moy, Y. Automating the verification of floating-point programs. In Verified Software: Theories, Tools, and Experiments (eds Paskevich, A. & Wies, T.) 102–119 (Springer, 2018). https://doi.org/10.1007/978-3-319-72308-2_7",
            "Fulton, N. et al. KeYmaera X: an axiomatic tactical theorem prover for hybrid systems. In Automated Deduction — CADE-25 (eds Felty, A. P. & Middeldorp, A.) 527–538 (Springer, 2015). https://doi.org/10.1007/978-3-319-21401-6_36",
            "Mitsch, S. & Platzer, A. ModelPlex: verified runtime validation of verified cyber-physical system models. Form. Methods Syst. Des. 49, 33–74 (2016). https://doi.org/10.1007/s10703-016-0241-z",
            "Zinzindohoué, J.-K., Bhargavan, K., Protzenko, J. & Beurdouche, B. HACL*: a verified modern cryptographic library. In Proc. 2017 ACM SIGSAC Conf. Computer and Communications Security 1789–1806 (ACM, 2017). https://doi.org/10.1145/3133956.3134043",
            "Leino, K. R. M. Dafny: an automatic program verifier for functional correctness. In Logic for Programming, Artificial Intelligence, and Reasoning (eds Clarke, E. M. & Voronkov, A.) 348–370 (Springer, 2010). https://doi.org/10.1007/978-3-642-17511-4_20",
            "The mathlib Community. The Lean mathematical library. In Proc. 9th ACM SIGPLAN Int. Conf. Certified Programs and Proofs 367–381 (ACM, 2020). https://doi.org/10.1145/3372885.3373824",
            "Toscano-Moreno, M., Mandow, A., Martínez, M. A. & García-Cerezo, A. J. SPIN-based linear temporal logic path planning for ground vehicle missions with motion constraints on digital elevation models. Sensors 24, 5166 (2024). https://doi.org/10.3390/s24165166",
            "Mai, G. et al. On the opportunities and challenges of foundation models for GeoAI (vision paper). ACM Trans. Spatial Algorithms Syst. 10, 11 (2024). https://doi.org/10.1145/3653070",
            "Kizilkaya, D., Sajja, R., Sermet, Y. & Demir, I. Toward HydroLLM: a benchmark dataset for hydrology-specific knowledge assessment for large language models. Environ. Data Sci. 4, e31 (2025). https://doi.org/10.1017/eds.2025.10006",
            "Guo, Y., Liu, X., Rong, J., Shi, F. & Tang, C. SAM-GFNet: generalized feature fusion with hierarchical network for hyperspectral image semantic segmentation. Remote Sens. 17, 3662 (2025). https://doi.org/10.3390/rs17223662",
            "National Geospatial Technical Operations Center, Earth Resources Observation and Science Center & National Geospatial Program. Seamless 1 meter Digital Elevation Models (DEMs) — USGS National Map 3DEP Downloadable Data Collection. U.S. Geological Survey https://doi.org/10.5066/P13LJKFS (2025).",
            "U.S. Geological Survey, Earth Resources Observation and Science Center. Digital elevation — Interferometric synthetic aperture radar (IFSAR) — Alaska. U.S. Geological Survey https://doi.org/10.5066/P9C064CO (2013).",
            "European Space Agency. Copernicus DEM — Global and European Digital Elevation Model (COP-DEM). https://doi.org/10.5270/ESA-c5d3d65",
            "Guo, Y. GeoProofBench v0.1: a machine-checked proposition set for digital elevation model analysis. Science Data Bank https://doi.org/10.57760/sciencedb.011r9 (2026). CSTR: 31253.11.sciencedb.011r9.",
        ],
    )

    heading(doc, "附录　英文投稿说明函中译文（审稿人看不到原函）", 1)
    para(doc, "致 Scientific Data 主编 Guy Jones 博士：", first=True)
    para(
        doc,
        "现提交数据描述文《面向数字高程模型分析的机器可检验命题集》（文章类型：Data Descriptor；唯一作者）。"
        "文稿提交 GeoProofBench v0.1，即一套关于 DEM 算子的、经版本管理的机器可检验命题目录。文稿不提出新的插值方法。"
        "本发布含六条已实现一阶命题（GPB-001 至 005 与 GPB-015）、五条组合或反例记录（P-COMP-1 至 5）以及四十四个占位标识符。"
        "占位名称不是已实现命题。Dafny 与 Lean 文件不共享内核。"
        "云端重跑报告各编译单元的 verified members 计数（含 include），不是 GeoProofBench 引理总数；"
        "PCOMP_1.dfy 本身有 11 条引理。Lean lake build 为 0 errors。"
        "锁文件导入 2764 个 mathlib 模块，该数字是工具链规模，不是引理数。"
        "反例作为记录保留。数据集在科学数据银行 V1 开放获取：https://doi.org/10.57760/sciencedb.011r9。"
        "选用科学数据银行，是因为它是中国科学院国家通用仓储，同时给出 DOI 与 CSTR，本版本不受限。"
        "Scientific Data 非双盲，文稿已署名，审稿人可直接从 DOI 下载，不设 embargo，也不另做 anonymous.4open.science 镜像。"
        "数据 CC-BY-4.0，软件 MIT。实验室代码树见 https://github.com/fariell/verifiable-geocomputation。"
        "相关文章 SAM-GFNet（Remote Sens. 2025）不与本数据集共享数据。"
        "无外部资助、无项目编号，工作由作者单位时间支持。无利益冲突。窗口参数见正文数据可用性（审稿人看不到本函）。",
    )

    doc.save(OUT)
    return OUT


if __name__ == "__main__":
    path = build_full()
    print("wrote", path, os.path.getsize(path))
