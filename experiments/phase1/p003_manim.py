"""Manim scene: ZT Hxx stencil and 1/w² amplification of centre noise.

Render (local, ffmpeg required):

    P003_MANIM=1 python experiments/phase1/p003_curvature.py

or:

    manim -ql experiments/phase1/p003_manim.py ZTStencil
"""
from manim import *

WEIGHTS = {
    (0, 0): 0,
    (1, 0): 0,
    (2, 0): 0,
    (0, 1): 1,
    (1, 1): -2,
    (2, 1): 1,
    (0, 2): 0,
    (1, 2): 0,
    (2, 2): 0,
}
LABELS = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]


class ZTStencil(Scene):
    def construct(self):
        title = Text("P-003  Zevenbergen–Thorne  Hxx", font_size=32)
        title.to_edge(UP)
        self.play(FadeIn(title))

        cells = VGroup()
        texts = VGroup()
        origin = LEFT * 2.4 + UP * 0.4
        side = 1.15
        for r in range(3):
            for c in range(3):
                sq = Square(side_length=side)
                sq.move_to(origin + RIGHT * c * side + DOWN * r * side)
                w = WEIGHTS[(c, r)]
                if w == 1:
                    sq.set_fill(BLUE, opacity=0.45)
                elif w == -2:
                    sq.set_fill(RED, opacity=0.55)
                else:
                    sq.set_fill(GREY, opacity=0.12)
                sq.set_stroke(WHITE, 2)
                lab = Text(LABELS[r * 3 + c], font_size=22)
                lab.move_to(sq.get_center() + UP * 0.22)
                wt = Text(f"{w:+d}" if w != 0 else "0", font_size=20, color=YELLOW)
                wt.move_to(sq.get_center() + DOWN * 0.22)
                cells.add(sq)
                texts.add(lab, wt)

        formula = MathTex(
            r"H_{xx}=\frac{d-2e+f}{w^{2}}",
            font_size=40,
        )
        formula.to_edge(RIGHT).shift(UP * 1.2)

        self.play(LaggedStart(*[Create(s) for s in cells], lag_ratio=0.05))
        self.play(FadeIn(texts), Write(formula))
        self.wait(0.4)

        noise = MathTex(
            r"e\mapsto e+\delta \;\Rightarrow\; \Delta H_{xx}=-\frac{2\delta}{w^{2}}",
            font_size=34,
        )
        noise.next_to(formula, DOWN, buff=0.55)
        self.play(Write(noise))

        centre = cells[4]
        pulse = centre.copy().set_fill(RED, opacity=0.9)
        self.play(Transform(centre, pulse), run_time=0.6)
        self.play(Indicate(noise, color=RED))

        scale = MathTex(r"w=30\,\mathrm{m},\;\sigma\approx 3\,\mathrm{m}", font_size=28)
        scale.next_to(noise, DOWN, buff=0.4)
        amp = MathTex(r"|\Delta H_{xx}|\sim 10^{-2}\,\mathrm{m}^{-1}", font_size=28)
        amp.next_to(scale, DOWN, buff=0.25)
        self.play(FadeIn(scale), FadeIn(amp))
        self.wait(1.2)
        self.play(*[FadeOut(m) for m in self.mobjects])
