"""Manim scene: D8 pit (no flow) vs planar west flow.

Render:

    P005_MANIM=1 python experiments/phase1/p005_d8.py

or:

    manim -ql experiments/phase1/p005_manim.py D8Stencil
"""
from manim import *

LABELS = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]


def grid3(origin, fills):
    cells = VGroup()
    texts = VGroup()
    side = 0.85
    for r in range(3):
        for c in range(3):
            sq = Square(side_length=side)
            sq.move_to(origin + RIGHT * c * side + DOWN * r * side)
            sq.set_fill(fills[r * 3 + c], opacity=0.45)
            sq.set_stroke(WHITE, 2)
            lab = Text(LABELS[r * 3 + c], font_size=18)
            lab.move_to(sq.get_center())
            cells.add(sq)
            texts.add(lab)
    return cells, texts, side


class D8Stencil(Scene):
    def construct(self):
        title = Text("P-005  D8   GPB-010 / GPB-011", font_size=30)
        title.to_edge(UP)
        self.play(FadeIn(title))

        pit_fills = [BLUE] * 4 + [RED] + [BLUE] * 4
        left, lt, side = grid3(LEFT * 5.2 + UP * 0.2, pit_fills)
        capL = Text("pit → NoFlow", font_size=22)
        capL.next_to(left, DOWN, buff=0.25)

        plane_fills = [GREY_BROWN] * 9
        right, rt, _ = grid3(RIGHT * 0.4 + UP * 0.2, plane_fills)
        capR = Text("plane A>0,B=0 → W", font_size=22)
        capR.next_to(right, DOWN, buff=0.25)

        self.play(LaggedStart(*[Create(s) for s in left], lag_ratio=0.04))
        self.play(FadeIn(lt), Write(capL))
        self.play(LaggedStart(*[Create(s) for s in right], lag_ratio=0.04))
        self.play(FadeIn(rt), Write(capR))

        e_cell = right[4]
        w_cell = right[3]
        arrow = Arrow(e_cell.get_center(), w_cell.get_center(), buff=0.12, color=YELLOW)
        self.play(GrowArrow(arrow))
        note = MathTex(r"\max\ \mathrm{drop}^2/\mathrm{dist}^2", font_size=28)
        note.to_edge(DOWN, buff=0.35)
        self.play(Write(note))
        self.wait(0.8)
