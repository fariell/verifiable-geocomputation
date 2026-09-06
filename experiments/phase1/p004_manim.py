"""Manim scene: Horn ∂x stencil and cubic remainder O(w²) → 0.

Render (local, ffmpeg required):

    P004_MANIM=1 python experiments/phase1/p004_consistency.py

or:

    manim -ql experiments/phase1/p004_manim.py HornStencil
"""
from manim import *

# Horn ∂x weights before / (8w). Rows = q down.
WEIGHTS = {
    (0, 0): -1,
    (1, 0): 0,
    (2, 0): 1,
    (0, 1): -2,
    (1, 1): 0,
    (2, 1): 2,
    (0, 2): -1,
    (1, 2): 0,
    (2, 2): 1,
}
LABELS = ["a", "b", "c", "d", "e", "f", "g", "h", "i"]


class HornStencil(Scene):
    def construct(self):
        title = Text("P-004  Horn  Dx   GPB-019", font_size=32)
        title.to_edge(UP)
        self.play(FadeIn(title))

        cells = VGroup()
        texts = VGroup()
        origin = LEFT * 3.4 + UP * 0.55
        side = 1.05
        for r in range(3):
            for c in range(3):
                sq = Square(side_length=side)
                sq.move_to(origin + RIGHT * c * side + DOWN * r * side)
                w = WEIGHTS[(c, r)]
                if w > 0:
                    sq.set_fill(BLUE, opacity=0.20 + 0.18 * abs(w))
                elif w < 0:
                    sq.set_fill(RED, opacity=0.20 + 0.18 * abs(w))
                else:
                    sq.set_fill(GREY, opacity=0.10)
                sq.set_stroke(WHITE, 2)
                lab = Text(LABELS[r * 3 + c], font_size=20)
                lab.move_to(sq.get_center() + UP * 0.22)
                wt = Text(f"{w:+d}", font_size=18, color=YELLOW)
                wt.move_to(sq.get_center() + DOWN * 0.22)
                cells.add(sq)
                texts.add(lab, wt)

        formula = MathTex(
            r"\partial_x=\frac{(c+2f+i)-(a+2d+g)}{8w}",
            font_size=32,
        )
        formula.next_to(title, DOWN, buff=0.25).to_edge(RIGHT, buff=0.35)

        self.play(LaggedStart(*[Create(s) for s in cells], lag_ratio=0.05))
        self.play(FadeIn(texts), Write(formula))
        self.wait(0.3)

        exact = MathTex(r"\deg\le 2:\ \partial_x \equiv A", font_size=28)
        exact.next_to(formula, DOWN, buff=0.35)
        rem = MathTex(r"z=G x^3:\ \partial_x=G w^{2}\to 0", font_size=28)
        rem.next_to(exact, DOWN, buff=0.25)
        self.play(Write(exact))
        self.play(Write(rem))
        self.play(Indicate(rem, color=BLUE))
        self.wait(0.8)
